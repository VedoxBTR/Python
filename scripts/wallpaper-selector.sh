#!/bin/sh
# wallpaper-selector.sh — selector Vanta Black + Pywal con PREVIEW
# Modos: rofi (grid con thumbnails), wofi (con preview img), waypaper (GUI)
# Uso: wallpaper-selector.sh [--rofi|--wofi|--waypaper] — default rofi

MODE="${1:---rofi}"
WALL_DIR="$HOME/Wallpaper"
ALT_DIR="$HOME/Pictures/Wallpapers"
APPLY="$HOME/dotfiles/scripts/apply-colors.sh"

# Buscar wallpapers
FILES=$(find "$WALL_DIR" "$ALT_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort -u)
[ -z "$FILES" ] && notify-send "Wallpaper" "No se encontraron imágenes en $WALL_DIR" -u critical && exit 1

# Helper: notificación preview disponible
notify_preview_hint() {
  echo "[wallpaper] usando $1 con preview"
}

case "$MODE" in
  --waypaper|--gui)
    notify_preview_hint "waypaper GUI"
    waypaper --folder "$WALL_DIR" --backend awww 2>/dev/null &
    exit 0
    ;;
  --wofi)
    if ! command -v wofi >/dev/null 2>&1; then
      notify-send "Wofi no instalado" "Instalando? sudo pacman -S wofi — usando rofi como fallback" -u critical
      if command -v rofi >/dev/null 2>&1; then
        MODE="--rofi"
      else
        MODE="--rofi"
      fi
    else
      # Wofi con preview: formato img:/path:text:basename
      # Wofi --allow-images muestra thumbnail + texto
      WOFI_INPUT=$(printf "%s\n" "$FILES" | while IFS= read -r f; do
        b=$(basename "$f")
        # Sanitizar : y \n en nombre para wofi
        printf "img:%s:text:%s\n" "$f" "$b"
      done)
      CHOICE=$(printf "%s\n" "$WOFI_INPUT" | wofi --dmenu --allow-images --prompt="  wallpaper>" --width 780 --height 520 --cache-file /dev/null 2>/dev/null)
      # Wofi devuelve el texto (basename) o línea completa si no parseó. Extraer basename
      CHOICE=$(printf "%s" "$CHOICE" | sed 's/^.*text://' | sed 's/^img:.*text://' | xargs 2>/dev/null)
      # Si viene con img: prefix entero, extraer filename
      if echo "$CHOICE" | grep -q "^img:"; then
        CHOICE=$(basename "$(echo "$CHOICE" | cut -d: -f2)")
      fi
      # Si CHOICE vacía, salir
      [ -z "$CHOICE" ] && exit 0
      # Si CHOICE contiene ruta completa, sacar basename
      case "$CHOICE" in
        */*) CHOICE=$(basename "$CHOICE") ;;
      esac
      # Continuar al flujo común (buscar FILE por basename)
    fi
    # Si fallback cambió MODE, re-evaluar
    if [ "$MODE" != "--wofi" ]; then
      # Recursivo: re-ejecutar con nuevo modo
      exec "$0" "$MODE"
    fi
    ;;
  --rofi)
    # Rofi grid 3x3 con thumbnails (requiere rofi >=1.7 y theme wallpaper-selector)
    if ! command -v rofi >/dev/null 2>&1; then
      notify-send "Rofi no instalado" "Usando rofi fallback" -u low
      MODE="--rofi"
      exec "$0" "$MODE"
    else
      # Construir lista con icon injection: "label\0icon\x1f/path"
      # Usar archivo temporal para manejar null bytes
      TMP_ROFI=$(mktemp)
      printf "%s\n" "$FILES" | while IFS= read -r f; do
        b=$(basename "$f")
        # rofi espera label + null + icon
        printf '%s\0icon\x1f%s\n' "$b" "$f" >> "$TMP_ROFI"
      done
      # Lanzar rofi con grid theme
      if [ -f "$HOME/.config/rofi/wallpaper-selector.rasi" ]; then
        THEME="$HOME/.config/rofi/wallpaper-selector.rasi"
      else
        THEME="$HOME/.config/rofi/theme.rasi"
      fi
      # cat con null bytes debe ser con --null? Pero cat normal preserva null
      CHOICE=$(cat "$TMP_ROFI" | rofi -dmenu -p " wallpaper" -theme "$THEME" -show-icons -i -l 9 2>/dev/null)
      rm -f "$TMP_ROFI"
      [ -z "$CHOICE" ] && exit 0
      # Rofi devuelve solo label (basename)
      CHOICE=$(printf "%s" "$CHOICE" | xargs)
    fi
    ;;
  *)
    # Rofi dmenu por defecto (rápido, con pywal) - fuzzel deprecado
    CHOICE=$(printf "%s\n" "$FILES" | xargs -I{} basename {} | rofi -dmenu -i -p " wallpaper" -theme ~/.config/rofi/dmenu.rasi -l 15 2>/dev/null)
    ;;
esac

[ -z "$CHOICE" ] && exit 0

# Atajos directos: si escribe "waypaper", "wofi", "rofi" abre ese modo
case "$CHOICE" in
  wofi|WOFI)
    exec "$0" --wofi
    ;;
  rofi|ROFI)
    exec "$0" --rofi
    ;;
  waypaper|gui|GUI)
    waypaper --folder "$WALL_DIR" --backend awww 2>/dev/null &
    exit 0
    ;;
esac

FILE=$(printf "%s\n" "$FILES" | grep -F "/$CHOICE" | head -1)
[ -z "$FILE" ] && FILE=$(find "$WALL_DIR" "$ALT_DIR" -name "$CHOICE" 2>/dev/null | head -1)
[ -z "$FILE" ] && FILE=$(printf "%s\n" "$FILES" | grep -F "$CHOICE" | head -1)
[ -z "$FILE" ] && notify-send "Wallpaper" "Archivo no encontrado: $CHOICE" -u critical && exit 1

# Preguntar modo: Auto pywal vs Vanta Black puro vs solo wallpaper
MODE_CHOICE=$(printf "auto (pywal + awww)\nvantablack (puro negro)\nsolo wallpaper (sin recolorear)\nwofi preview\nrofi grid" | rofi -dmenu -i -p "modo" -theme ~/.config/rofi/dmenu.rasi -l 6 2>/dev/null)

# Si eligió ir a preview, re-lanzar selector en ese modo
case "$MODE_CHOICE" in
  *wofi*) exec "$0" --wofi ;;
  *rofi*) exec "$0" --rofi ;;
esac

case "$MODE_CHOICE" in
  *vantablack*)
    notify-send "Wallpaper" "Aplicando $CHOICE en Vanta Black" -i "$FILE" 2>/dev/null
    mkdir -p ~/.config/dotfiles
    cp "$FILE" ~/.config/dotfiles/wallpaper.png
    ln -sf "$FILE" ~/.config/dotfiles/wallpaper.current
    pgrep -x awww-daemon >/dev/null 2>&1 || (awww-daemon 2>/dev/null & sleep 0.8)
    awww img "$FILE" 2>/dev/null
    "$APPLY" --vantablack
    # Waybar vantablack puro — subida 2px
    cat > ~/.config/waybar/style.css <<'CSS'
/* Vanta Black - Waybar transparente - subida 2px */
* { border:none; border-radius:0; font-family:"JetBrainsMono Nerd Font",monospace; font-size:12px; min-height:0; }
window#waybar { background: transparent; color:#e5e5e5; margin:2px 12px 0 12px; }
#workspaces, #clock, #network, #pulseaudio, #battery, #tray, #custom-power, #idle_inhibitor {
  background: rgba(0,0,0,0.55);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 10px;
  padding: 4px 12px;
  margin: 2px 3px;
  color:#e5e5e5;
}
#workspaces { padding:0 4px; background:rgba(0,0,0,0.65); }
#workspaces button { color:#666666; background:transparent; border-radius:8px; padding:2px 10px; margin:3px 2px; }
#workspaces button.active { background:#ffffff; color:#000000; }
#workspaces button.occupied { color:#e5e5e5; }
#workspaces button:hover { background:#1a1a1a; color:#ffffff; }
#clock { background:rgba(0,0,0,0.65); color:#ffffff; font-weight:700; }
#network.disconnected, #battery.critical { color:#ff3b30; }
#battery.charging { color:#30d158; }
tooltip { background:#000000; border:1px solid #222222; border-radius:8px; color:#e5e5e5; }
CSS
    pkill -SIGUSR2 waybar 2>/dev/null || (pkill waybar; waybar >/dev/null 2>&1 &)
    ;;
  *solo*)
    mkdir -p ~/.config/dotfiles
    cp "$FILE" ~/.config/dotfiles/wallpaper.png
    ln -sf "$FILE" ~/.config/dotfiles/wallpaper.current 2>/dev/null
    pgrep -x awww-daemon >/dev/null 2>&1 || (awww-daemon 2>/dev/null & sleep 0.8)
    awww img "$FILE" 2>/dev/null
    notify-send "Wallpaper" "$CHOICE" -i "$FILE" 2>/dev/null
    ;;
  *)
    "$APPLY" "$FILE"
    ;;
esac

# Opcional: matugen para GTK si está instalado
if command -v matugen >/dev/null 2>&1; then
  matugen image "$FILE" --mode dark -t scheme-monochrome 2>/dev/null &
fi
