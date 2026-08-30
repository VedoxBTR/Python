#!/bin/sh
# wifi-menu.sh — optimizado anti-freeze (Vanta Black + rofi)
# FIX: antes usaba --rescan yes 2 veces bloqueando 5-10s. Ahora usa --rescan no instantáneo.
# Solo hace rescan real al pulsar [Rescan] o si la cache está vacía. Rescan va en background.

export PATH="$HOME/.local/bin:$PATH"

signal_icon() {
  sig="$1"
  if [ "$sig" -ge 80 ]; then echo "󰤨"
  elif [ "$sig" -ge 60 ]; then echo "󰤥"
  elif [ "$sig" -ge 40 ]; then echo "󰤢"
  elif [ "$sig" -ge 20 ]; then echo "󰤟"
  else echo "󰤯"
  fi
}
sec_icon() {
  case "$1" in
    *WPA3*) echo "󰌾" ;;
    *WPA2*) echo "󰌾" ;;
    *WPA*) echo "󰌾" ;;
    *WEP*) echo "󰌿" ;;
    *) echo "󰌶" ;;
  esac
}

# Header rápido con timeout (evita freeze si NM está ocupado)
CONN=$(timeout 2 nmcli -t -f NAME connection show --active 2>/dev/null | head -1)
IP=$(timeout 2 nmcli -t -f IP4.ADDRESS device show 2>/dev/null | head -1 | cut -d: -f2)
if [ -n "$CONN" ]; then
  HEADER="󰤨  $CONN ($IP)  —  desconectar"
else
  HEADER="󰤭  Desconectado"
fi

# Lanzar rescan en background para la próxima apertura (no bloquea)
# Solo si hace >15s desde último rescan, pero lo hacemos siempre en background, es inocuo y no bloquea
(nohup timeout 4 nmcli device wifi rescan >/dev/null 2>&1 &)

# Lista cacheada INSTANTÁNEA (no rescan). Antes era --rescan yes que bloqueaba.
LIST=$(timeout 4 nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ device wifi list --rescan no 2>/dev/null | grep -v "^--" | grep -v "^:" | head -n 30)

# Si cache vacía (recién boot), intentar 1 rescan rápido con timeout corto, si no esperar
if [ -z "$LIST" ]; then
  notify-send "Wi-Fi" "Cache vacía, escaneando..." 2>/dev/null
  LIST=$(timeout 6 nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ device wifi list --rescan yes 2>/dev/null | grep -v "^--" | head -n 30)
fi

TMP=$(mktemp)
MAP=$(mktemp)
trap 'rm -f "$TMP" "$MAP"' EXIT INT TERM

{
  echo "$HEADER"
  echo "── Redes disponibles ─────────────"
  echo "  [Rescan redes]"
  echo "󰖪  [Desactivar Wi-Fi]"
  echo "󰤨  [Abrir nmtui (avanzado)]"
  echo "──────────────────────────────"
} > "$TMP"

COUNT=0
# Usar cache de SSIDs vistos para deduplicar sin grep lineal cada vez (más rápido)
SEEN=""

printf "%s\n" "$LIST" | while IFS=: read -r INUSE SSID SIGNAL SEC FREQ; do
  # SSID puede tener \: escapado, nmcli lo escapa. Decodificar simple:
  SSID=$(printf "%s" "$SSID" | sed 's/\\:/:/g')
  [ -z "$SSID" ] && continue
  # Deduplicar: si ya vimos SSID, saltar
  case " $SEEN " in
    *" $SSID "*) continue ;;
  esac
  SEEN="$SEEN $SSID "
  COUNT=$((COUNT+1))
  [ "$COUNT" -gt 20 ] && break
  ICON=$(signal_icon "${SIGNAL:-0}")
  SECI=$(sec_icon "$SEC")
  BAND="2.4G"
  echo "$FREQ" | grep -q "5" && BAND="5G"
  STAR=""
  [ "$INUSE" = "*" ] && STAR="●"
  DISP=$(printf "%s  %-28s  %3s%%  %s  %s  %s" "$ICON" "$SSID" "${SIGNAL:-?}" "$BAND" "$SECI" "$STAR")
  echo "$DISP" >> "$TMP"
  printf "%s|%s\n" "$DISP" "$SSID" >> "$MAP"
