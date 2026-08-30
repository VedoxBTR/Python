#!/bin/sh
# start-common.sh — componentes compartidos, compositor-agnóstico (mango/niri)
#
# Arranca el compositor y, SOLO cuando el socket Wayland ya existe, lanza
# waybar + mako + swayidle + swww + polkit. El script queda como líder de
# sesión (wait) hasta que el compositor termina.
#
# Uso: start-common.sh <mango|niri>

COMPOSITOR="${1:-niri}"
export XDG_CURRENT_DESKTOP=wlroots
export XDG_SESSION_TYPE=wayland
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
LOG="${XDG_RUNTIME_DIR}/dotfiles-start.log"
WALLPAPER="${WALLPAPER:-$HOME/.config/dotfiles/wallpaper.png}"
: > "$LOG"

log() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }

log "iniciando compositor: $COMPOSITOR"
"$COMPOSITOR" &
comp_pid=$!

# Esperar a que aparezca el socket Wayland (wayland-0, wayland-1, ...)
WAYLAND_DISPLAY=""
for i in $(seq 1 40); do
  sock=$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | head -1)
  if [ -n "$sock" ]; then
    WAYLAND_DISPLAY="$(basename "$sock")"
    export WAYLAND_DISPLAY
    break
  fi
  if ! kill -0 "$comp_pid" 2>/dev/null; then
    log "ERROR: el compositor '$COMPOSITOR' terminó antes de crear el socket."
    exit 1
  fi
  sleep 0.5
done

if [ -z "$WAYLAND_DISPLAY" ]; then
  log "ERROR: no apareció ningún socket Wayland en 20s."
  wait "$comp_pid"
  exit 1
fi
log "Wayland listo: $WAYLAND_DISPLAY"

# Agente polkit (privilegios gráficos). Usa el primero disponible.
if [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >>"$LOG" 2>&1 &
elif [ -x /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 ]; then
  /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 >>"$LOG" 2>&1 &
elif [ -x /usr/lib/polkit-kde-authentication-agent-1 ]; then
  /usr/lib/polkit-kde-authentication-agent-1 >>"$LOG" 2>&1 &
fi

# Barra
waybar >>"$LOG" 2>&1 &
log "waybar lanzado (pid $!)"

# Notificaciones
mako >>"$LOG" 2>&1 &
log "mako lanzado (pid $!)"

# Historial de portapapeles
wl-paste --watch cliphist store >>"$LOG" 2>&1 &
log "cliphist lanzado (pid $!)"

# Bloqueo por inactividad
swayidle -w timeout 300 'swaylock -f' >>"$LOG" 2>&1 &
log "swayidle lanzado (pid $!)"

# Wallpaper (requiere un archivo en WALLPAPER o $HOME/.config/dotfiles/wallpaper.png)
# Nota: el paquete Arch es awww (bin awww) que provee swww
_wallpaper_cmd="swww"
command -v awww >/dev/null 2>&1 && _wallpaper_cmd="awww"
if [ -f "$WALLPAPER" ]; then
  $_wallpaper_cmd init >>"$LOG" 2>&1 && $_wallpaper_cmd img "$WALLPAPER" >>"$LOG" 2>&1 &
  log "$_wallpaper_cmd lanzado con $WALLPAPER"
else
  log "WALLPAPER no encontrado ($WALLPAPER): se omite el fondo."
fi

log "todo listo, esperando al compositor (pid $comp_pid)"
wait "$comp_pid"
log "compositor terminó; sesión cerrada."
