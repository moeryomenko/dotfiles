#!/usr/bin/env bash
# Helper for hypridle: save/dim/restore brightness on DDC/CI monitors.
# Usage:
#   hypridle-brightness.sh save     # save current brightness to temp files
#   hypridle-brightness.sh dim      # set both monitors to 10%
#   hypridle-brightness.sh restore  # restore saved brightness
#   hypridle-brightness.sh status   # print current brightness for both monitors

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypridle"
mkdir -p "$STATE_DIR"

# DP monitors that support DDC/CI
MONITORS=(
  "DP-1:11"
  "DP-2:12"
)

case "${1:-}" in
  save)
    for entry in "${MONITORS[@]}"; do
      name="${entry%%:*}"
      bus="${entry##*:}"
      ddcutil --brief getvcp 10 --bus "$bus" 2>/dev/null \
        | awk '{print $4}' \
        > "$STATE_DIR/brightness-$name.txt" \
        || true
    done
    ;;
  dim)
    for entry in "${MONITORS[@]}"; do
      name="${entry%%:*}"
      bus="${entry##*:}"
      ddcutil setvcp 10 10 --bus "$bus" 2>/dev/null || true
    done
    ;;
  restore)
    for entry in "${MONITORS[@]}"; do
      name="${entry%%:*}"
      bus="${entry##*:}"
      saved="$STATE_DIR/brightness-$name.txt"
      if [[ -f "$saved" ]]; then
        value=$(cat "$saved")
        ddcutil setvcp 10 "$value" --bus "$bus" 2>/dev/null || true
      fi
    done
    ;;
  status)
    for entry in "${MONITORS[@]}"; do
      name="${entry%%:*}"
      bus="${entry##*:}"
      current=$(ddcutil --brief getvcp 10 --bus "$bus" 2>/dev/null | awk '{print $4}')
      echo "$name (bus $bus): $current%"
    done
    ;;
  *)
    echo "Usage: $0 {save|dim|restore|status}"
    exit 1
    ;;
esac
