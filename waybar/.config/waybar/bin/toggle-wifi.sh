#!/usr/bin/env bash

set -Eeuo pipefail

if ! command -v nmcli >/dev/null 2>&1; then
	printf 'nmcli not found\n' >&2
	exit 1
fi

if [[ "$(nmcli radio wifi)" == enabled ]]; then
	nmcli radio wifi off
else
	nmcli radio wifi on
fi
