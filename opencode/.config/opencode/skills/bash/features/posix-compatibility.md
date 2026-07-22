# POSIX Compatibility

POSIX sh (`#!/bin/sh`) portability guide for Bash developers. Covers every Bash-ism that breaks under dash, ash, yash, posh, and BusyBox sh, with before/after diffs and ShellCheck references.

---

## Shebang

| Context | Shebang | Shell |
|---------|---------|-------|
| POSIX target | `#!/bin/sh` | System default POSIX shell |
| Bash target | `#!/usr/bin/env bash` | Portable Bash discovery via PATH |
| Hybrid (needs Bash) | `#!/bin/sh` + `[ -z "$BASH_VERSION" ] && exec bash "$0"` | Bail-out re-exec |

**Rule**: If the script uses no Bash-isms, use `#!/bin/sh`. If the script must use Bash features, use `#!/usr/bin/env bash` and document the dependency. Never use `#!/bin/bash` (hardcoded path is not portable).

[Check] shebang choice matches the actual shell features used in the script

---

## Strict Mode Diffs

Bash strict mode is not fully portable. Each component has a POSIX-sh equivalent or must be dropped.

### set options

| Bash | POSIX sh | Notes |
|------|----------|-------|
| `set -Eeuo pipefail` | `set -eu` | `-E` (errtrace), `-o pipefail` are Bash-only |
| `shopt -s inherit_errexit` | N/A | No equivalent |
| `trap ... ERR` | N/A | No `ERR` pseudo-signal in POSIX |
| `set -o noglob` / `set -f` | `set -f` | POSIX: `set -f` (same as `noglob`) |

```bash
# Bash — full strict mode
#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "ERR at line $LINENO"' ERR
shopt -s inherit_errexit

# POSIX sh — reduced strict mode
#!/bin/sh
set -eu
```

### Error reporting

Bash provides `$LINENO` and `$FUNCNAME` for error context. POSIX sh has only `$LINENO` (not guaranteed by all implementations):

```bash
# Bash — trap with context
trap 'echo "ERROR: $BASH_SOURCE:$LINENO in $FUNCNAME"' ERR

# POSIX sh — trap with line number only
trap 'echo "ERROR at line $LINENO"' EXIT
```

[Check] script uses `set -eu` not `set -Eeuo pipefail` when `#!/bin/sh`
[Check] no `ERR` trap in POSIX sh scripts
[Check] no `inherit_errexit` (shopt is Bash-only)

---

## Conditional Diffs

### test `[ ]` vs `[[ ]]`

`[[ ]]` is a Bash extension. POSIX sh uses `[ ]` (the `test` builtin).

```bash
# Bash — double brackets
if [[ "$var" == "value" ]]; then
if [[ -n "$var" && -f "$path" ]]; then
if [[ ! -z "$var" ]]; then

# POSIX sh — single brackets
if [ "$var" = "value" ]; then
if [ -n "$var" ] && [ -f "$path" ]; then
if [ -n "$var" ]; then
```

### String comparison: `==` inside `[ ]`

POSIX `[ ]` uses `=` for string equality, not `==`. Some shells accept `==` but it is not portable.

```bash
# Bash
[ "$x" == "yes" ]

# POSIX sh
[ "$x" = "yes" ]
```

### Regex matching: `=~`

The `=~` operator inside `[[ ]]` is Bash-only.

```bash
# Bash
if [[ "$email" =~ ^[a-z]+@[a-z]+\.[a-z]+$ ]]; then

# POSIX sh — use case statement
case "$email" in
    *@*.*)
        ;;
esac
```

For more complex regex, use `grep` or `sed`:

```bash
# POSIX sh — grep-based regex matching
if printf '%s\n' "$email" | grep -qE '^[a-z]+@[a-z]+\.[a-z]+$'; then
    ...
fi
```

[Check] all conditionals use `[ ]` not `[[ ]]`
[Check] string comparison inside `[ ]` uses `=` not `==`
[Check] regex matching uses `case` or external tools, not `=~`

---

## No Arrays

Bash indexed arrays are not available in POSIX sh.

