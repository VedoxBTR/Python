#!/bin/sh
# power-menu.sh — menú de sesión mínimo (sin Noctalia)
# lock / logout / reboot / shutdown  ·  usa fuzzel, cero deps extra
choice=$(printf "lock\nlogout\nreboot\nshutdown" | fuzzel --prompt="sesión> ")
case "$choice" in
  lock)    swaylock -f ;;
  logout)  loginctl terminate-user "$USER" ;;
  reboot)  systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
