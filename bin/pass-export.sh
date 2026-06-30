#!/usr/bin/env bash
#
# pass-export.sh — Export all pass (password-store) entries to JSON.
#
# Usage:
#   ./pass-export.sh [--output FILE] [--dry-run]
#
# Examples:
#   ./pass-export.sh
#   ./pass-export.sh --output ~/migration/passwords.json
#   ./pass-export.sh --dry-run
#
# Output format:
#   [
#     {"path": "site/entry", "password": "s3cret"},
#     ...
#   ]
#
# Export is plaintext — handle the output file with care.
# Transfer securely (encrypt before sending over network).

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# ---- Colours ----------------------------------------------------------------
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

info()  { printf "${CYAN}%s${RESET}\n" "$*"; }
ok()    { printf "${GREEN}  ✓ %s${RESET}\n" "$*"; }
warn()  { printf "${YELLOW}  ! %s${RESET}\n" "$*"; }
err()   { printf "${RED}  ✗ %s${RESET}\n" "$*" >&2; }
header(){ printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ---- Usage ------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [--output FILE] [--dry-run]

Export all pass password-store entries to a JSON file.

Options:
  --output FILE      Output file path (default: passwords.json)
  --dry-run          Show what would be exported without writing
  -h, --help         Show this help message

Output is plaintext JSON — handle the file securely.
EOF
    exit 0
}

# ---- Prerequisite checks ----------------------------------------------------
check_prereqs() {
    local missing=false
    for cmd in pass jq; do
        if ! command -v "$cmd" &>/dev/null; then
            err "required command not found: $cmd"
            missing=true
        fi
    done
    if [ "$missing" = true ]; then exit 1; fi
}

# ---- Export -----------------------------------------------------------------
do_export() {
    local output_file="$1"
    local dry_run="$2"

    local store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

    if [ ! -d "$store_dir" ]; then
        err "password store not found: ${store_dir}"
        exit 1
    fi

    # Gather all entries from .gpg files
    local entries=()
    while IFS= read -r -d '' file; do
        local entry
        entry="${file#"$store_dir"/}"
        entry="${entry%.gpg}"
        entries+=("$entry")
    done < <(find "$store_dir" -name '*.gpg' -print0 | sort -z)

    local total="${#entries[@]}"

    if [ "$total" -eq 0 ]; then
        warn "no password entries found in ${store_dir}"
        exit 0
    fi

    info "found ${total} password entr${total:+ies}"

    if [ "$dry_run" = true ]; then
        echo
        info "entries to export:"
        for entry in "${entries[@]}"; do
            echo "  ${entry}"
        done
        ok "dry-run complete — ${total} entries would be exported"
        exit 0
    fi

    # Write JSON
    {
        echo "["
        local i=0
        for entry in "${entries[@]}"; do
            local password
            password="$(pass show "$entry")"

            # JSON-escape both fields
            local entry_json pass_json
            entry_json="$(printf '%s' "$entry" | jq -R .)"
            pass_json="$(printf '%s' "$password" | jq -R .)"

            if [ "$i" -gt 0 ]; then
                echo ","
            fi
            printf '  {"path": %s, "password": %s}' "$entry_json" "$pass_json"
            i=$((i + 1))
        done
        echo
        echo "]"
    } > "$output_file"

    chmod 600 "$output_file"

    local size
    size="$(du -h "$output_file" | cut -f1)"
    ok "exported ${total} entr${total:+ies} to ${output_file} (${size})"
}

# ---- Main -------------------------------------------------------------------
main() {
    local output_file="passwords.json"
    local dry_run=false

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage ;;
            --output)
                if [ $# -lt 2 ]; then err "--output requires an argument"; exit 1; fi
                output_file="$2"; shift 2 ;;
            --output=*) output_file="${1#*=}"; shift ;;
            --dry-run)  dry_run=true; shift ;;
            *) err "unknown option: $1"; usage ;;
        esac
    done

    check_prereqs
    do_export "$output_file" "$dry_run"
}

main "$@"