```bash
# Bash — indexed array
fruits=("apple" "banana" "cherry")
echo "${fruits[1]}"
for f in "${fruits[@]}"; do

# POSIX sh — positional params or IFS splitting
# Option 1: Positional parameters
set -- apple banana cherry
# Access by position using shift
for f in "$@"; do
    echo "$f"
done

# Option 2: Delimited string with IFS
fruits="apple banana cherry"
IFS=' '
for f in $fruits; do
    echo "$f"
done
```

### Counting elements

```bash
# Bash
count=${#fruits[@]}

# POSIX sh
count=$#
# or
count=$(printf '%s\n' "$fruits" | wc -w)
```

[Check] no indexed array syntax `var=(...)` or `${var[idx]}` in POSIX sh scripts
[Check] loop over items uses `for x in "$@"` or IFS-split strings

---

## No Associative Arrays

Bash 4+ associative arrays (`declare -A`) have no POSIX sh equivalent.

```bash
# Bash
declare -A user
user[name]="alice"
user[role]="admin"
echo "${user[role]}"

# POSIX sh — separate variables or prefix convention
user_name="alice"
user_role="admin"
echo "$user_role"

# Or: newline-delimited key=value pairs
users="name=alice
role=admin"
echo "$users" | grep '^role=' | cut -d= -f2
```

[Check] no `declare -A` or `typeset -A` in POSIX sh scripts

---

## No Process Substitution

`<(cmd)` and `>(cmd)` are Bash-only. Use temp files or pipes.

```bash
# Bash
diff <(sort file1) <(sort file2)

# POSIX sh — temp files
tmp1=$(mktemp)
tmp2=$(mktemp)
sort file1 > "$tmp1"
sort file2 > "$tmp2"
diff "$tmp1" "$tmp2"
rm -f "$tmp1" "$tmp2"

# POSIX sh — pipe (when only one substitution)
sort file1 | diff - file2
```

```bash
# Bash — while-read with process substitution
while IFS= read -r line; do
    process "$line"
done < <(command)

# POSIX sh — pipe into the loop
command | while IFS= read -r line; do
    process "$line"
done
```

[Check] no `<(...)` or `>(...)` syntax in POSIX sh scripts
[Check] temp files are cleaned up with `rm -f` or trap handler

---

## No `local` Keyword

`local` is not in POSIX (though supported by dash, ash, busybox sh as an extension — but NOT posh).

```bash
# Bash
myfunc() {
    local var="value"
    echo "$var"
}

# POSIX sh — subshell scoping
myfunc() (
    var="value"
    echo "$var"
)

# POSIX sh — unique naming convention
myfunc() {
    _myfunc_var="value"
    echo "$_myfunc_var"
}
```

Subshell scoping (`( )` instead of `{ }`) is the safest portable pattern — variables inside do not leak. However, subshells cannot modify parent scope variables, so use unique naming when mutation is needed.

[Check] no `local` keyword in POSIX sh when targeting posh
[Check] subshell `( )` scoping or unique var names used as alternatives

---

## No `+=` Operator

Bash's `+=` is not POSIX.

```bash
# Bash
msg="hello"
msg+=" world"

# POSIX sh — string concatenation
msg="hello"
msg="${msg} world"
```

[Check] string concatenation uses `${var}suffix` not `var+=suffix`

---

## No `$FUNCNAME`, `$BASH_SOURCE`, `$BASH_VERSINFO`

These variables are Bash-only. `$LINENO` is POSIX (though not guaranteed in all historical shells).

```bash
# Bash
log "error" "$FUNCNAME" "$BASH_SOURCE:$LINENO"

# POSIX sh
log "error" "${0}:${LINENO}"
```

[Check] no `$FUNCNAME` (use `${0}`)
[Check] no `$BASH_SOURCE` (use `$0`)
[Check] no `$BASH_VERSINFO` (feature-test with `$BASH_VERSION` or drop)

---

## No `printf -v`, `read -a`, `read -t`, `read -d`

These `read` and `printf` flags are Bash extensions.

### `printf -v` (assign to variable)

```bash
# Bash
printf -v myvar "Hello %s" "World"

# POSIX sh — command substitution
myvar=$(printf "Hello %s" "World")
```

### `read -a` (read into array)

```bash
# Bash
read -a parts <<< "a:b:c"

# POSIX sh — IFS splitting with set
set -- a b c  # or pipe through IFS
```

