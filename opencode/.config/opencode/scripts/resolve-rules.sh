#!/bin/bash
# resolve custom rules file through the two-layer override chain
# usage: resolve-rules.sh <filename> [data-dir]
# e.g.: resolve-rules.sh planning-rules.md /path/to/opencode/data
#
# checks in order (first-found-wins, not merged):
#   1. .opencode/<filename>                 (project override)
#   2. <data-dir>/<filename>                (user override)
#
# outputs file content to stdout if found, empty output if not
# always exits 0

set -euo pipefail

filename="$1"
if [ -z "$filename" ]; then
    exit 0
fi

# use argument if provided, fall back to env var
data_dir="${2:-${OPENCODE_DATA:-}}"

if [ -f ".opencode/$filename" ] && [ -s ".opencode/$filename" ]; then
    cat ".opencode/$filename"
elif [ -n "$data_dir" ] && [ -f "$data_dir/$filename" ] && [ -s "$data_dir/$filename" ]; then
    cat "$data_dir/$filename"
fi

exit 0
