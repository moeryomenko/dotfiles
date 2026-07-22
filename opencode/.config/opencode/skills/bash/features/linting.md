# Linting (ShellCheck & shfmt)

ShellCheck enforces correctness and portability; shfmt enforces consistent formatting. Together they form the linting layer of the Bash quality gate.

---

## ShellCheck Fundamentals

### Installation

| Method | Command | Notes |
|--------|---------|-------|
| **Debian/Ubuntu** | `apt-get install shellcheck` | Often outdated — use the binary or cabal for latest |
| **Arch Linux** | `pacman -S shellcheck` | Reasonably current |
| **macOS (Homebrew)** | `brew install shellcheck` | Latest stable |
| **From binary (recommended)** | Download from [GitHub releases](https://github.com/koalaman/shellcheck/releases) | Prefer this for CI to pin a version |
| **Via cabal** | `cabal install shellcheck` | Bleeding edge |
| **Via Docker** | `docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable` | No local install needed |
| **As a pre-commit hook** | See pre-commit section below | Automatic per-repo |

### Shell Dialects

ShellCheck supports multiple shell targets via the `--shell` flag or `.shellcheckrc`:

| Target | Flag | Use Case |
|--------|------|----------|
| `bash` | `--shell=bash` | Full Bash syntax (default) |
| `sh` | `--shell=sh` | POSIX sh — disables bashisms |
| `dash` | `--shell=dash` | Dash-specific semantics |
| `ksh` | `--shell=ksh` | Korn shell |
| `busybox` | `--shell=busybox` | BusyBox ash |

### Running ShellCheck

```bash
# Single file
shellcheck myscript.sh

# All scripts in a directory
shellcheck --shell=bash lib/*.sh bin/*.sh

# Recursive — find all .sh files
find . -name '*.sh' -exec shellcheck {} +

# With explicit dialect
shellcheck --shell=sh --severity=style myposix.sh

# Scan from stdin
cat myscript.sh | shellcheck -
```

> [Check] shellcheck installed and available via `shellcheck --version`
> [Check] --shell flag matches the shebang or project target

---

## `.shellcheckrc` Project Configuration

Place a `.shellcheckrc` file in the project root. ShellCheck picks it up automatically when run from that directory.

```ini
# .shellcheckrc — Project-wide ShellCheck configuration

# Target shell dialect
shell=bash

# Enable strict mode checks
enable=all

# Disable pedantic warnings that don't fit the project
disable=SC1091    # Not following external source — expected in our env
disable=SC2154    # Variable referenced but not assigned — sourced from env
disable=SC2034    # Variable appears unused — used via indirect reference
disable=SC2086    # Double quote to prevent globbing — intentional in safe context

# Source path hints for external files (SC1090/SC1091)
source-path=SCRIPTDIR
source-path=lib/
source-path=/usr/local/lib/bash/
```

### Key Directives

| Directive | Purpose |
|-----------|---------|
| `shell=bash` | Set target shell dialect |
| `enable=all` | Enable all checks including optional/style |
| `enable=check-uname-os` | Enable platform-specific checks |
| `disable=SC####` | Suppress a specific code project-wide |
| `source-path=PATH` | Tell ShellCheck where to look for sourced files |
| `external-sources=true` | Follow external sources (off by default) |

### Configuration for Strict POSIX

```ini
# .shellcheckrc — Strict POSIX sh project
shell=sh
enable=all
disable=SC2039    # In POSIX mode, SC2039 is handled by default
```

### Configuration for Bash Development

```ini
# .shellcheckrc — Bash library/module project
shell=bash
enable=all
disable=SC1091,SC2154,SC2034,SC2086
source-path=SCRIPTDIR
source-path=lib/
external-sources=true
```

### Configuration for CI/CD

```ini
# .shellcheckrc — CI pipeline scripts
shell=bash
enable=all
disable=SC1091,SC2154
```

> [Check] `.shellcheckrc` placed at project root
> [Check] `shell=` directive matches the shebang line of target scripts

---

## Environment Variables

ShellCheck respects these environment variables:

| Variable | Effect |
|----------|--------|
| `SHELLCHECK_SHELL` | Override default shell dialect (e.g., `sh`, `bash`, `dash`) |
| `SHELLCHECK_STRICT` | Set to `1` to enable `enable=all` and `severity=style` |
| `SHELLCHECK_OPTS` | Pass additional CLI flags |
| `LC_ALL` | Affects locale-sensitive checks (e.g., character classes) |

```bash
# Use in CI or wrapper scripts
export SHELLCHECK_SHELL=bash
export SHELLCHECK_STRICT=1
shellcheck myscript.sh

# Equivalent to:
# shellcheck --shell=bash --severity=style myscript.sh
```

> [Check] `SHELLCHECK_SHELL` set to correct dialect in CI
> [Check] `SHELLCHECK_STRICT` enabled for maximum coverage

---

## Error Code Categories

ShellCheck error codes follow a numeric range system. Despite the ranges, not every number in a range is assigned — codes cluster by general topic.

| Range | Category | Examples |
|-------|----------|----------|
| SC1000–SC1999 | **Parsing / syntax** | SC1000: `$` is not used specially; SC1078: quote mismatch |
| SC2000–SC2099 | **Shell semantics / correctness** | SC2000: `$` is not used specially for `$?`; SC2001: simplify `sed`; SC2002: useless `cat` |
| SC2100–SC2199 | **Quoting / escaping / expansions** | SC2100: use `[[ ]]` over `[ ]`; SC2148: missing shebang; SC2155: declare+assign separate |
| SC2200–SC2299 | **Globbing / word splitting** | SC2200: brace expansion; SC2206: word splitting on array assignment |
| SC3000–SC3099 | **POSIX sh compatibility** | SC3010: `[[ ]]` not POSIX; SC3020: `$(<file)` not POSIX |
| SC4000–SC4099 | **Style / conventions** | SC4000: function definition style; SC4001: `$` on mapfile/readarray |
| SC5000–SC5099 | **Miscellaneous / specialized** | SC5000: Bash 4.3+ version checks |

### Most-Encountered Codes

```bash
# SC1000 — $ is not used specially
# Bad: echo "The cost is $10"
# Good: echo "The cost is \$10"

# SC2000 — $ is not used specially for $? (see SC1000)
# Bad: if [ $? -ne 0 ]
# Good: if mycommand; then ...

# SC2100 — Use [[ ]] over [ ] (in Bash)
# Bad: if [ "$x" = "y" ]
# Good: if [[ "$x" == "y" ]]

# SC2154 — Variable referenced but not assigned
# Bad: echo "$MYVAR"  # MYVAR never set
# Good: MYVAR="${MYVAR:-default}"; echo "$MYVAR"

# SC2086 — Double quote to prevent globbing/word splitting
# Bad: rm -rf $DIR
# Good: rm -rf "$DIR"

# SC2046 — Quote this to prevent word splitting
# Bad: rm $(find . -name '*.tmp')
# Good: rm "$(find . -name '*.tmp')"

# SC2068 — Double quote array expansions
# Bad: for f in $arr; do
# Good: for f in "${arr[@]}"; do

# SC3010 — [[ ]] is not POSIX sh
# Bad: if [[ "$x" = "y" ]]; then ...  (in sh target)
# Good: if [ "$x" = "y" ]; then ...

# SC3020 — $(<file) is not POSIX sh
# Bad: content=$(<config.txt)  (in sh target)
# Good: content=$(cat config.txt)
```

> [Check] SC1xxx codes are syntax issues; fix shebangs, brackets, quotes
> [Check] SC2xxx codes are common logic errors; prefer `[[ ]]`, `$(<file)`, and quoting
> [Check] SC3xxx codes flag POSIX-incompatible bashisms
> [Check] SC4xxx codes are style guidelines; lower priority

---

## Suppression Patterns

### Inline Suppression

Suppress a single warning on the line it fires:

```bash
# shellcheck disable=SC2086
rm -rf $DIR

# Multiple codes on one line
# shellcheck disable=SC2086,SC2046
rm $(find . -name '*.tmp')

# With justification comment
# shellcheck disable=SC2086  # Intentional word splitting on $DIR
rm -rf $DIR
```

### Block-Level Suppression

Suppress for a code block (block-level scope) — all lines until the next directive:

```bash
# shellcheck disable=SC2086
for dir in "${dirs[@]}"; do
    rm -rf $dir
    echo "Removed $dir"
done
# shellcheck enable=SC2086
```

### File-Level Suppression

Suppress for the entire file — place at top after shebang:

```bash
#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154
# This file sources external env files; SC1091/SC2154 are expected.

source /etc/environment
echo "$EXTERNAL_VAR"
```

### Suppression Best Practices

| Practice | Reason |
|----------|--------|
| Always add a justification comment | Future readers know WHY it's suppressed |
| Suppress the narrowest scope possible | Inline > block > file-level |
| Suppress by specific code, never `disable=all` | Prevents hiding new violations |
| Review suppressions during PR review | Suppressions are debt — revisit periodically |

> [Check] Every `# shellcheck disable=` has a trailing justification comment
> [Check] No `disable=all` anywhere in the codebase

---

## Practical Configuration Examples

### Minimal Strict POSIX `.shellcheckrc`

```ini
shell=sh
enable=all
severity=style
disable=SC2039,SC3043
```

### Minimal Bash Dev `.shellcheckrc`

```ini
shell=bash
enable=style
source-path=SCRIPTDIR
external-sources=true
disable=SC1091,SC2154,SC2034,SC2086
```

### Maximal CI `.shellcheckrc`

```ini
shell=bash
enable=all
severity=style
source-path=SCRIPTDIR
source-path=lib/
source-path=tests/
external-sources=true
disable=SC1091  # Not following external source — sourced at runtime
```

---

## Pre-Commit Hook Integration

### With pre-commit framework

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.10.0    # Pin to latest stable
    hooks:
      - id: shellcheck
        args: ["--severity=style", "--shell=bash"]

  - repo: https://github.com/mvdan/sh
    rev: v3.8.0      # Pin to latest stable
    hooks:
      - id: shfmt
        args: ["-d", "-i", "2", "-ci"]  # -d = diff mode
```

### Manual pre-commit hook

```bash
# .git/hooks/pre-commit — or .githooks/pre-commit with git config core.hooksPath .githooks
#!/usr/bin/env bash
set -euo pipefail

errors=0
while IFS= read -r -d '' file; do
    shellcheck --severity=style "$file" || errors=$((errors + 1))
done < <(find . -name '*.sh' -not -path './.git/*' -print0)

if (( errors > 0 )); then
    echo "Linting failed: $errors file(s) with violations"
    exit 1
fi
```

> [Check] Pre-commit hook installed and executable
> [Check] Hook runs `shellcheck` and `shfmt -d` on staged `.sh` files

---

## Editor Integration

### VS Code

- **ShellCheck**: Extension `timonwong.shellcheck` — real-time linting in the editor
- **shfmt**: Format on save via `foxundermoon.shell-format` extension
- **Installation**:
  ```bash
  code --install-extension timonwong.shellcheck
  code --install-extension foxundermoon.shell-format
  ```

### Vim/Neovim

```vim
" ShellCheck via ALE (Asynchronous Lint Engine)
Plug 'dense-analysis/ale'

" ALE configuration
let g:ale_linters = {'sh': ['shellcheck']}
let g:ale_fixers = {'sh': ['shfmt']}
let g:ale_sh_shellcheck_options = '--severity=style'
let g:ale_sh_shfmt_options = '-i 2 -ci'
```

### Emacs

```elisp
;; Flycheck for ShellCheck
(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode))