### `read -t` (timeout)

```bash
# Bash
read -t 5 -p "Continue? " answer

# POSIX sh — no direct equivalent; use timeout(1) if available
if command -v timeout >/dev/null 2>&1; then
    answer=$(timeout 5 sh -c 'printf "Continue? " >&2; read input; printf "%s" "$input"')
fi
```

### `read -d` (delimiter)

```bash
# Bash — read until semicolon
read -d ';' field

# POSIX sh — use IFS or sed
field=$(printf '%s\n' "$data" | sed 's/;.*//')
```

[Check] no `printf -v` (use `$(...)` assignment)
[Check] no `read -a` (use positional params with `set --`)
[Check] no `read -t` (use `timeout` or drop)
[Check] no `read -d` (use `sed` or `cut`)

---

## No `shopt` or `extglob`

`shopt` and `extglob` are Bash extensions.

```bash
# Bash
shopt -s extglob
case "$file" in
    *.@(md|txt|rst)) echo "doc" ;;
esac

# POSIX sh — use case with explicit patterns
case "$file" in
    *.md|*.txt|*.rst) echo "doc" ;;
esac
```

[Check] no `shopt` builtin usage
[Check] glob patterns use explicit `|` in case branches, not `@(...)` pattern lists

---

## Function Definition

POSIX sh only allows `fname() { }`. The `function` keyword and `() { }` combined form are Bash-only.

```bash
# Bash — allowed but not POSIX
function myfunc() {
    echo "$@"
}

# Bash — also valid POSIX form
myfunc() {
    echo "$@"
}

# POSIX sh — must omit `function` keyword
myfunc() {
    echo "$@"
}
```

[Check] function definitions omit the `function` keyword

---

## `$()` is POSIX, Backticks are Legacy

Both `$(cmd)` and `` `cmd` `` are POSIX, but `$(cmd)` is preferred for nesting and readability.

```bash
# Legacy — still POSIX but hard to nest
files=`ls -la`

# Preferred POSIX — nestable, clearer
files=$(ls -la)
nested=$(printf "%s" "$(dirname "$(pwd)")")
```

[Check] scripts use `$(cmd)` not `` `cmd` `` (ShellCheck SC2006)

---

## `printf` over `echo`

`echo` behavior varies across shells (`-n`, `-e`, escape sequences). `printf` is POSIX and consistent.

```bash
# Non-portable — behavior depends on echo implementation
echo "Hello"
echo -n "No newline"
echo "\tTab"      # some echo interpret escapes, others don't

# Portable POSIX
printf '%s\n' "Hello"
printf '%s' "No newline"
printf '\t%s\n' "Tab"
```

`printf '%s\n' "$var"` is always safe. Use `printf '%s' "$var"` where no trailing newline is desired.

[Check] `printf` is used instead of `echo` for all output (ShellCheck SC3016, SC3030)

---

## `command -v` is POSIX, `type` is not

`command -v` is defined by POSIX. `type` and `which` are not.

```bash
# Non-portable — `type` not in POSIX, `which` is external
type mycommand
which mycommand

# Portable POSIX
if command -v mycommand >/dev/null 2>&1; then
    echo "mycommand is available"
fi
```

[Check] command existence checks use `command -v` (ShellCheck SC3055)

---

## Testing Across POSIX Shell Flavors

When targeting POSIX sh, test across these implementations:

| Shell | Package | Notes |
|-------|---------|-------|
| **dash** | Debian/Ubuntu `/bin/sh` | Most common POSIX sh target |
| **ash** | BusyBox | Embedded/Linux default |
| **yash** | Yet Another SHell | Strictest POSIX compliance |
| **posh** | pdksh derivative | Rejects `local`, the strictest |
| **BusyBox sh** | `busybox sh` | Multi-call binary, common in containers |

### Test Matrix

```bash
for shell in dash ash yash posh busybox sh; do
    if command -v "$shell" >/dev/null 2>&1; then
        echo "=== Testing with $shell ==="
        "$shell" -n script.sh && "$shell" script.sh
    fi
done
```

[Check] script is tested with `dash -n script.sh` (syntax check)
[Check] script is tested on at least one strict POSIX shell (yash or posh)

---

## ShellCheck POSIX Compliance Flags (SC3010–SC3057)

