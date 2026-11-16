#!/usr/bin/env bash

set -Eeuo pipefail

if command -v swaync-client >/dev/null 2>&1; then
	exec swaync-client -t
fi

exec hyprlauncher -t