;; shfmt via format-all
(use-package format-all
  :ensure t
  :hook (sh-mode . format-all-mode))
```

### ShellCheck in terminal

```bash
# Watch mode with entr (Linux)
find . -name '*.sh' | entr -c shellcheck --severity=style /_

# Using fd + watch
fd -e sh | entr sh -c 'shellcheck --severity=style {} && echo "OK"'
```

> [Check] Editor extension configured with project settings
> [Check] Lint-on-save enabled for `.sh` files

---

## CI/CD Workflows

### GitHub Actions

```yaml
# .github/workflows/lint.yml
name: ShellCheck + shfmt
on:
  push:
    branches: [main]
    paths: ['**/*.sh']
  pull_request:
    paths: ['**/*.sh']

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: ShellCheck
        uses: ludeeus/action-shellcheck@master
        with:
          severity: style
          scandir: './bin:./lib'

      - name: ShellCheck (all files, strict)
        run: |
          shellcheck --version
          find . -name '*.sh' -not -path './.git/*' -print0 \
            | xargs -0 shellcheck --severity=style --shell=bash

      - name: shfmt (check formatting)
        uses: mvdan/shfmt-preview@v3
        with:
          args: '-d -i 2 -ci -ln bash'
```

### GitLab CI

```yaml
# .gitlab-ci.yml
lint:
  stage: test
  image: koalaman/shellcheck:stable
  before_script:
    - apt-get update && apt-get install -y shfmt
  script:
    - shellcheck --version
    - shfmt --version
    - find . -name '*.sh' -not -path './.git/*' -print0 \
      | xargs -0 -P"$(nproc)" -I{} sh -c '
          shellcheck --severity=style --shell=bash "{}" &&
          shfmt -d -i 2 -ci "{}"
        '
  rules:
    - changes:
        paths: ['**/*.sh']