ShellCheck flags Bash-isms when `shell=sh` is set. All flags in the SC3010–SC3057 range are POSIX compliance violations.

| Flag | Description |
|------|-------------|
| SC3010 | `[[ ]]` used when not POSIX |
| SC3011 | `-nt` / `-ot` used with `[ ]` instead of `[[ ]]` |
| SC3012 | `==` inside `[ ]` (use `=` instead) |
| SC3013 | `-ef` used in `[ ]` |
| SC3014 | `=~` regex operator (Bash-only) |
| SC3015 | `[[ ]]` with pattern matching |
| SC3016 | `echo` with escape sequences (use `printf`) |
| SC3017 | `echo -e` (use `printf`) |
| SC3018 | uppercase function name |
| SC3019 | `let` is not POSIX (use `$(( ))`) |
| SC3020 | `select` is not POSIX |
| SC3021 | `until` with `[[ ]]` |
| SC3022 | `(( ))` arithmetic in `[[ ]]` |
| SC3023 | `[[ ]]` with arithmetic |
| SC3024 | `function` keyword |
| SC3025 | `declare` / `typeset` not POSIX |
| SC3026 | `export -f` not POSIX |
| SC3027 | `local` not POSIX |
| SC3028 | `$BASH_SOURCE` / `$BASH_LINENO` not POSIX |
| SC3029 | `$FUNCNAME` not POSIX |
| SC3030 | `echo` with `-n` (use `printf`) |
| SC3031 | `printf` without format string |
| SC3032 | `printf -v` not POSIX |
| SC3033 | `read -a` not POSIX |
| SC3034 | `read -t` not POSIX |
| SC3035 | `read -d` not POSIX |
| SC3036 | `read -p` not POSIX (use `printf` prompt + `read`) |
| SC3037 | `read -s` not POSIX |
| SC3038 | `read -n` not POSIX |
| SC3039 | `read -e` not POSIX |
| SC3040 | `shopt` not POSIX |
| SC3041 | `extglob` not POSIX |
| SC3042 | `+=` not POSIX |
| SC3043 | `${!var}` indirect reference not POSIX |
| SC3044 | `${var^}` / `${var,}` case modification not POSIX |
| SC3045 | `${var#pattern}` / `${var%pattern}` with extglob not POSIX |
| SC3046 | `${var/old/new}` parameter substitution limited in POSIX |
| SC3047 | process substitution `<(...)` / `>(...)` not POSIX |
| SC3048 | arrays `var=(...)` not POSIX |
| SC3049 | associative arrays `declare -A` not POSIX |
| SC3050 | `${!arr[@]}` key enumeration not POSIX |
| SC3051 | `${#arr[@]}` array length not POSIX |
| SC3052 | `source` not POSIX (use `.`) |
| SC3053 | `type` not POSIX (use `command -v`) |
| SC3054 | `caller` not POSIX |
| SC3055 | `command -v` preferred over `type` |
| SC3056 | `$PIPESTATUS` not POSIX |
| SC3057 | `$EPOCHSECONDS` / `$EPOCHREALTIME` not POSIX |

### ShellCheck Configuration

Add to `.shellcheckrc` when targeting POSIX sh:

```properties
# .shellcheckrc — enforce POSIX sh compliance
shell=sh
disable=SC2039,SC3043,SC3056
# SC2039: In POSIX sh, 'local' is not supported (warn ok for dash/ash)
# SC3043: Some POSIX vars are Bash-only — suppress false positives
# SC3056: $PIPESTATUS — suppress if handling pipe errors differently
```

Or per-script override:

```bash
# shellcheck shell=sh
```

[Check] ShellCheck is run with `shell=sh` for POSIX-targeting scripts
[Check] ShellCheck reports zero SC3010–SC3057 violations

---

## Migration Checklist: Bash to POSIX sh

Use this checklist when porting a Bash script to POSIX sh:

### Shebang & Strict Mode

- [ ] `#!/usr/bin/env bash` → `#!/bin/sh`
- [ ] `set -Eeuo pipefail` → `set -eu`
- [ ] Remove `trap ... ERR`
- [ ] Remove `shopt -s inherit_errexit`
- [ ] Remove `set -o pipefail` — handle pipe errors with `${PIPESTATUS[0]}` alternatives or drop

