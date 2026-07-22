# Project Structure

Recommended layout, library sourcing conventions, module system, function naming, exit codes, dependency management, documentation generation, configuration patterns, and build tooling for Bash projects.

## Recommended Layout

A well-organized Bash project mirrors established conventions from other scripting languages. The standard layout separates concerns across clearly named directories:

```
project/
├── bin/           # Entry-point scripts (executable, thin argument parsers)
├── lib/           # Library scripts (sourced, never executed directly)
├── tests/         # BATS test files
├── fixtures/      # Test fixture data (expected output, mock configs)
├── docs/          # Documentation (markdown)
├── man/           # Man page sources (roff)
├── .env           # Local configuration (gitignored)
├── .env.example   # Documented example configuration
├── .editorconfig  # Editor settings
├── .gitattributes # Git attribute overrides
├── Makefile       # Build, test, lint targets
├── shell.nix      # Optional: reproducible dev shell (Nix)
└── README.md      # Project overview and quickstart
```

### Directory Purposes

| Directory | Purpose | Executable? | Sourced? |
|-----------|---------|-------------|----------|
| `bin/` | Public entry points, thin argument parsers | Yes | No |
| `lib/` | Reusable library code with function definitions | No | Yes |
| `tests/` | BATS test suites, one file per component | Yes (BATS) | No |
| `fixtures/` | Static test data, expected outputs, config stubs | No | No |
| `docs/` | Project documentation in Markdown | No | No |
| `man/` | Man page sources (troff/groff format) | No | No |

### When to Use Each Layout Element

- **`bin/`**: Always. Every project needs at least one entry point.
- **`lib/`**: Always when the project has more than one script or any shared logic.
- **`tests/`**: Always for any project meant to be maintained. Tests are not optional.
- **`fixtures/`**: When test data exceeds inline heredocs or is shared across test files.
- **`docs/`**: When the project has usage documentation beyond a README.
- **`man/`**: When the project provides system-level commands installed globally.

## Library Pattern

Library scripts live in `lib/` and are sourced, never executed directly. Every library follows a strict pattern:

### Library Header Template

```bash
#!/usr/bin/env bash
#
# lib/validate.sh — Input validation utilities
#
# Copyright (c) 2024 Project Author
# SPDX-License-Identifier: MIT
#
# Usage in scripts:
#   source "$(cd "${BASH_SOURCE[0]%/*}" && pwd)/lib/validate.sh"

set -Eeuo pipefail

# Resolve SCRIPT_DIR relative to the *calling* script's BASH_SOURCE
# so sourced files can locate siblings.
SCRIPT_DIR="$(cd "${BASH_SOURCE[1]%/*}" && pwd)"
readonly SCRIPT_DIR

# --- Guard against double-sourcing ---
[[ -z ${_VALIDATE_SH:-} ]] || return
_VALIDATE_SH=1
readonly _VALIDATE_SH

# --- Dependencies ---
# This library requires: realpath, grep -P

# --- Library code ---
```

### Header Elements Explained

| Element | Purpose |
|---------|---------|
| Shebang | `#!/usr/bin/env bash` for editor detection even though the file is sourced |
| Doc comment | Author, license, usage hint for consumers |
| `set -Eeuo pipefail` | Same strict mode as entry points (see defensive-patterns) |
| `SCRIPT_DIR` | Resolved from the caller's `BASH_SOURCE[1]` so relative paths work |
| Guard | Prevents double-sourcing. Underscore-prefixed, uppercase variable |
| Dependencies | Comment listing external commands the library requires |

### Function Prefix Convention

Every function in a library carries a prefix matching the library filename:

```bash
# lib/validate.sh — all functions prefixed with validate_

# Check that a value is a non-empty string
validate_nonempty() {
    local name="$1" value="$2"
    [[ -n $value ]] || die "validate: $name must not be empty"
}

# Check that a value matches a regex
validate_match() {
    local name="$1" value="$2" pattern="$3"
    [[ $value =~ $pattern ]] || die "validate: $name does not match required pattern"
}
```

**Convention**: filename `validate.sh` → function prefix `validate_`. This prevents collisions when multiple libraries are sourced in the same shell.

## Module System

For larger Bash projects, a module system prevents expensive re-initialization and manages load order.

### Source Guard Pattern

```bash
# lib/net/http.sh — HTTP client module
#
# Load with:
#   source "${SCRIPT_DIR}/lib/net/http.sh"

# Guard: exit immediately if already loaded
[[ -z ${_NET_HTTP_SH:-} ]] || return
_NET_HTTP_SH=1
readonly _NET_HTTP_SH

# --- Dependencies ---
# Requires: curl, jq

# Verify that all dependencies are available
if ! command -v curl &>/dev/null; then
    echo "net/http: requires curl" >&2
    return 1
fi
```

