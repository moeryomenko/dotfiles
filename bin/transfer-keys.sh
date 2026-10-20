#!/usr/bin/env bash
#
# transfer-keys.sh — Export or import SSH and GPG keys for machine migration.
#
# Usage:
#   ./transfer-keys.sh export [--output-dir DIR] [--dry-run]
#   ./transfer-keys.sh import ARCHIVE [--dry-run]
#
# Examples:
#   # On source machine
#   ./transfer-keys.sh export
#
#   # Copy archive to target, then on target
#   ./transfer-keys.sh import keys-export-*.tar.gz
#
# The archive is a tar.gz containing:
#   ssh/          — ~/.ssh/ (private keys, config, etc.)
#   gpg-secret.asc  — gpg --export-secret-keys --armor
#   gpg-public.asc  — gpg --export --armor
#   gpg-trust.txt   — gpg --export-ownertrust
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SELF="$(readlink -f "$0")"

# ---- Colours (disable if not a terminal) ------------------------------------
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

# ---- Usage ----------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <export|import> [options]

Commands:
  export                  Export SSH + GPG keys into a portable archive
    --output-dir DIR      Output directory (default: current directory)
    --dry-run             Show what would be done without doing it

  import ARCHIVE          Import SSH + GPG keys from an archive
    --dry-run             Show what would be done without doing it
    --yes                 Skip confirmation prompts

EOF
    exit 0
}

# ---- Prerequisite checks -------------------------------------------------
check_prereqs() {
    local missing=false
    for cmd in gpg tar; do
        if ! command -v "$cmd" &>/dev/null; then
            err "required command not found: $cmd"
            missing=true
        fi
    done
    if [ "$missing" = true ]; then exit 1; fi
}

# ---- Helpers --------------------------------------------------------------
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

dry_run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        warn "[dry-run] would run: $*"
    else
        eval "$@"
    fi
}

# ---- Export ---------------------------------------------------------------
do_export() {
    local output_dir="$1"
    local hostname
    hostname="$(hostname -s 2>/dev/null || echo "unknown")"
    local date_str
    date_str="$(date +%Y%m%d-%H%M%S)"
    local archive_name="keys-export-${hostname}-${date_str}.tar.gz"
    local archive_path="${output_dir}/${archive_name}"
    local work_dir
    work_dir="$(mktemp -d)"

    info "output archive: ${archive_path}"
    echo

    # --- SSH ---
    header "1. SSH keys"
    if [ -d "$HOME/.ssh" ]; then
        local ssh_file_count
        ssh_file_count="$(find "$HOME/.ssh" -maxdepth 1 -type f 2>/dev/null | wc -l)"
        info "  found ${ssh_file_count} file(s) in ~/.ssh"

        # Copy, excluding sockets and agent sockets
        dry_run_cmd "
            mkdir -p \"${work_dir}/ssh\" &&
            find \"$HOME/.ssh\" -maxdepth 1 -type f \
                ! -name '*.sock' \
                -exec cp -a {} \"${work_dir}/ssh/\" \;
        "
        ok "SSH keys staged"
    else
        warn "~/.ssh does not exist — skipping SSH keys"
    fi

    # --- GPG ---
    header "2. GPG keys"
    local gpg_key_count
    gpg_key_count="$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c '^sec' || true)"
    if [ "$gpg_key_count" -gt 0 ]; then
        info "  found ${gpg_key_count} secret key(s)"

        dry_run_cmd "gpg --export-secret-keys --armor > \"${work_dir}/gpg-secret.asc\""
        ok "secret keys exported"

        dry_run_cmd "gpg --export --armor > \"${work_dir}/gpg-public.asc\""
        ok "public keys exported"

        dry_run_cmd "gpg --export-ownertrust > \"${work_dir}/gpg-trust.txt\""
        ok "ownertrust exported"
    else
        warn "no GPG secret keys found — skipping GPG export"
    fi

    # --- Package ---
    header "3. Package archive"
    if [ "$DRY_RUN" = false ]; then
        if [ -z "$(ls -A "${work_dir}")" ]; then
            err "nothing to export — work directory is empty"
            rm -rf "$work_dir"
            exit 1
        fi
    fi

    dry_run_cmd "
        tar czf \"${archive_path}\" -C \"${work_dir}\" . &&
        ok \"archive created: ${archive_path}\"
    "

    if [ "$DRY_RUN" = false ]; then
        local size
        size="$(du -h "$archive_path" | cut -f1)"
        info "archive size: ${size}"
    fi

    # --- Summary ---
    header "4. Transfer instructions"
    cat <<TRANSFER
  Copy the archive to the target machine and run:

    scp ${archive_path} user@target:~/
    ssh user@target '${SCRIPT_NAME} import ${archive_name}'

  Or use a USB drive for air-gapped transfer.

  Archive contents:
TRANSFER

    if [ "$DRY_RUN" = false ]; then
        tar tzf "$archive_path" | sed 's/^/    /'
    else
        info "    (dry-run contents not available)"
    fi

    # Cleanup
    rm -rf "$work_dir"
}

