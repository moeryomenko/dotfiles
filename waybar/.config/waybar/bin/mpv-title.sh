#!/usr/bin/env bash

set -Eeuo pipefail

# Hide this fallback when mpv exposes MPRIS (mpv-mpris); the regular mpris
# module handles the title in that case.
if command -v playerctl >/dev/null 2>&1 &&
	playerctl -l 2>/dev/null | grep -q '^mpv'; then
	exit 0
fi

title=$(
	hyprctl clients -j 2>/dev/null |
		jq -r '[.[] | select((.class // "") == "mpv")] | sort_by(.focusHistoryID) | .[0].title // empty'
)

title=${title% - mpv}

if [[ -n $title && $title != mpv ]]; then
	printf '%s\n' "$title"
fi