### Conditionals

- [ ] `[[ expr ]]` → `[ expr ]`
- [ ] `==` inside `[ ]` → `=` inside `[ ]`
- [ ] `=~` regex pattern → `case` statement or `grep -qE`
- [ ] `&&` / `||` inside `[[ ]]` → separate `[ ]` connected with `&&` / `||`
- [ ] Pattern matching in `[[ $var == pattern ]]` → `case $var in pattern)`

### Data Structures

- [ ] Indexed arrays `arr=(...)` → `set -- ...` or IFS-split string
- [ ] Array access `${arr[i]}` → positional param `$i` or `cut` on IFS string
- [ ] Array length `${#arr[@]}` → `$#` or `wc -w`
- [ ] Associative arrays `declare -A` → separate variables `var_key=value`
- [ ] `${!arr[@]}` key enumeration → explicit list

### Process Substitution & Subshells

- [ ] `<(cmd)` → temp file or pipe
- [ ] `>(cmd)` → temp file
- [ ] `while read ... done < <(cmd)` → `cmd | while read ... done`

### Variables & Scope

- [ ] `local var` → subshell `( )` or unique name `_func_var`
- [ ] `var+=suffix` → `var="${var}suffix"`
- [ ] `${var^}` / `${var,,}` → `tr` or `awk`
- [ ] `${!indirect}` → `eval "printf '%s\n' \"\${$indirect}\""` (with caution)
- [ ] `$FUNCNAME` → `${0}` or hardcoded
- [ ] `$BASH_SOURCE` → `$0`
- [ ] `$BASH_VERSINFO` → drop or feature-test

### Builtins & Syntax

- [ ] `function fname() { }` → `fname() { }`
- [ ] `shopt` → remove
- [ ] `extglob` patterns → explicit case alternatives
- [ ] `printf -v var` → `var=$(printf ...)`
- [ ] `read -a` → `set --` with IFS
- [ ] `read -t` → `timeout` command if available, or drop
- [ ] `read -d` → `cut` or `sed`
- [ ] `(( i++ ))` → `i=$((i + 1))`
- [ ] `let i++` → `i=$((i + 1))`
- [ ] `source file` → `. file`
- [ ] `type cmd` → `command -v cmd`
- [ ] `` `cmd` `` → `$(cmd)`
- [ ] `echo` → `printf '%s\n'`
- [ ] `$LINENO` — keep (POSIX), verify dash/ash support

### Testing

- [ ] Run ShellCheck with `shell=sh` — zero SC3010–SC3057 violations
- [ ] Syntax-check: `dash -n script.sh`
- [ ] Syntax-check: `busybox sh -n script.sh`
- [ ] Run full test suite under dash
- [ ] Run full test suite under BusyBox sh
- [ ] (Optional) Run under yash and posh for strictest validation

### Verification Markers

```bash
# Each migration step verification:
[Check] shebang is #!/bin/sh
[Check] set options are POSIX-compatible (set -eu)
[Check] no [[ ]] conditionals remain
[Check] no arrays remain
[Check] no process substitution remains
[Check] no local keyword remains
[Check] no += operator remains
[Check] no Bash-only variables referenced
[Check] function definitions use fname() without function keyword
[Check] printf used instead of echo
[Check] command -v used instead of type
[Check] ShellCheck shell=sh passes with zero POSIX violations
```

---

## Verification Markers

Execute these verification steps after loading this feature:

```bash
# Verify feature file content
[Check] posix-compatibility.md covers all POSIX compatibility domains:
  - Shebang conventions
  - Strict mode diffs
  - Conditional diffs ([ ] vs [[ ]])
  - Arrays and associative arrays
  - Process substitution
  - local keyword
  - += operator
  - Bash-only variables ($FUNCNAME, $BASH_SOURCE, $BASH_VERSINFO)
  - printf -v, read -a, read -t, read -d
  - shopt and extglob
  - Function definition syntax
  - $() vs backticks
  - printf vs echo
  - command -v vs type
  - POSIX shell testing targets
  - Migration checklist
  - ShellCheck flags SC3010-SC3057

[Check] each diff section contains Bash example followed by POSIX-compatible equivalent
[Check] verification markers are included at the end of the feature file
