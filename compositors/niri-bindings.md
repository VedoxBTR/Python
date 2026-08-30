# Binds de niri para el setup sin Noctalia

Sintaxis niri (config.kdl): dentro de `binds { ... }`
```
"Mod+Space" { spawn "fuzzel"; }
"Mod+L" { spawn "swaylock -f"; }
"Ctrl+Alt+Delete" { spawn "$HOME/dotfiles/scripts/power-menu.sh"; }
"Mod+Shift+W" { spawn "$HOME/dotfiles/scripts/wallpaper.sh"; }
"Mod+Print" { spawn "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%s).png"; }
"Mod+Slash" { spawn "cliphist list | fuzzel | wl-copy"; }
```

## Nota
Revisar `~/.config/niri/config.kdl` por si hay referencias a `noctalia`
(ej. `spawn "noctalia msg ..."`) y reemplazarlas como arriba.
Los apps comunes (waybar/mako/swayidle/swww/polkit) los lanza
`start-common.sh`, no hace falta `spawn` extra en niri.
