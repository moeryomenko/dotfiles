#!/usr/bin/env bash
#
# pass-import.sh — Import passwords into pass (password-store) from JSON.
#
# Usage:
#   ./pass-import.sh FILE [--force] [--dry-run] [--yes]
#
# Examples:
#   # Import all entries (skips existing)
#   ./pass-import.sh passwords.json
#
#   # Overwrite existing entries
#   ./pass-import.sh passwords.json --force
#
#   # Preview without importing
#   ./pass-import.sh passwords.json --dry-run
#
# Input JSON format:
#   [
#     {"path": "site/entry", "password": "s3cret"},
#     ...
#   ]
# (This is the format produced by pass-export.sh.)

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
Usage: ${SCRIPT_NAME} FILE [--force] [--dry-run] [--yes]

Import passwords into pass from a JSON file.

Arguments:
  FILE               JSON file to import (produced by pass-export.sh)

Options:
  --force            Overwrite existing entries (default: skip)
  --dry-run          Show what would be imported without modifying store
  --yes              Skip confirmation prompt
  -h, --help         Show this help message

Input format: JSON array of {"path": "...", "password": "..."}
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

# ---- Helpers ----------------------------------------------------------------
confirm() {
    local prompt="$1"
    local answer
    printf "%s [y/N] " "$prompt"
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# ---- Import -----------------------------------------------------------------
do_import() {
    local json_file="$1"
    local force="$2"
    local dry_run="$3"
    local skip_confirm="$4"

    if [ ! -f "$json_file" ]; then
        err "file not found: ${json_file}"
        exit 1
    fi

    # Validate JSON
    if ! jq empty "$json_file" 2>/dev/null; then
        err "invalid JSON in ${json_file}"
        exit 1
    fi

    local total
    total="$(jq 'length' "$json_file")"

    if [ "$total" -eq 0 ]; then
        warn "JSON file is empty — nothing to import"
        exit 0
    fi

    info "importing ${total} entr${total:+ies} from ${json_file}"

    # Determine which entries exist and which are new
    local new_entries=()
    local existing_entries=()
    local overwrite_entries=()

    while IFS=$'\t' read -r path is_existing; do
        if [ "$is_existing" = "true" ]; then
            existing_entries+=("$path")
            if [ "$force" = true ]; then
                overwrite_entries+=("$path")
            fi
        else
            new_entries+=("$path")
        fi
    done < <(jq -r '.[] | [.path, (if .path then false else false end)] | @tsv' "$json_file" | while IFS=$'\t' read -r path _; do
        if [ -f "${PASSWORD_STORE_DIR:-$HOME/.password-store}/${path}.gpg" ]; then
            printf "%s\ttrue\n" "$path"
        else
            printf "%s\tfalse\n" "$path"
        fi
    done)

    # Summary
    echo
    info "summary:"
    echo "  new:      ${#new_entries[@]}"
    echo "  existing: ${#existing_entries[@]}"
    if [ "$force" = true ]; then
        echo "  to overwrite: ${#overwrite_entries[@]}"
    else
        echo "  to skip:    ${#existing_entries[@]}"
    fi
    echo

    if [ "${#new_entries[@]}" -eq 0 ] && [ "${#overwrite_entries[@]}" -eq 0 ]; then
        warn "nothing to import (all entries already exist and --force not set)"
        exit 0
    fi

    # Confirm
    if [ "$skip_confirm" = false ] && [ "$dry_run" = false ]; then
        if ! confirm "Continue with import?"; then
            info "import cancelled"
            exit 0
        fi
    fi

    # Dry-run
    if [ "$dry_run" = true ]; then
        header "would import (${#new_entries[@]} new, ${#overwrite_entries[@]} overwritten):"
        if [ "${#new_entries[@]}" -gt 0 ]; then
            echo "  new entries:"
            for entry in "${new_entries[@]}"; do echo "    ${entry}"; done
        fi
        if [ "${#overwrite_entries[@]}" -gt 0 ]; then
            echo "  overwritten entries:"
            for entry in "${overwrite_entries[@]}"; do echo "    ${entry}"; done
        fi
        ok "dry-run complete — would import ${#new_entries[@]} new + ${#overwrite_entries[@]} overwritten"
        exit 0
    fi

    # Perform import
    local imported=0 skipped=0

    # Determine which entries to process
    local process_entries=()
    while IFS= read -r entry; do
        process_entries+=("$entry")
    done < <(jq -c '.[]' "$json_file")

    for entry_json in "${process_entries[@]}"; do
        local path password
        path="$(echo "$entry_json" | jq -r '.path')"
        password="$(echo "$entry_json" | jq -r '.password')"

        # Check if should skip
        if [ -f "${PASSWORD_STORE_DIR:-$HOME/.password-store}/${path}.gpg" ] && [ "$force" = false ]; then
            skipped=$((skipped + 1))
            continue
        fi

        # Insert the password
        # pass insert -m takes multiline input, but we only have one line
        echo "$password" | pass insert -m "$path" &>/dev/null
        imported=$((imported + 1))
    done

    echo
    ok "imported ${imported} entr${imported:+ies}"
    if [ "$skipped" -gt 0 ]; then
        warn "skipped ${skipped} existing entr${skipped:+ies} (use --force to overwrite)"
    fi
}

# ---- Main -------------------------------------------------------------------
main() {
    local json_file="" force=false dry_run=false skip_confirm=false

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage ;;
            --force)    force=true; shift ;;
            --dry-run)  dry_run=true; shift ;;
            --yes)      skip_confirm=true; shift ;;
            -*)
                err "unknown option: $1"
                usage
                ;;
            *)
                if [ -z "$json_file" ]; then
                    json_file="$1"; shift
                else
                    err "unexpected argument: $1"; exit 1
                fi
                ;;
        esac
    done

    if [ -z "$json_file" ]; then
        err "missing FILE argument"
        usage
    fi

    check_prereqs
    do_import "$json_file" "$force" "$dry_run" "$skip_confirm"
}

main "$@"