```

### Makefile Integration

```makefile
# Makefile — linting targets

SHELLCHECK := shellcheck
SHELLCHECK_FLAGS := --severity=style --shell=bash
SHFMT_FLAGS := -d -i 2 -ci -ln bash
SCRIPTS := $(shell find . -name '*.sh' -not -path './.git/*')

.PHONY: lint
lint: lint-shellcheck lint-shfmt  ## Run all linters

.PHONY: lint-shellcheck
lint-shellcheck:  ## Run ShellCheck on all .sh files
	$(SHELLCHECK) $(SHELLCHECK_FLAGS) $(SCRIPTS)

.PHONY: lint-shfmt
lint-shfmt:  ## Check formatting of all .sh files
	shfmt $(SHFMT_FLAGS) $(SCRIPTS)

.PHONY: lint-fix
lint-fix:  ## Auto-fix formatting (shfmt -w)
	shfmt -w -i 2 -ci -ln bash $(SCRIPTS)

.PHONY: lint-ci
lint-ci: lint  ## CI alias
```

> [Check] CI workflow runs both `shellcheck` and `shfmt -d`
> [Check] `.gitignore` excludes Git directory from shellcheck scans
> [Check] CI fails on any violation with non-zero exit

---

## Combined ShellCheck + shfmt Workflow

Always run both tools on every `.sh` file. They catch different classes of issues:

```bash
# Single file quick check
shellcheck myscript.sh && shfmt -d myscript.sh