### Module Organization (Nested Namespaces)

```
lib/
├── net/
│   ├── http.sh      # _NET_HTTP_SH
│   └── dns.sh       # _NET_DNS_SH
├── fs/
│   ├── path.sh      # _FS_PATH_SH
│   └── temp.sh      # _FS_TEMP_SH
└── validate.sh      # _VALIDATE_SH
```

The guard variable mirrors the path: `lib/net/http.sh` → `_NET_HTTP_SH`. Replace `/` with `_`, uppercase, append `_SH`.

### Module Loader Function (Optional)

For projects with many interdependent modules, a loader function can manage the load graph:

```bash
# lib/loader.sh — Module dependency loader
#
# Usage: load "net/http" "fs/path"

_LOADER_SH=1
readonly _LOADER_SH

# Load one or more modules by relative path under lib/
load() {
    local module
    for module in "$@"; do
        local path="${SCRIPT_DIR}/lib/${module}.sh"
        if [[ ! -f $path ]]; then
            echo "loader: module not found: ${module}" >&2
            return 1
        fi
        # shellcheck source=/dev/null
        source "$path"
    done
}
```

## Entry Point Pattern

Entry points in `bin/` are the public interface. They should be thin — parse arguments, validate inputs, delegate to library functions.

```bash
#!/usr/bin/env bash
#
# bin/backup — Create and manage backups
#
# Usage: backup <command> [options]
#
# Commands:
#   create  Create a new backup
#   list    List existing backups
#   restore Restore from a backup
#
# Options:
#   -d, --dir DIR    Target directory (default: .)
#   -v, --verbose    Enable verbose output
#   -h, --help       Show this help

set -Eeuo pipefail

# --- Bootstrap: find project root from script location ---
SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_ROOT

# --- Source libraries ---
# shellcheck source=../lib/validate.sh
source "$PROJECT_ROOT/lib/validate.sh"
# shellcheck source=../lib/backup.sh
source "$PROJECT_ROOT/lib/backup.sh"

# --- Argument parsing ---
main() {
    local cmd="" dir="." verbose=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)    dir="$2"; shift 2 ;;
            -v|--verbose) verbose=1; shift ;;
            -h|--help)   show_help; exit 0 ;;
            create|list|restore) cmd="$1"; shift ;;
            *)           echo "unknown option: $1" >&2; exit 2 ;;
        esac
    done

    validate_nonempty "command" "$cmd"

    # Delegate to library
    run_backup_ "$cmd" "$dir" "$verbose"
}

main "$@"
```

### Entry Point Rules

1. **Thin**: No logic beyond argument parsing and dispatch. All real work is in `lib/`.
2. **Explicit bootstrap**: Resolve `SCRIPT_DIR` and `PROJECT_ROOT` from `BASH_SOURCE[0]`.
3. **ShellCheck directives**: Use `# shellcheck source=...` so ShellCheck follows library sources.
4. **Usage message**: Every entry point prints usage with `-h`/`--help`.
5. **Exit codes**: Use standard exit codes (see below).

## Function Naming

Consistent function naming makes code self-documenting. Use verb prefixes to signal intent:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `validate_*` | Input validation, returns error on invalid data | `validate_path "$path"` |
| `ensure_*` | Idempotent setup — succeeds if already done | `ensure_dir "$dir"` |
| `run_*` | Execute an action, may produce side effects | `run_backup "$src" "$dest"` |
| `get_*` | Return a value via stdout (pure-ish) | `get_temp_dir` |
| `set_*` | Mutate state or configuration | `set_log_level debug` |
| `has_*` | Boolean check, returns 0/1 | `has_command jq` |
| `is_*` | State predicate | `is_mounted "/mnt"` |
| `die` | Log error and exit | `die "failed to connect"` |
| `cleanup_*` | Resource teardown | `cleanup_temp_files` |

### Example Implementation

```bash
# Boolean predicate
has_command() {
    command -v "$1" &>/dev/null
}

# Idempotent setup
ensure_dir() {
    local dir="$1"
    if [[ ! -d $dir ]]; then
        mkdir -p "$dir"
    fi
}

# Action function
run_sync() {
    local src="$1" dest="$2"
    rsync -a --delete "$src" "$dest"
}
```

### Private Functions

Prefix with double underscore to signal "internal — not part of public API":

```bash
# Internal helper, not for external use
__validate_parse_flags() { ... }
```

## Exit Codes

Use standard exit codes consistently. These match conventions used by system commands and the GNU Coding Standards.

