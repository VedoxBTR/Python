# Binds de mango para el setup sin Noctalia

Sintaxis mango: `bind=MOD,KEY,spawn,comando`

## Quitar (líneas actuales que dependen de noctalia)
En `~/.config/mango/config.conf`:
- `exec-once=noctalia`  ← ELIMINAR (noctalia ya no arranca; los apps comunes
  los lanza `start-common.sh`).
- `bind=SUPER,space,spawn,noctalia msg panel-toggle launcher`
- `bind=SUPER,s,spawn,noctalia msg panel-toggle control-center`
- `bind=SUPER+SHIFT,w,spawn,noctalia msg panel-toggle wallpaper`
- `bind=SUPER+CTRL,comma,spawn,noctalia msg settings-toggle`
- `bind=CTRL+ALT,Delete,spawn,noctalia msg panel-toggle session`
- `bind=SUPER+ALT,l,spawn,noctalia-shell ipc call session lock` (si existe)

## Añadir (reemplazos mínimos)
```
# Lanzador
bind=SUPER,space,spawn,fuzzel

# Lock
bind=SUPER,l,spawn,swaylock -f

# Menú de sesión (lock/logout/reboot/shutdown)
bind=CTRL+ALT,Delete,spawn,~/dotfiles/scripts/power-menu.sh

# Selector de wallpaper
bind=SUPER+SHIFT,w,spawn,~/dotfiles/scripts/wallpaper.sh

# Screenshot (requiere grim + slurp)
bind=SUPER,Print,spawn,grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%s).png

# Historial de portapapeles
bind=SUPER,slash,spawn,cliphist list | fuzzel | wl-copy
```

Mantener los binds de audio/brillo (wpctl, brightnessctl) y los de ventana.
