#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

if ! command -v bluetoothctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
	exit 0
fi

connected_devices=$(bluetoothctl devices Connected 2>/dev/null) || exit 0
[[ -n $connected_devices ]] || exit 0

declare -a labels=()

while IFS= read -r device_line; do
	if [[ ! $device_line =~ ^Device[[:space:]]+([[:xdigit:]:]+)[[:space:]]+(.+)$ ]]; then
		continue
	fi

	address=${BASH_REMATCH[1]}
	fallback_alias=${BASH_REMATCH[2]}
	info=$(bluetoothctl info "$address" 2>/dev/null || true)

	alias=$(
		awk '
			/^[[:space:]]*Alias:[[:space:]]*/ {
				sub(/^[[:space:]]*Alias:[[:space:]]*/, "")
				print
				exit
			}
		' <<<"$info"
	)
	alias=${alias:-$fallback_alias}

	battery=$(
		awk '
			/^[[:space:]]*Battery Percentage:/ {
				value = $NF
				gsub(/[()]/, "", value)
				if (value ~ /^[0-9]+$/ && value + 0 <= 100) {
					print value
				}
				exit
			}
		' <<<"$info"
	)

	label=$alias
	if [[ -n $battery ]]; then
		label+="   ${battery}%"
	fi
	labels+=("$label")
done <<<"$connected_devices"

((${#labels[@]} > 0)) || exit 0

text=${labels[0]}
tooltip=${labels[0]}
for label in "${labels[@]:1}"; do
	text+="  ·  $label"
	tooltip+=$'\r'"$label"
done

jq -cn --arg text "$text" --arg tooltip "$tooltip" \
	'{text: $text, tooltip: $tooltip}'