| Code | Meaning | When to Use |
|------|---------|-------------|
| `0` | Success | Everything completed as expected |
| `1` | General error | Most runtime failures, validation errors |
| `2` | Misuse | Invalid option, missing argument, wrong invocation |
| `126` | Cannot execute | File is not executable or is a directory |
| `127` | Command not found | A required command is not on PATH |
| `128` | Invalid exit | Used internally by bash for out-of-range exits |
| `128+N` | Signal N | `130` = SIGINT (Ctrl+C), `137` = SIGKILL, `143` = SIGTERM |
| `64-78` | Reserved | EX_USAGE through EX_OSFILE (from sysexits.h) |

### Usage in Scripts

```bash
# General error
die() {
    echo "error: $*" >&2
    exit 1
}

# Command not found
if ! command -v jq &>/dev/null; then
    echo "error: jq is required but not on PATH" >&2
    exit 127
fi

# Invalid usage
if [[ $# -eq 0 ]]; then
    echo "usage: ${0##*/} <file>" >&2
    exit 2
fi
```

### Exit in Libraries

Library functions should `return` exit codes, not `exit`. Leave `exit` to entry points:

```bash
# lib/validate.sh — returns 1, does not exit
validate_nonempty() {
    local name="$1" value="$2"
    if [[ -z $value ]]; then
        echo "validate $name: must not be empty" >&2
        return 1
    fi
    return 0
}
```

The entry point calls `die` on non-zero returns:

```bash
validate_nonempty "path" "$path" || die "invalid path"
```

## Dependency Management

Bash has no native package manager. Dependencies are managed through vendoring or community tools.

### Vendoring (Preferred for Small Dependencies)

Copy library code into a `vendor/` directory and source it directly:

```
project/
├── lib/          # First-party libraries
└── vendor/       # Third-party libraries, frozen at specific versions
    └── colors.sh  # From github.com/example/bash-colors@v1.2.0
```

Each vendored file includes a comment identifying its origin and version:

```bash
# vendor/colors.sh — Terminal color helpers
# Source: https://github.com/example/bash-colors v1.2.0
# License: MIT
# Checksum: sha256-<hash>
```

### Community Tools