done

# Llamada rofi directa (reemplazo fuzzel)
CHOICE=$(rofi -dmenu -i -p "󰖩 wifi" -theme ~/.config/rofi/dmenu.rasi -l 14 < "$TMP" 2>/dev/null)
[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
  *"Rescan"*)
    # Rescan real ahora sí, en foreground pero notificando
    notify-send "Wi-Fi" "Escaneando redes..." 2>/dev/null
    timeout 6 nmcli device wifi rescan 2>/dev/null
    sleep 1
    exec "$0"
    ;;
  *"Desactivar Wi-Fi"*)
    nmcli radio wifi off 2>/dev/null && notify-send "Wi-Fi" "Wi-Fi desactivado" || notify-send "Wi-Fi" "Error"
    exit 0
    ;;
  *"nmtui"*)
    foot -e nmtui 2>/dev/null &
    exit 0
    ;;
  *"──"*|"──────────────────────────────")
    exit 0
    ;;
esac

# Si eligió header conectado, desconectar
if [ "$CHOICE" = "$HEADER" ]; then
  if [ -n "$CONN" ]; then
    nmcli connection down "$CONN" 2>/dev/null && notify-send "Wi-Fi" "Desconectado de $CONN" || notify-send "Wi-Fi" "Error al desconectar"
  fi
  exit 0
fi

# Buscar SSID real via MAP (robusto con espacios)
REAL_SSID=$(grep -F "${CHOICE}|" "$MAP" 2>/dev/null | cut -d'|' -f2 | head -1)
# Fallback: si no está en map (ej header), intentar extraer segundo campo
if [ -z "$REAL_SSID" ]; then
  REAL_SSID=$(echo "$CHOICE" | awk '{print $2}')
  # Si tiene estrella ● al final, quitarla, y buscar exacto en LIST
  REAL_SSID=$(printf "%s" "$LIST" | cut -d: -f2 | grep -Fx "$REAL_SSID" | head -1)
  [ -z "$REAL_SSID" ] && REAL_SSID=$(echo "$CHOICE" | awk '{print $2}')
fi
[ -z "$REAL_SSID" ] && exit 1
# Decodificar
REAL_SSID=$(printf "%s" "$REAL_SSID" | sed 's/\\:/:/g' | xargs)

# Ver si ya guardada
if nmcli connection show 2>/dev/null | grep -q "^${REAL_SSID} "; then
  notify-send "Wi-Fi" "Conectando a $REAL_SSID..." 2>/dev/null
  if timeout 10 nmcli connection up "$REAL_SSID" 2>/dev/null; then
    notify-send "Wi-Fi" "Conectado a $REAL_SSID" 2>/dev/null
  else
    notify-send "Wi-Fi" "Fallo al conectar" 2>/dev/null
  fi
else
  SEC=$(printf "%s\n" "$LIST" | grep -F ":${REAL_SSID}:" | cut -d: -f4 | head -1)
  if echo "$SEC" | grep -q "WPA\|WEP"; then
    PASS=$(printf "" | rofi -dmenu -password -p "󰌾 password" -theme ~/.config/rofi/dmenu.rasi -l 1 2>/dev/null)
    [ -z "$PASS" ] && exit 0
    notify-send "Wi-Fi" "Conectando a $REAL_SSID..." 2>/dev/null
    if timeout 15 nmcli device wifi connect "$REAL_SSID" password "$PASS" 2>/dev/null; then
      notify-send "Wi-Fi" "Conectado a $REAL_SSID" 2>/dev/null
    else
      notify-send "Wi-Fi" "Contraseña incorrecta o error" -u critical 2>/dev/null
    fi
  else
    timeout 15 nmcli device wifi connect "$REAL_SSID" 2>/dev/null && notify-send "Wi-Fi" "Conectado a $REAL_SSID" || notify-send "Wi-Fi" "Error al conectar"
  fi
fi
