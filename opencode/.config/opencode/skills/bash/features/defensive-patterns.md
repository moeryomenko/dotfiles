# Defensive Patterns

> **Framework**: Part of the [bash skill catalog](../SKILL.md). Load this feature first before any other bash feature.

Comprehensive defensive Bash programming guide for production-grade scripts. Each pattern includes a worked example with explanation and code.

## Table of Contents

1. [Strict Mode](#1-strict-mode)
2. [Error Trapping](#2-error-trapping)
3. [Variable Safety](#3-variable-safety)
4. [Array Handling](#4-array-handling)
5. [Conditional Safety](#5-conditional-safety)
6. [Safe Script Directory Detection](#6-safe-script-directory-detection)
7. [Comprehensive Function Template](#7-comprehensive-function-template)
8. [Safe Temporary File Handling](#8-safe-temporary-file-handling)
9. [Robust Argument Parsing](#9-robust-argument-parsing)
10. [Structured Logging](#10-structured-logging)
11. [Process Orchestration](#11-process-orchestration)
12. [Safe File Operations](#12-safe-file-operations)
13. [Idempotent Script Design](#13-idempotent-script-design)
14. [Dry-Run Support](#14-dry-run-support)
15. [Safe Command Substitution](#15-safe-command-substitution)
16. [Dependency Checking](#16-dependency-checking)

---

## 1. Strict Mode

Enable bash strict mode at the top of every script to catch errors early. This is the single most impactful defensive practice.

```bash
#!/bin/bash
set -Eeuo pipefail          # Catch errors, unset vars, pipe failures
shopt -s inherit_errexit    # Bash 4.4+: inherit -e inside command substitutions
IFS=$'\n\t'                 # Only split on newlines and tabs
```

**What each flag does:**

| Flag | Effect |
|------|--------|
| `-E` | Inherit ERR trap inside functions, command substitutions, and subshells |
| `-e` | Exit immediately if any command exits non-zero |
| `-u` | Treat unset variables as an error with exit |
| `-o pipefail` | A pipeline fails if **any** command in it fails (not just the last) |
| `inherit_errexit` | Shell-compat level 4.4+: propagate `-e` inside `$()` substitutions |
| `IFS=$'\n\t'` | Prevent word splitting on spaces, reducing quoting bugs |

**Consequence**: Without `set -Eeuo pipefail`, a script continues running after a failed command, often corrupting state or producing misleading results. Without `inherit_errexit`, command substitutions swallow errors silently.

> **Note**: Strict mode has caveats. `-e` can cause unexpected exits in conditionals (`if`, `&&`, `||`). Use explicit `|| true` or `|| :` after commands whose failure is acceptable. Test your scripts with strict mode before deploying.

---

## 2. Error Trapping

Use `trap` with `ERR` and `EXIT` to catch errors and clean up resources. The ERR trap fires before the EXIT trap on failure.

```bash
#!/bin/bash
set -Eeuo pipefail

# Capture cleanup PID for recursive cleanup
_CLEANUP_PID=$$

_cleanup() {
    local exit_code=$?
    echo "[CLEANUP] Exit code $exit_code — removing temporary files" >&2
    rm -rf -- "${TMPDIR:-/tmp/missing}"
    trap - ERR EXIT  # Prevent recursive trap
    exit "$exit_code"
}

_error_handler() {
    local line=$1
    local cmd=$2
    echo "[ERROR] Command failed at line $line: $cmd" >&2
}

trap _cleanup EXIT
trap '_error_handler $LINENO "$BASH_COMMAND"' ERR

TMPDIR=$(mktemp -d)
# Script logic follows...
```

**Consequence**: Without an EXIT trap, temporary files, locks, and system state changes leak on abnormal exit. Without an ERR trap, you get a bare "exit 1" with no indication of where or why.

**Pattern variations:**

| Trap target | Use |
|-------------|-----|
| `EXIT` | Always runs: cleanup resources, remove temp files, release locks |
| `ERR` | Only on error: log diagnostic info, capture stack trace |
| `SIGINT`/`SIGTERM` | User interrupt: graceful shutdown, child process cleanup |
| `RETURN` | Source-level: restore `IFS`, `cd` back to original dir after sourcing |

---

## 3. Variable Safety

Always quote variable expansions to prevent word splitting and globbing. Use `${var:?}` to enforce required variables.

```bash
#!/bin/bash
set -Eeuo pipefail

# Correct: always double-quote
cp -- "$source" "$dest"
rm -f -- "$file"
printf '%s\n' "$message"

# Required variable enforcement (script exits with message if unset)
: "${DEPLOY_ENV:?DEPLOY_ENV is not set — must be staging or production}"
: "${API_KEY:?API_KEY is required}"

# Safe default values
count="${COUNT:-10}"            # default to 10 if unset
debug="${DEBUG:=0}"             # set to 0 if unset (side effect)
name="${1:-default}"            # positional param with default

# Read from file into variable safely
content=$(<"$file")             # no cat, no subshell overhead

# Read array from command output
mapfile -t lines < <(grep -v '^#' "$config_file")

# Multi-character delimiter splitting
IFS=',' read -ra parts <<< "$csv_line"
```

**Consequence**: Unquoted `$var` splits on whitespace and expands globs. `$source` containing `file with spaces` becomes two arguments; `$input` containing `*` becomes a glob of all files. These are the most common source of subtle bash bugs.

---

## 4. Array Handling

Use indexed and associative arrays for groups of items. Use NUL-delimited streams for arbitrary filenames.

```bash
#!/bin/bash
set -Eeuo pipefail

# Indexed arrays
declare -a files=("config.yaml" "main.sh" "README.md")
files+=("new_file.txt")

# Safe iteration (preserves spaces in filenames)
for file in "${files[@]}"; do
    printf 'Processing: %s\n' "$file"
done

# Associative arrays (Bash 4.0+)
declare -A config=(
    [host]="localhost"
    [port]="8080"
    [debug]="true"
)
printf 'Host: %s\n' "${config[host]}"

# Reading file lines into an array
mapfile -t lines < <(command)   # strips trailing newline per entry
readarray -t numbers < <(seq 1 10)

# NUL-safe find (handles ANY filename — spaces, newlines, dashes)
while IFS= read -r -d '' file; do
    rm -f -- "$file"
done < <(find /tmp -name '*.tmp' -type f -print0)

# Safe array slicing
first_two=("${files[@]:0:2}")

# Array length
printf 'Count: %d\n' "${#files[@]}"
```

**Consequence**: Iterating with `for f in $(find ...)` breaks on filenames with spaces, tabs, or newlines. `while read -r line` without `-d ''` loses trailing newlines and fails on binary content. Using NUL-delimited streams (`-print0` / `-d ''`) is the only safe strategy for arbitrary filenames.

---

## 5. Conditional Safety

Use `[[ ]]` for Bash conditionals (safer, more features) and `[ ]` only when POSIX compatibility is required.

```bash
#!/bin/bash
set -Eeuo pipefail

# Prefer [[ ]] — no word splitting, no glob expansion, supports regex
if [[ -f "$file" && -r "$file" ]]; then
    content=$(<"$file")
fi

# Pattern matching with == and extended globs
if [[ "$filename" == *.sh ]]; then
    printf 'Shell script: %s\n' "$filename"
fi

# Regex matching (Bash 4.0+)
if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf 'Valid email: %s\n' "$email"
fi

# String comparison
if [[ "$mode" == "production" ]]; then
    DEBUG=false
fi

# Numeric comparison (use (( )) for integers)
if (( count > max )); then
    printf 'Count %d exceeds max %d\n' "$count" "$max"
fi

# File tests
[[   -e "$path" ]]  # exists (any type)
[[   -f "$path" ]]  # regular file
[[   -d "$path" ]]  # directory
[[   -L "$path" ]]  # symbolic link
[[   -r "$path" ]]  # readable
[[   -w "$path" ]]  # writable
[[   -x "$path" ]]  # executable
[[   -s "$path" ]]  # non-empty file
[[ ! -z "$var"  ]]  # not empty (or use -n)

# Compound conditions
if [[ -f "$file" && -s "$file" ]]; then
    printf '%s is a non-empty file\n' "$file"
fi

# Multi-condition (|| and && short-circuit)
[[ -z "$var" ]] && printf 'var is empty\n'
[[ -n "$var" ]] || printf 'var is empty\n'
```

**Consequence**: Using `[ ]` with unquoted variables causes word splitting and glob expansion. `[ $status = "" ]` becomes `[ = "" ]` if `$status` is empty, causing a syntax error. `[[ ]]` handles this safely by design.

**File test ordering**: Test existence before type. `[[ -f "$path" ]]` implies existence, but testing `[[ -e "$path" ]]` first gives a clearer error message: "does not exist" vs "not a regular file".

---

## 6. Safe Script Directory Detection

Determine the absolute directory of the running script, resolving symlinks. This is essential for scripts that need to locate sibling files, libraries, or data.

```bash
#!/bin/bash
set -Eeuo pipefail

# Resolve the full directory of the script (symlink-safe)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"

# Source libraries relative to script location
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/common.sh"

# Reference data files
CONFIG_FILE="${SCRIPT_DIR}/config/defaults.conf"

# Handle sourcing vs direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed, not sourced
    printf 'Running %s from %s\n' "$SCRIPT_NAME" "$SCRIPT_DIR"
    main "$@"
fi
```

**Consequence**: Without symlink resolution, a script invoked through a symlink to `/opt/app/bin/script.sh` thinks its parent dir is the symlink's directory, not `/opt/app/bin/`. `pwd -P` resolves to the physical directory. Without `${BASH_SOURCE[0]}` over `$0`, sourcing the script from another file gives the wrong path.

---

## 7. Comprehensive Function Template

Every function should declare `local` variables, document its purpose, validate inputs, and return explicit exit codes.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# validate_file — Check that a file exists and is readable
#
# Arguments:
#   $1 — path to file
#   $2 — optional custom error message
#
# Returns:
#   0 — file exists and is readable
#   1 — file does not exist or is not readable
# ---------------------------------------------------------------------------
validate_file() {
    local -r path="${1:?validate_file: missing path argument}"
    local -r message="${2:-File not found or unreadable: $path}"

    if [[ ! -f "$path" ]]; then
        printf 'ERROR: %s\n' "$message" >&2
        return 1
    fi

    if [[ ! -r "$path" ]]; then
        printf 'ERROR: Permission denied reading: %s\n' "$path" >&2
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# process_files — Process files from input directory into output directory
#
# Arguments:
#   $1 — input directory
#   $2 — output directory
#
# Returns:
#   0 — all files processed successfully
#   1 — input validation failed
# ---------------------------------------------------------------------------
process_files() {
    local -r input_dir="${1:?process_files: missing input_dir}"
    local -r output_dir="${2:?process_files: missing output_dir}"

    # Validate directories
    validate_file "$input_dir" "Input directory not found: $input_dir" || return 1

    if [[ ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir" || {
            printf 'ERROR: Cannot create output directory: %s\n' "$output_dir" >&2
            return 1
        }
    fi

    # Process files safely with NUL-delimited find
    local count=0
    while IFS= read -r -d '' file; do
        printf 'Processing: %s\n' "$file"
        # ... work ...
        ((count++))
    done < <(find "$input_dir" -maxdepth 1 -type f -print0)

    printf 'Processed %d file(s)\n' "$count"
    return 0
}
```

**Consequence**: Functions without `local` variables silently mutate global scope, causing impossible-to-debug state corruption. Functions without input validation fail with cryptic downstream errors instead of a clear "missing argument" message.

**Naming convention**: Prefix with a domain verb: `validate_*`, `ensure_*`, `run_*`, `get_*`, `set_*`, `log_*`.

---

## 8. Safe Temporary File Handling

Always use `mktemp` for temporary files and `trap` to guarantee cleanup. Never hardcode `/tmp/` paths.

```bash
#!/bin/bash
set -Eeuo pipefail

# Global vars for cleanup
_TMPDIR=""
_TMPFILES=()

_cleanup_temp() {
    local exit_code=$?
    if [[ -n "$_TMPDIR" && -d "$_TMPDIR" ]]; then
        rm -rf -- "$_TMPDIR"
    fi
    for tmpf in "${_TMPFILES[@]}"; do
        rm -f -- "$tmpf" 2>/dev/null || true
    done
    trap - EXIT ERR
    exit "$exit_code"
}
trap _cleanup_temp EXIT

# Pattern 1: Temporary directory (preferred)
_TMPDIR=$(mktemp -d) || {
    printf 'FATAL: Cannot create temporary directory\n' >&2
    exit 1
}

# Pattern 2: Single temporary file
tmpfile=$(mktemp) || exit 1
_TMPFILES+=("$tmpfile")

# Pattern 3: Temporary file with suffix
tmpcfg=$(mktemp --suffix=.yaml) || exit 1
_TMPFILES+=("$tmpcfg")

# Safe use: write atomically using temp file + mv
printf 'data' > "$_TMPDIR/output.tmp"
mv "$_TMPDIR/output.tmp" "/final/path.txt"

# Cleanup is automatic via trap — no manual cleanup needed
```

**Consequence**: Hardcoded `/tmp/myscript.$$` is predictable (security: symlink attacks) and never cleaned up on crash. `mktemp` creates random names in the secure temp directory. Without `trap` cleanup, temp files accumulate on every crash.

---

## 9. Robust Argument Parsing

Use a `while case` loop for short options (`getopts`) and a positional loop for long options. Validate required arguments after parsing.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Configuration defaults ----
VERBOSE=false
DRY_RUN=false
OUTPUT_FILE=""
THREADS=4
ARGS=()

# ---- Usage ----
usage() {
    cat <<EOF
Usage: ${0##*/} [OPTIONS] [ARGUMENTS...]

Options:
  -v, --verbose         Enable verbose output
  -d, --dry-run         Show what would be done without making changes
  -o, --output FILE     Write output to FILE (required)
  -j, --jobs NUM        Number of parallel jobs (default: $THREADS)
  -h, --help            Show this help and exit

Arguments are passed to the underlying command.
EOF
    exit "${1:-0}"
}

# ---- Parse options ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="${2:?--output requires a value}"
            shift 2
            ;;
        -o=*|--output=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        -j|--jobs)
            THREADS="${2:?--jobs requires a number}"
            shift 2
            ;;
        -j=*|--jobs=*)
            THREADS="${1#*=}"
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        --)
            shift
            ARGS+=("$@")
            break
            ;;
        -*)
            printf 'ERROR: Unknown option: %s\n' "$1" >&2
            usage 1
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# ---- Validate required arguments ----
[[ -n "$OUTPUT_FILE" ]] || {
    printf 'ERROR: --output is required\n' >&2
    usage 1
}

# ---- Execute ----
if [[ "$VERBOSE" == "true" ]]; then
    printf 'Output: %s\nThreads: %d\nDry-run: %s\n' \
        "$OUTPUT_FILE" "$THREADS" "$DRY_RUN"
fi
```

**Consequence**: Ad-hoc `$1`, `$2` parsing with shifting is fragile and unreadable. Mixing option order breaks the parser. This pattern handles `-o FILE`, `--output FILE`, `--output=FILE`, `--` separator, and unknown options consistently.

---

## 10. Structured Logging

Implement leveled logging with timestamps and stderr output. Never clutter stdout with diagnostic messages.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Log level constants ----
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# ---- Timestamp format ----
_log_timestamp() {
    date +'%Y-%m-%dT%H:%M:%S%z'
}

# ---- Logging functions ----
log_debug() {
    if (( LOG_LEVEL <= LOG_LEVEL_DEBUG )); then
        printf '[%s] DEBUG: %s\n' "$(_log_timestamp)" "$*" >&2
    fi
}

log_info() {
    if (( LOG_LEVEL <= LOG_LEVEL_INFO )); then
        printf '[%s] INFO: %s\n' "$(_log_timestamp)" "$*" >&2
    fi
}

log_warn() {
    if (( LOG_LEVEL <= LOG_LEVEL_WARN )); then
        printf '[%s] WARN: %s\n' "$(_log_timestamp)" "$*" >&2
    fi
}

log_error() {
    if (( LOG_LEVEL <= LOG_LEVEL_ERROR )); then
        printf '[%s] ERROR: %s\n' "$(_log_timestamp)" "$*" >&2
    fi
}

# ---- Syslog integration (optional) ----
log_syslog() {
    local level="$1"
    shift
    logger -t "${0##*/}" -p "user.${level}" "$*"
}

# ---- Usage ----
log_info 'Starting backup process'
log_debug 'Source: /data, Dest: /backup'
log_warn 'Low disk space on /backup'
log_error 'Failed to sync: connection timeout'
```

**Consequence**: Using `echo` or `printf` to stdout for diagnostics mixes program output with log messages, making both unparseable. Always use stderr (`>&2`) for logs. Timestamps at ISO 8601 format (`2026-07-16T14:30:00+0000`) enable log sorting and correlation.

---

## 11. Process Orchestration

Track background process PIDs and implement graceful shutdown with signal handling.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Process tracking ----
declare -a _BG_PIDS=()
declare -a _BG_NAMES=()

_bg_run() {
    local name="$1"
    shift
    "$@" &
    local pid=$!
    _BG_PIDS+=("$pid")
    _BG_NAMES+=("$name")
    log_debug "Started $name (PID $pid)"
}

# ---- Signal handler ----
_graceful_shutdown() {
    local signal="$1"
    log_info "Received $signal — shutting down gracefully"

    for i in "${!_BG_PIDS[@]}"; do
        local pid="${_BG_PIDS[$i]}"
        local name="${_BG_NAMES[$i]}"

        if kill -0 "$pid" 2>/dev/null; then
            log_info "Stopping $name (PID $pid)"
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # Wait for graceful shutdown with timeout
    local deadline=$(( SECONDS + 10 ))
    for pid in "${_BG_PIDS[@]}"; do
        remaining=$(( deadline - SECONDS ))
        if (( remaining > 0 )); then
            wait "$pid" 2>/dev/null || true
        else
            log_warn "Force killing PID $pid"
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    exit 1
}

trap '_graceful_shutdown SIGINT' SIGINT
trap '_graceful_shutdown SIGTERM' SIGTERM

# ---- Usage ----
_bg_run "worker-1" ./worker.sh --queue=incoming
_bg_run "worker-2" ./worker.sh --queue=outgoing

log_info "All workers started — waiting for completion"
wait
log_info "All workers finished"
```

**Consequence**: Background processes left running after a script exits become orphaned zombies. Without PID tracking and signal handlers, `Ctrl+C` or `kill` leaves child processes running indefinitely.

---

## 12. Safe File Operations

Atomic writes prevent partial-file reads. Safe move and rmdir prevent data loss.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Atomic write: write to temp then rename ----
atomic_write() {
    local target="$1"
    local tmpfile
    tmpfile=$(mktemp --tmpdir "$(basename "$target").XXXXXXXX") || return 1

    # Write content via stdin to temp file
    cat > "$tmpfile"

    # Preserve permissions if target exists
    if [[ -f "$target" ]]; then
        chmod --reference="$target" "$tmpfile" 2>/dev/null || true
    fi

    # Atomic rename (POSIX guarantees rename is atomic on same filesystem)
    mv -- "$tmpfile" "$target"
}

# Usage: printf 'data' | atomic_write "/etc/config/app.conf"

# ---- Safe move: never overwrite existing files ----
safe_move() {
    local source="$1"
    local dest="$2"

    [[ -e "$source" ]] || {
        printf 'ERROR: Source not found: %s\n' "$source" >&2
        return 1
    }
    [[ ! -e "$dest" ]] || {
        printf 'ERROR: Destination exists: %s\n' "$dest" >&2
        return 1
    }

    mv -- "$source" "$dest"
}

# ---- Safe rmdir: refuse non-empty directories ----
safe_rmdir() {
    local dir="$1"

    [[ -d "$dir" ]] || {
        printf 'ERROR: Not a directory: %s\n' "$dir" >&2
        return 1
    }

    # Check emptiness before removal
    if [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
        printf 'ERROR: Directory not empty: %s\n' "$dir" >&2
        return 1
    fi

    rmdir -- "$dir"
}

# ---- Atomic file update (backup + write) ----
safe_update() {
    local file="$1"
    local backup="${file}.bak.$(date +%s)"

    [[ -f "$file" ]] && cp -- "$file" "$backup"
    atomic_write "$file" < /dev/stdin
}
```

**Consequence**: Direct `>` redirection to the target file truncates it before writing. If the write fails mid-way, the target is empty or corrupt. Atomic write (`mktemp` + `mv`) ensures the target is either the old file or the complete new file — never a partial write.

---

## 13. Idempotent Script Design

An idempotent script produces the same final state regardless of how many times it runs. Every operation checks the current state before making changes.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Idempotent helpers ----

# Create directory only if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        log_debug "Directory already exists: $dir"
        return 0
    fi
    mkdir -p "$dir" || {
        log_error "Failed to create directory: $dir"
        return 1
    }
    log_info "Created directory: $dir"
}

# Write file only if content differs
ensure_file() {
    local target="$1"
    local content="$2"

    if [[ -f "$target" ]]; then
        local current
        current=$(<"$target")
        if [[ "$current" == "$content" ]]; then
            log_debug "File unchanged: $target"
            return 0
        fi
    fi

    printf '%s' "$content" > "$target"
    log_info "Updated: $target"
}

# Ensure symlink points to correct target
ensure_symlink() {
    local target="$1"
    local link_path="$2"

    local current
    current=$(readlink "$link_path" 2>/dev/null || true)
    if [[ "$current" == "$target" ]]; then
        log_debug "Symlink correct: $link_path -> $target"
        return 0
    fi

    ln -sf -- "$target" "$link_path"
    log_info "Set symlink: $link_path -> $target"
}

# Idempotent user/group creation
ensure_user() {
    local user="$1"
    if id "$user" &>/dev/null; then
        log_debug "User already exists: $user"
        return 0
    fi
    useradd "$user"
    log_info "Created user: $user"
}

# ---- Usage ----
ensure_directory "/var/lib/myapp/data"
ensure_file "/etc/myapp/config" "DEBUG=false\nMODE=production\n"
ensure_symlink "/var/lib/myapp/data" "/opt/myapp/data"
```

**Consequence**: Non-idempotent scripts fail on second run — directories already exist, files are overwritten, symlinks conflict, users already created. Every rerun of a non-idempotent script risks corruption or data loss. Idempotent scripts are safe to run in CI/CD pipelines, cron jobs, and recovery scenarios.

---

## 14. Dry-Run Support

A dry-run mode shows what the script *would* do without making changes. Every state-changing operation must check `DRY_RUN`.

```bash
#!/bin/bash
set -Eeuo pipefail

DRY_RUN="${DRY_RUN:-false}"

# ---- Execution wrapper ----
run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        printf '[DRY-RUN] Would execute: %s\n' "$*" >&2
        return 0
    fi
    "$@"
}

# ---- Higher-level operations ----
run_rm() {
    run_cmd rm -f -- "$@"
}

run_mv() {
    run_cmd mv -- "$@"
}

run_mkdir() {
    run_cmd mkdir -p -- "$@"
}

run_ln() {
    run_cmd ln -sf -- "$@"
}

run_chown() {
    run_cmd chown -- "$@"
}

# ---- Usage ----
run_mkdir "/var/lib/myapp/data"
run_rm "/tmp/old_cache"
run_mv "/tmp/output" "/final/path"
run_ln "/opt/app/current-version" "/opt/app/current"

# Conditional dry-run from CLI
#   DRY_RUN=true ./script.sh
#   ./script.sh --dry-run  (see Pattern 9 for arg parsing)
```

**Consequence**: Without a dry-run pattern, users must either run the script and hope (risking destruction) or manually trace through the code. A `run_cmd` wrapper makes every operation reviewable and testable. Always log dry-run operations to stderr so stdout remains parsable.

---

## 15. Safe Command Substitution

Always use `$()` over backticks. Use NUL-delimited iteration for arbitrary output. Check substitution exit codes.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Preferred: $() over backticks ----
# Backticks (legacy — fragile, harder to nest)
# output=`command`     # NO: quoting issues, no nesting

# Modern: $() — clear, nestable, consistent quoting
output=$(command -v python3)

# ---- Capture with error checking ----
result=$(some_command) || {
    log_error "some_command failed with exit $?"
    return 1
}

# ---- Read file into variable (no subshell) ----
content=$(<"$file")          # equivalent to $(cat "$file") but no fork

# ---- Multi-line output into array ----
mapfile -t lines < <(grep -v '^#' "$config_file")

# ---- NUL-safe iteration (handles spaces, newlines, glob chars) ----
while IFS= read -r -d '' file; do
    printf 'Processing: %s\n' "$file"
done < <(find /var/log -name '*.log' -mtime +30 -print0)

# ---- Safe variable default from command ----
timestamp="${EPOCHSECONDS:-$(date +%s)}"

# ---- Avoid eval ----
# NEVER do: eval "cmd=$(dynamic_value)"
# Use arrays instead:
cmd_args=(curl -s -H "Authorization: Bearer $token" "$url")
"${cmd_args[@]}"
```

**Consequence**: Backticks have inconsistent escaping rules, cannot be nested, and are hard to spot in code reviews. `$()` works consistently with quoting and escapes, nests cleanly (`$(command1 $(command2))`), and is POSIX-compliant.

**NUL safety**: `for f in $(find ...)` splits on every space, tab, and newline in filenames. `find ... -print0` + `read -d ''` is the only pattern that handles all valid Unix filenames.

---

## 16. Dependency Checking

Use `command -v` (POSIX-compliant) instead of `which` (external command, inconsistent exit codes). Centralize checks at script start.

```bash
#!/bin/bash
set -Eeuo pipefail

# ---- Dependency check helper ----
check_deps() {
    local -r context="${1:-script}"
    shift
    local -a missing=()
    local cmd

    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        printf 'ERROR: %s requires: %s\n' "$context" "${missing[*]}" >&2
        printf 'Install missing dependencies:\n' >&2
        for cmd in "${missing[@]}"; do
            printf '  - %s\n' "$cmd" >&2
        done
        return 1
    fi
}

# ---- Version checking (when specific versions are needed) ----
check_version() {
    local cmd="$1"
    local min_version="$2"
    local actual

    actual=$("$cmd" --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || true)
    if [[ -z "$actual" ]]; then
        log_warn "Could not determine version for $cmd"
        return 0
    fi

    # Simple string comparison (works for semver with same digit count)
    if [[ "$actual" < "$min_version" ]]; then
        log_error "$cmd version $actual < required $min_version"
        return 1
    fi
}

# ---- Usage ----
check_deps "${0##*/}" jq curl git python3
check_version python3 3.8.0

# ---- `type` vs `command -v` ----
# POSIX: command -v cmd   — exits 0 if found, 1 if not (standardized)
# Avoid: which cmd        — not POSIX, exit code varies by implementation
# Avoid: type cmd         — not POSIX, output format varies
```

**Consequence**: `which` is not POSIX and may exit 0 even when a command isn't functional, depending on the implementation. `command -v` is standardized by POSIX, has a consistent interface, and is a shell builtin that does not fork an external process.

---

## Verification Markers

> [Check] Strict mode enabled with `set -Eeuo pipefail`, `shopt -s inherit_errexit`, `IFS=$'\n\t'`
> [Check] Error trapping uses `trap ... EXIT` for cleanup, `trap ... ERR` for diagnostics
> [Check] Every variable expansion is quoted: `"$var"`, `"${arr[@]}"`
> [Check] Required variables enforced with `: "${VAR:?message}"`
> [Check] Arrays handled safely: `mapfile`/`readarray`, NUL-delimited `find -print0`
> [Check] Conditionals use `[[ ]]` over `[ ]` (except POSIX contexts)
> [Check] Script directory resolved symlink-safe: `$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)`
> [Check] Functions declare `local -r` variables and document arguments
> [Check] Temporary files created via `mktemp` with `trap` cleanup
> [Check] Argument parsing handles short, long, combined (`-o=FILE`), `--`, and errors
> [Check] Structured logging uses levels, timestamps, and stderr output
> [Check] Background PIDs tracked; `SIGTERM`/`SIGINT` handled for graceful shutdown
> [Check] File operations atomic: `mktemp` → write → `mv` for atomic writes
> [Check] Scripts designed idempotent: check state before mutating
> [Check] `DRY_RUN` guarded `run_cmd` wrapper for all destructive operations
> [Check] Command substitution uses `$()` over backticks
> [Check] Dependencies checked via `command -v` over `which`
> [Check] Cross-reference: this feature is the ALWAYS READ first-load for `bash/SKILL.md`
