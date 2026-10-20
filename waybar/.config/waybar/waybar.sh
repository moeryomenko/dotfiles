#!/usr/bin/env bash

set -Eeuo pipefail

pkill --exact waybar 2>/dev/null || true

while pgrep --exact waybar >/dev/null; do
  sleep 0.1
done

exec waybar