# All scripts in directory
shellcheck *.sh && shfmt -d *.sh

# All scripts
shellcheck --shell=bash *.sh && shfmt -d -ln bash *.sh

# Exit on first failure
shellcheck --shell=bash *.sh || exit 1
shfmt -d -ln bash *.sh || exit 1

# Auto-fix formatting first, then lint
shfmt -w -i 2 -ci *.sh && shellcheck --severity=style *.sh
```

### Indentation Convention

shfmt defaults to 4-space indentation. Most modern Bash projects use 2-space:

```bash
# Apply project convention
shfmt -w -i 2 -ci -ln bash script.sh

# CI check (diff mode — no changes)
shfmt -d -i 2 -ci -ln bash script.sh
```

> [Check] Both ShellCheck and shfmt run on every `.sh` file
> [Check] shfmt run in diff mode (`-d`) in CI; write mode (`-w`) locally
> [Check] Consistent indentation (2 or 4 spaces) enforced project-wide

---

## Performance

Optimize linting for large codebases.

### Parallel Execution with `xargs -P`

```bash
# Check all .sh files in parallel (4 workers)
find . -name '*.sh' -not -path './.git/*' -print0 \
  | xargs -0 -P 4 -I {} shellcheck --severity=style "{}"

# Combined ShellCheck + shfmt in parallel
find . -name '*.sh' -not -path './.git/*' -print0 \
  | xargs -0 -P "$(nproc)" -I{} sh -c '
      shellcheck --severity=style "{}" && shfmt -d -i 2 -ci "{}"
    '
```

### Caching with `git diff`

Only lint changed files:

```bash
# Lint only staged .sh files
while IFS= read -r -d '' file; do
    shellcheck --severity=style "$file" || errors=$((errors + 1))
done < <(git diff --cached --name-only -z -- '*.sh')

# Lint only modified files (unstaged)
while IFS= read -r -d '' file; do
    shellcheck --severity=style "$file" || errors=$((errors + 1))
done < <(git diff --name-only -z -- '*.sh')
```

### Speed Tips

| Technique | Speedup | When to Use |
|-----------|---------|-------------|
| `xargs -P $(nproc)` | 2-8x on multi-core | Large CI runs |
| Lint only changed files | 10-100x | Pre-commit hook |
| Use binary install (not cabal) | 2x | CI setup |
| ShellCheck cached index | 1.5x | Repeated runs on same files |

> [Check] Parallel execution configured for CI pipelines
> [Check] Pre-commit hooks lint only staged/modified files

---

## Output Formats

### GCC-style (default)

```
script.sh: line 42: error: Double quote to prevent globbing. [SC2086]
```

Suitable for tools that parse GCC output (e.g., flycheck, quickfix lists).

### JSON

```bash
shellcheck --format=json script.sh
```

```json
{
  "files": [
    {
      "file": "script.sh",
      "comments": [
        {
          "line": 42,
          "column": 5,
          "endLine": 42,
          "endColumn": 10,
          "level": "warning",
          "code": 2086,
          "message": "Double quote to prevent globbing and word splitting."
        }
      ]
    }
  ]
}
```

Use in automated tooling, SARIF reports, or custom dashboards.

### Quiet

```bash
shellcheck --quiet script.sh
```

Only prints errors, no preamble or summary. Useful in pipelines where only exit codes matter.

### Checkstyle (XML)

```bash
shellcheck --format=checkstyle script.sh > shellcheck-report.xml
```

Integrates with Jenkins, SonarQube, and other tools that consume Checkstyle XML.

### TAP (Test Anything Protocol)

```bash
shellcheck --format=tap script.sh
```

Suitable for test harnesses that consume TAP output.

> [Check] Output format chosen for the consuming tool (GCC for editors, JSON for custom tooling, quiet for CI exit codes)
> [Check] Quiet mode in CI unless post-processing is needed

---

## Common Violation Patterns

### Pattern 1: Unquoted Variable Expansion (SC2086)

**Before** — word splitting and globbing on `$file`:
```bash
#!/bin/bash
for file in $(find /var/log -name "*.log"); do
    rm $file