| Tool | Description | Install |
|------|-------------|---------|
| [bpkg](https://www.bpkg.dev/) | Bash package manager, npm-like | `curl -fsSL https://bpkg.sh/install.sh \| bash` |
| [basher](https://github.com/basherpm/basher) | Bash package manager with git-based installs | `brew install basher` or `apt install basher` |
| [bashly](https://bashly.dev/) | CLI generator with dependency support | `gem install bashly` |

### Checksum Verification

For critical dependencies (especially in CI/CD pipelines), verify checksums:

```bash
# Verify a vendored dependency
verify_checksum() {
    local file="$1" expected="$2"
    local actual
    actual=$(sha256sum "$file" | cut -d' ' -f1)
    if [[ $actual != "$expected" ]]; then
        echo "checksum mismatch for $file" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        return 1
    fi
}
```

## Documentation Generation

### Markdown with `shdoc`

[shdoc](https://github.com/reconquest/shdoc) generates Markdown documentation from specially formatted comments:

```bash
# lib/validate.sh

# @description Check that a value matches a regex pattern
#
# @example
#   validate_match "username" "$input" '^[a-z]+$'
#
# @arg $1 string Field name (for error messages)
# @arg $2 string Value to check
# @arg $3 string Regex pattern
#
# @exitcode 0 Value matches pattern
# @exitcode 1 Value does not match pattern
#
# @see validate_nonempty
validate_match() {
    local name="$1" value="$2" pattern="$3"
    if [[ ! $value =~ $pattern ]]; then
        echo "validate $name: must match pattern" >&2
        return 1
    fi
}
```

Generate docs:

```bash
shdoc lib/validate.sh > docs/validate.md
```

### Man Pages with `shellman`

[shellman](https://github.com/yousefvand/shellman) generates troff-format man pages:

```bash
# Write man page source in docs/backup.1.md
shellman docs/backup.1.md > man/backup.1
```

### Makefile Targets for Docs

```makefile
# Generate documentation
docs: docs/api

docs/api: lib/*.sh
	mkdir -p docs/api
	for f in lib/*.sh; do \
		shdoc "$$f" > "docs/api/$$(basename "$$f" .sh).md"; \
	done

man: man/%.1: docs/%.1.md
	shellman "$<" > "$@"

.PHONY: docs man
```

## Configuration Patterns

### Sourcing `.env`

```bash
# Load .env if present (must be in project root)
load_env() {
    local env_file="${1:-${PROJECT_ROOT:-.}/.env}"
    if [[ -f $env_file ]]; then
        # shellcheck source=/dev/null
        source "$env_file"
    fi
}
```

### Defaults with Override Chain

Configuration resolution follows a three-tier chain:

```bash
# 1. Hard-coded defaults
: "${BACKUP_DIR:=/var/backups}"
: "${BACKUP_RETENTION_DAYS:=30}"
: "${BACKUP_COMPRESS:=gzip}"

# 2. Environment file overrides (lowest priority)
load_env

# 3. Environment variable overrides (highest priority)
# BACKUP_DIR=/custom/path ./script.sh
```

### Configuration with `config.sh` Library

For complex config, create a dedicated config module:

```bash
# lib/config.sh — Configuration loading with override chain

_CONFIG_SH=1
readonly _CONFIG_SH

# Default configuration
config_defaults() {
    : "${CFG_HOST:=localhost}"
    : "${CFG_PORT:=8080}"
    : "${CFG_SSL:=false}"
    : "${CFG_LOG_LEVEL:=info}"
}

# Load config from file (format: KEY=VALUE)
config_load_file() {
    local file="$1"
    if [[ ! -f $file ]]; then
        echo "config: file not found: $file" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$file"
}

# Full initialization
config_init() {
    config_defaults
    load_env "${PROJECT_ROOT}/.env"
    config_load_file "${XDG_CONFIG_HOME}/project/config" 2>/dev/null || true
}
```

## Makefile Targets

Standardize on these targets for consistency across Bash projects:

```makefile
SHELL := /usr/bin/env bash
SCRIPTS := $(shell find bin/ lib/ -type f -name '*.sh')
TESTS := $(shell find tests/ -type f -name '*.bats')

.PHONY: lint format test check build clean docs

# Lint with ShellCheck
lint:
	shellcheck $(SCRIPTS)

# Format with shfmt
format:
	shfmt -w $(SCRIPTS)

# Run BATS tests
test:
	bats tests/

# Run all quality checks
check: lint test

# Build / install (varies by project)
build:
	@echo "Building project..."  # Replace with actual build steps

# Clean generated artifacts
clean:
	rm -rf docs/api/ man/

# Generate documentation
docs:
	@echo "Generating docs..."  # See Documentation Generation section

# Development server / watch (optional)
dev:
	@echo "Starting dev environment..."

# Print available targets
help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | sort | \
		awk -F: '{printf "  %-10s %s\n", $$1, ""}'
```

### Makefile Notes

- Use `.PHONY` for all non-file targets.
- `SHELL := /usr/bin/env bash` ensures Make uses Bash, not `sh`.
- Keep targets composable: `check` runs `lint` + `test`.
- The `help` target documents available commands.

## `.editorconfig` and `.gitattributes`

### `.editorconfig`

```ini
# .editorconfig — Editor settings for shell scripts
root = true

[*]
indent_style = space
indent_size = 4
tab_width = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.sh]
indent_style = space
indent_size = 4
# ShellCheck and shfmt both default to 4-space indentation
# https://www.shellcheck.net/wiki/SC2323

[Makefile]
indent_style = tab
indent_size = 4
# Makefiles require tabs for rules

[*.md]
trim_trailing_whitespace = false
# Allow trailing whitespace in Markdown (hard line breaks)
```

### `.gitattributes`

```ini
# .gitattributes — Git attribute overrides for shell projects
*.sh   text eol=lf diff=bash
*.bats text eol=lf diff=bash
*.env  text eol=lf
Makefile text eol=lf

# Binary files that shouldn't be diffed
*.png  binary
*.jpg  binary
*.gz   binary

# Generated files
docs/api/** linguist-generated=true
man/** linguist-generated=true
```

Key attributes explained:

- `text eol=lf`: Normalize line endings to LF on checkout (even on Windows).
- `diff=bash`: Use Bash syntax highlighting in diffs for `.sh` and `.bats` files.
- `linguist-generated=true`: Mark generated files so language statistics and diffs exclude them.

## Verification

[Check] Recommended layout covers bin/, lib/, tests/, fixtures/, docs/, man/
[Check] Library pattern documented with header template, guard clause, SCRIPT_DIR, function prefixes
[Check] Module system documented with source guard pattern and nested namespace convention
[Check] Entry point pattern documented with thin arg parser delegating to lib functions
[Check] Function naming documented with prefix conventions: validate_, ensure_, run_, get_, set_, has_, is_
[Check] Exit codes documented: 0 success, 1 error, 2 misuse, 126-127 command, 128+ signals
[Check] Library functions return codes, entry points call exit
[Check] Dependency management covers vendoring, bpkg, basher, checksum verification
[Check] Documentation covers shdoc for markdown and shellman for man pages
[Check] Config patterns cover .env sourcing, defaults, override chains
[Check] Makefile targets cover lint, format, test, check, build
[Check] .editorconfig and .gitattributes documented with shell-specific settings
