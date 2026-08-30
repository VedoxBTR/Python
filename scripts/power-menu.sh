#!/bin/sh
# power-menu.sh — menú de sesión mínimo (sin Noctalia)
# lock / logout / reboot / shutdown  ·  usa rofi (reemplazo fuzzel)
choice=$(printf "lock\nlogout\nreboot\nshutdown" | rofi -dmenu -i -p "sesión" -theme ~/.config/rofi/dmenu.rasi)
case "$choice" in
  lock)    swaylock -f ;;
  logout)  loginctl terminate-user "$USER" ;;
  reboot)  systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