done
```

**After** — quoted and safe:
```bash
#!/bin/bash
while IFS= read -r -d '' file; do
    rm "$file"
done < <(find /var/log -name "*.log" -print0)
```

---

### Pattern 2: Useless `cat` (SC2002)

**Before** — unnecessary subprocess:
```bash
cat config.txt | grep "server"
```

**After** — direct redirection:
```bash
grep "server" < config.txt
```

---

### Pattern 3: Missing Shebang (SC2148)

**Before** — no shebang, ShellCheck can't determine shell:
```bash
echo "Hello world"
```

**After** — explicit shebang:
```bash
#!/usr/bin/env bash
echo "Hello world"
```

---

### Pattern 4: Unquoted Array Expansion (SC2068)

**Before** — array elements word-split:
```bash
args=(-name "*.log" -mtime +7)
find /var/log "${args}"
```

**After** — proper array expansion:
```bash
args=(-name "*.log" -mtime +7)
find /var/log "${args[@]}"
```

---

### Pattern 5: `$?` Instead of Direct Command (SC2181)

**Before** — fragile exit code check:
```bash
grep "pattern" config.txt
if [ $? -eq 0 ]; then
    echo "Found"
fi
```

**After** — direct command check:
```bash
if grep -q "pattern" config.txt; then
    echo "Found"
fi
```

---

### Pattern 6: `declare -a` Without Initialization (SC2206)

**Before** — implicit word splitting:
```bash
declare -a items
items="one two three"
```

**After** — proper array assignment:
```bash
items=("one" "two" "three")
```

---

### Pattern 7: `[[ ]]` in POSIX Script (SC3010)

**Before** — bashism in `sh` context:
```bash
#!/bin/sh
if [[ "$var" == "value" ]]; then
    echo "match"
fi
```

**After** — POSIX-compatible:
```bash
#!/bin/sh
if [ "$var" = "value" ]; then
    echo "match"
fi
```

---

### Pattern 8: Function Declaration Inconsistency (SC2112/SC2113)

**Before** — mixed styles, missing `function` keyword:
```bash
myfunction () {
    echo "mixed style"
}

function myfunction2 {
    echo "ksh style"
}
```

**After** — consistent POSIX-compatible style:
```bash
myfunction() {
    printf '%s\n' "consistent style"
}

myfunction2() {
    printf '%s\n' "consistent style"
}
```

---

### Pattern 9: `echo` of Variable Content (SC3037, portability)

**Before** — `echo` with flags or variable interpolation:
```bash
echo "$message"
echo -n "$message"
echo "$(date): $status"
```

**After** — use `printf`:
```bash
printf '%s\n' "$message"
printf '%s' "$message"
printf '%s: %s\n' "$(date)" "$status"
```

---

### Pattern 10: Missing `local` in Functions (unassigned — exposed global)

**Before** — function leaks variables to global scope:
```bash
process_file() {
    count=0
    for line in "$@"; do
        count=$((count + 1))
    done
    echo "$count"
}
```

**After** — scoped with `local`:
```bash
process_file() {
    local count=0 line
    for line in "$@"; do
        count=$((count + 1))
    done
    printf '%s\n' "$count"
}
```

---

## Verification

- [Check] ShellCheck binary installed and in PATH
- [Check] `shellcheck --version` reports target version
- [Check] `.shellcheckrc` present in project root
- [Check] `shell=bash` or `shell=sh` set to match project shebangs
- [Check] All `.sh` files pass `shellcheck --severity=style` without errors
- [Check] All `.sh` files pass `shfmt -d -i 2 -ci -ln bash` without diff
- [Check] CI pipeline runs both linters on all `.sh` files
- [Check] Pre-commit hook installed for staged `.sh` files
- [Check] No `disable=all` or unreviewed suppressions in the codebase
- [Check] Before-and-after patterns reviewed against actual project violations