# ---- Import ---------------------------------------------------------------
do_import() {
    local archive="$1"
    local skip_confirm="$2"
    local work_dir
    work_dir="$(mktemp -d)"

    if [ ! -f "$archive" ]; then
        err "archive not found: ${archive}"
        exit 1
    fi

    # Check archive magic
    if ! file "$archive" | grep -q 'gzip compressed data'; then
        err "file is not a gzip archive: ${archive}"
        exit 1
    fi

    info "importing from: ${archive}"
    echo

    # --- Confirm ---
    if [ "$skip_confirm" = false ] && [ "$DRY_RUN" = false ]; then
        info "This will OVERWRITE the following:"
        echo
        tar tzf "$archive" | while read -r line; do
            case "$line" in
                ssh/*)      echo "  ~/.ssh/${line#ssh/}" ;;
                gpg-*)      echo "  GPG key: ${line}" ;;
                *)          echo "  ${line}" ;;
            esac
        done
        echo
        if ! confirm "Continue with import?"; then
            info "import cancelled"
            rm -rf "$work_dir"
            exit 0
        fi
    fi

    # Extract
    header "1. Extracting archive"
    dry_run_cmd "tar xzf \"$archive\" -C \"${work_dir}\""
    ok "archive extracted"

    # --- SSH ---
    header "2. SSH keys"
    if [ -d "${work_dir}/ssh" ] && [ -n "$(ls -A "${work_dir}/ssh/" 2>/dev/null)" ]; then
        dry_run_cmd "
            cp -a \"${work_dir}/ssh/.\" \"$HOME/.ssh/\"
        "
        ok "SSH keys copied to ~/.ssh"

        # Fix permissions
        dry_run_cmd "
            chmod 700 \"$HOME/.ssh\" &&
            find \"$HOME/.ssh\" -type f -name 'id_*' ! -name '*.pub' -exec chmod 600 {} + &&
            find \"$HOME/.ssh\" -type f -name '*.pub' -exec chmod 644 {} + &&
            find \"$HOME/.ssh\" -type f -name 'config' -exec chmod 600 {} + 2>/dev/null || true
        "
        ok "SSH permissions fixed"
    else
        warn "no SSH data in archive — skipping"
    fi

    # --- GPG ---
    header "3. GPG keys"
    if [ -f "${work_dir}/gpg-secret.asc" ]; then
        dry_run_cmd "gpg --import \"${work_dir}/gpg-secret.asc\""
        ok "secret keys imported"

        if [ -f "${work_dir}/gpg-public.asc" ]; then
            dry_run_cmd "gpg --import \"${work_dir}/gpg-public.asc\""
            ok "public keys imported"
        fi

        if [ -f "${work_dir}/gpg-trust.txt" ]; then
            dry_run_cmd "gpg --import-ownertrust \"${work_dir}/gpg-trust.txt\""
            ok "ownertrust restored"
        fi
    elif [ -f "${work_dir}/gpg-public.asc" ]; then
        dry_run_cmd "gpg --import \"${work_dir}/gpg-public.asc\""
        ok "public keys imported (no secret keys in archive)"
    else
        warn "no GPG data in archive — skipping"
    fi

    # --- Verify ---
    header "4. Verification"

    if [ "$DRY_RUN" = false ]; then
        local ssh_count=0 gpg_count=0
        if [ -d "${work_dir}/ssh" ]; then
            ssh_count="$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' 2>/dev/null | wc -l)"
        fi
        gpg_count="$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c '^sec' || true)"

        echo "  SSH private keys in ~/.ssh: ${ssh_count}"
        echo "  GPG secret keys:            ${gpg_count}"

        if [ "$ssh_count" -gt 0 ] || [ "$gpg_count" -gt 0 ]; then
            ok "import complete"
        else
            warn "no keys found after import — something may be wrong"
        fi
    else
        info "  (verification skipped in dry-run mode)"
    fi

    # Cleanup
    rm -rf "$work_dir"
}

# ---- Argument parsing ----------------------------------------------------
parse_args() {
    local -n _command=$1; shift
    local -n _output_dir=$1; shift
    local -n _archive=$1; shift
    local -n _skip_confirm=$1; shift
    local -n _dry_run=$1; shift

    _command=""
    _output_dir="."
    _archive=""
    _skip_confirm=false
    _dry_run=false

    # Collect tokens into a flat array, splitting options and positional args.
    # We process in two passes: first find the command, then parse its options.
    local tokens=()
    for arg in "$@"; do
        tokens+=("$arg")
    done

    # Check for standalone --help
    if [ "$#" -eq 1 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
        usage
    fi

    # Locate the command index
    local cmd_idx=-1
    for i in "${!tokens[@]}"; do
        case "${tokens[$i]}" in
            -h|--help) usage ;;
            export|import)
                cmd_idx=$i
                _command="${tokens[$i]}"
                break
                ;;
        esac
    done

    if [ "$cmd_idx" -eq -1 ]; then
        err "missing command (export|import)"
        usage
    fi

    # Parse global options (before the command)
    local i=0
    while [ $i -lt "$cmd_idx" ]; do
        case "${tokens[$i]}" in
            -h|--help) usage ;;
            --dry-run)  _dry_run=true; i=$((i + 1)) ;;
            --yes)      _skip_confirm=true; i=$((i + 1)) ;;
            --output-dir)
                if [ $((i + 1)) -ge "$cmd_idx" ]; then
                    err "--output-dir requires an argument before command"; exit 1
                fi
                _output_dir="${tokens[$((i + 1))]}"; i=$((i + 2)) ;;
            --output-dir=*) _output_dir="${tokens[$i]#*=}"; i=$((i + 1)) ;;
            -*) err "unknown global option: ${tokens[$i]}"; exit 1 ;;
            *)  i=$((i + 1)) ;;
        esac
    done

    # Parse command-specific options (after the command)
    i=$((cmd_idx + 1))
    local positional=()
    while [ $i -lt "${#tokens[@]}" ]; do
        case "${tokens[$i]}" in
            -h|--help) usage ;;
            --dry-run)  _dry_run=true; i=$((i + 1)) ;;
            --yes)      _skip_confirm=true; i=$((i + 1)) ;;
            --output-dir)
                if [ $((i + 1)) -ge "${#tokens[@]}" ]; then
                    err "--output-dir requires an argument"; exit 1
                fi
                _output_dir="${tokens[$((i + 1))]}"; i=$((i + 2)) ;;
            --output-dir=*) _output_dir="${tokens[$i]#*=}"; i=$((i + 1)) ;;
            -*) err "unknown option: ${tokens[$i]}"; exit 1 ;;
            *)  positional+=("${tokens[$i]}"); i=$((i + 1)) ;;
        esac
    done

    if [ "$_command" = import ]; then
        if [ "${#positional[@]}" -eq 0 ]; then
            err "import requires an archive path"
            exit 1
        fi
        _archive="${positional[0]}"
    fi
}

# ---- Main -----------------------------------------------------------------
main() {
    if [ $# -eq 0 ]; then usage; fi

    local command output_dir archive skip_confirm DRY_RUN
    parse_args command output_dir archive skip_confirm DRY_RUN "$@"

    check_prereqs

    case "$command" in
        export)
            mkdir -p "$output_dir"
            output_dir="$(cd "$output_dir" && pwd 2>/dev/null || echo "$output_dir")"
            do_export "$output_dir"
            ;;
        import)
            archive="$(realpath "$archive" 2>/dev/null || echo "$archive")"
            do_import "$archive" "$skip_confirm"
            ;;
    esac
}

main "$@"
