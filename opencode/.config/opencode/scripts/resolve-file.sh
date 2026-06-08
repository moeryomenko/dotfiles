#!/bin/bash
# resolve a file through the three-layer override chain
# usage: resolve-file.sh <relative-path> [data-dir]
# e.g.: resolve-file.sh planning-rules.md /path/to/opencode/data
#
# checks in order (first-found-wins, never merge):
#   1. <cwd>/.opencode/<path>               (project override)
#   2. <data-dir>/<path>                     (user override)
#   3. <skill-root>/references/<path>        (bundled default)
#
# outputs the file content to stdout
# exits 1 if not found at any level

set -euo pipefail

path="$1"
if [ -z "$path" ]; then
    echo "error: usage: resolve-file.sh <relative-path> [data-dir]" >&2
    exit 1
fi

# use argument if provided, fall back to env var
data_dir="${2:-${OPENCODE_DATA:-}}"

# derive skill root from script location
# script is at <root>/scripts/resolve-file.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f ".opencode/$path" ] && [ -s ".opencode/$path" ]; then
    cat ".opencode/$path"
elif [ -n "$data_dir" ] && [ -f "$data_dir/$path" ] && [ -s "$data_dir/$path" ]; then
    cat "$data_dir/$path"
elif [ -f "$ROOT_DIR/references/$path" ]; then
    cat "$ROOT_DIR/references/$path"
else
    echo "error: file not found in override chain: $path" >&2
    exit 1
fi
