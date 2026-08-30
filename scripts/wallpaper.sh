#!/bin/sh
# wallpaper.sh — selector de fondo mínimo (sin Noctalia)
# lista ~/Pictures/Wallpapers y aplica con awww (provee swww)
DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
[ -d "$DIR" ] || exit 1
choice=$(find "$DIR" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -printf '%f\n' | sort | fuzzel --prompt="wallpaper> ")
[ -n "$choice" ] || exit 0
# awww provee swww, pero el binario es awww
if command -v awww >/dev/null 2>&1; then
  awww init >/dev/null 2>&1
  awww img "$DIR/$choice"
else
  swww init >/dev/null 2>&1
  swww img "$DIR/$choice"
fi
