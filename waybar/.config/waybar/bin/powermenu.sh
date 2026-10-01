#!/usr/bin/env bash

set -Eeuo pipefail

for command in wofi hyprctl systemctl; do
  command -v "$command" >/dev/null || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  }
done

choice=$(printf '%s\n' 'Logout' 'Suspend' 'Hibernate' 'Reboot' 'Power off' | wofi --dmenu --prompt 'Power') || exit 0

case "$choice" in
  Logout)
    hyprctl dispatch exit
    ;;
  Suspend)
    systemctl suspend
    ;;
  Hibernate)
    systemctl hibernate
    ;;
  Reboot)
    systemctl reboot
    ;;
  'Power off')
    systemctl poweroff
    ;;
esac
