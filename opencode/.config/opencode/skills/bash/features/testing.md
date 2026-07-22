# Testing (Bats)

Comprehensive guide to testing Bash scripts with the Bash Automated Testing System (Bats). Covers fundamentals, assertions, mocking, fixtures, CI/CD integration, and advanced patterns.

## Bats Fundamentals

### Installation

Bats is a TAP-compliant testing framework for Bash. Install via package manager:

```bash
# Arch Linux
sudo pacman -S bats bats-support bats-assert bats-file

# Debian/Ubuntu
sudo apt install bats

# macOS (Homebrew)
brew install bats-core

# From source (any platform)
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

Bats ecosystem consists of several optional libraries:

| Library | Purpose | Package |
|---------|---------|---------|
| `bats-core` | Core test runner | `bats` |
| `bats-support` | Helper library support | `bats-support` |
| `bats-assert` | Assertion helpers (`assert_success`, `assert_output`) | `bats-assert` |
| `bats-file` | File assertions (`assert_file_exist`) | `bats-file` |

### TAP Output Format

Bats produces TAP (Test Anything Protocol) output, compatible with most CI systems:

```bash
# Run tests and see raw TAP output
bats tests/
# 1..4
# ok 1 greeting prints hello
# ok 2 greeting handles empty name
# not ok 3 greeting fails without argument
# ok 4 greeting trims whitespace
```

Use `bats --formatter tap13` for TAP 13 with diagnostics, or `bats --formatter pretty` (default) for human-readable output.

### Quick Start

```bash
#!/usr/bin/env bats

# A minimal test file
@test "true returns 0" {
    run true
    [ "$status" -eq 0 ]
}

@test "false returns 1" {
    run false
    [ "$status" -eq 1 ]
}
```

Run with `bats path/to/test.bats`.

## Test File Organization

### Naming Conventions

- **Test files**: `*.bats` extension (preferred) or `*.sh` in a `tests/` directory
- **Helper files**: `test_helper.bash` — loaded via `load` helper
- **Fixture data**: Store in `tests/fixtures/` parallel to test files

### Directory Layout

```
project/
├── bin/
│   └── my-script          # script under test
├── lib/
│   └── my-lib.sh          # sourced functions
├── tests/
│   ├── my-script.bats     # test file
│   ├── my-lib.bats        # tests for lib functions
│   ├── test_helper.bash   # shared helpers
│   └── fixtures/
│       ├── input.csv
│       └── expected-output.txt
└── Makefile               # test targets
```

### Loading Test Helpers

```bash
# tests/test_helper.bash — shared setup/helpers

setup() {
    # Common setup logic runs before every test
    export TEST_MODE=1
}

assert_file_mode() {
    local file="$1" expected="$2" actual
    actual=$(stat -c "%a" "$file")
    [ "$actual" = "$expected" ]
}
```

```bash
# tests/my-script.bats — using the helper

load test_helper

@test "script creates file with correct permissions" {
    run my-script create-file /tmp/test.txt
    assert_file_mode "/tmp/test.txt" "644"
    rm -f /tmp/test.txt
}
```

### Inline vs Library Tests

Separate tests for standalone scripts and sourced libraries:

```bash
# tests/my-script.bats — tests the executable entry point
@test "my-script --help prints usage" {
    run my-script --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^Usage: ]]
}

# tests/lib/my-lib.bats — tests library functions directly
load ../lib/my-lib.sh

@test "sanitize_filename removes special chars" {
    run sanitize_filename "hello world/fn.txt"
    [ "$output" = "hello_worldfn.txt" ]
}
```

## Basic Test Structure

### The `@test` Block

Every test is a `@test` block with a name and body. Bats treats the body as a Bash function:

```bash
@test "describe the behavior under test" {
    # Arrange — set up test conditions
    local input="hello"

    # Act — invoke the code under test
    run my_function "$input"

    # Assert — verify results
    [ "$status" -eq 0 ]
    [ "$output" = "processed: hello" ]
}
```

### The `run` Command

`run` executes a command, capturing its stdout, stderr, and exit code:

```bash
@test "run captures exit code and output" {
    run echo "hello world"
    echo "Exit code: $status"    # 0
    echo "Output: $output"       # "hello world"

    run ls /nonexistent
    echo "Exit code: $status"    # 1 or 2
}
```

`run` populates three special variables:

| Variable | Content | Example |
|----------|---------|---------|
| `$status` | Exit code of the command | `0`, `1`, `127` |
| `$output` | Combined stdout and stderr (one line) | `"hello world"` |
| `$lines` | Array of output lines | `("line1" "line2")` |

### `$status` — Exit Code Verification

```bash
@test "status assertions" {
    run true
    [ "$status" -eq 0 ]

    run false
    [ "$status" -ne 0 ]

    run bash -c 'exit 42'
    [ "$status" -eq 42 ]

    run nonexistent-command
    [ "$status" -eq 127 ]  # command not found
}
```

### `$output` — Full Output Verification

```bash
@test "output assertions" {
    run echo "hello world"
    [ "$output" = "hello world" ]

    [ -n "$output" ]         # output is non-empty
    [ -z "$output" ] && echo "empty output"
}
```

### `$lines` — Multi-Line Output

```bash
@test "lines array for multi-line output" {
    run printf "one\ntwo\nthree\n"

    [ "${#lines[@]}" -eq 3 ]    # line count
    [ "${lines[0]}" = "one" ]
    [ "${lines[1]}" = "two" ]
    [ "${lines[2]}" = "three" ]
}
```

## Assertion Patterns

### Exit Code Assertions

```bash
@test "exit code patterns" {
    run my-script

    # Basic
    [ "$status" -eq 0 ]
    [ "$status" -ne 0 ]

    # Using bats-assert (recommended for readability)
    assert_success
    assert_failure
    assert_failure 42  # specific exit code
}
```

### String Matching in Output

```bash
@test "string matching patterns" {
    run echo "error: file not found: /tmp/config.yml"

    # Exact match
    [ "$output" = "error: file not found: /tmp/config.yml" ]

    # Substring match (double brackets)
    [[ "$output" == *"file not found"* ]]

    # Partial match using grep
    echo "$output" | grep -q "file not found"

    # bats-assert style (requires bats-assert)
    assert_output "error: file not found: /tmp/config.yml"
    assert_output --partial "file not found"
}
```

### Regex Matching in Output

```bash
@test "regex matching" {
    run echo "processed 42 records in 1.23s"

    # Bash regex (double brackets)
    [[ "$output" =~ processed\ [0-9]+\ records ]]

    # grep -E with bash regex
    echo "$output" | grep -qE "processed [0-9]+ records"

    # bats-assert style
    assert_output --regexp "processed [0-9]+ records in [0-9]+\.[0-9]+s"
}
```

### Multi-Line Output Assertions

```bash
@test "multi-line output assertions" {
    run printf "name: alice\nrole: admin\nemail: alice@example.com\n"

    # Verify specific line
    [ "${lines[0]}" = "name: alice" ]
    [ "${lines[1]}" = "role: admin" ]

    # Verify line count
    [ "${#lines[@]}" -eq 3 ]

    # Iterate over lines
    local found=0
    for line in "${lines[@]}"; do
        if [[ "$line" == *"alice"* ]]; then
            found=1
            break
        fi
    done
    [ "$found" -eq 1 ]
}
```

### File Assertions

Using `bats-file` or shell built-ins:

```bash
@test "file assertions with shell built-ins" {
    local file="/tmp/test-output.txt"

    # Existence
    [ -f "$file" ]
    [ -d "/tmp" ]
    [ -e "$file" ]

    # Content
    [ -s "$file" ]            # non-empty
    [ ! -s "$file" ]          # empty

    # Permissions
    [ -r "$file" ]
    [ -w "$file" ]
    [ -x "$file" ]

    # Compare content
    run diff expected.txt "$file"
    [ "$status" -eq 0 ]
}

@test "file assertions with bats-file" {
    load '/usr/lib/bats-file/load.bash'

    assert_file_exist "/etc/passwd"
    assert_file_not_exist "/nonexistent"
    assert_file_owner "root" "/etc/passwd"
    assert_file_mode "/etc/passwd" "644"
    assert_empty "$(mktemp)"
    assert_not_empty "/etc/passwd"
}
```

## Setup and Teardown

### Per-Test Setup/Teardown

Bash functions called before/after every `@test` block:

```bash
setup() {
    # Runs before each test
    export TMPDIR=$(mktemp -d)
    cd "$TMPDIR" || exit 1
}

teardown() {
    # Runs after each test (even on failure)
    rm -rf "$TMPDIR"
}

@test "uses setup temp directory" {
    run pwd
    [[ "$output" == *"/tmp/tmp."* ]]
}

@test "cleanup happens between tests" {
    # TMPDIR is fresh — previous test's files are gone
    [ -d "$TMPDIR" ]
}
```

### Per-File Setup/Teardown

`setup_file` and `teardown_file` run once per test file (Bats 1.7+):

```bash
setup_file() {
    # Run once before all tests in this file
    export SHARED_CACHE=$(mktemp -d)
    echo "fixture data" > "$SHARED_CACHE/fixture.txt"
}

teardown_file() {
    # Run once after all tests in this file
    rm -rf "$SHARED_CACHE"
}

@test "first test uses shared fixture" {
    run cat "$SHARED_CACHE/fixture.txt"
    [ "$output" = "fixture data" ]
}

@test "second test same fixture" {
    [ -f "$SHARED_CACHE/fixture.txt" ]
}
```

**Caution:** `setup_file` and `teardown_file` run in a sub-shell. Variables must be exported or written to files to be visible in tests.

### Shared Fixtures Across Files

Use a `bats_setup` directory or environment variable:

```bash
# tests/test_helper.bash

export BATS_TEST_FIXTURES="${BATS_TEST_FIXTURES:-$(mktemp -d)}"

setup() {
    # Per-test setup
    export TEST_TEMP=$(mktemp -d "${BATS_TEST_FIXTURES}/test.XXXXXX")
}

teardown() {
    rm -rf "$TEST_TEMP"
}

# Register cleanup once via trap (runs on test suite exit)
if [[ -z "$_FIXTURE_CLEANUP_REGISTERED" ]]; then
    trap 'rm -rf "$BATS_TEST_FIXTURES"' EXIT
    _FIXTURE_CLEANUP_REGISTERED=1
fi
```

### Skipping Cleanup on Failure (Debugging)

```bash
teardown() {
    # Keep temp dir for debugging if test failed
    if [[ -n "$BATS_TEST_DID_NOT_PASS" ]]; then
        echo "Test failed — preserving $TEST_TEMP" >&3
        return 0
    fi
    rm -rf "$TEST_TEMP"
}
```

`>&3` writes to the Bats TAP output stream so the message appears in test output.

## Mocking and Stubbing

### Function Mocking with `export -f`

Override functions in child processes by exporting a mock:

```bash
# Script under test uses `curl`
@test "mock curl with export -f" {
    curl() {
        echo "200 OK"
        return 0
    }
    export -f curl

    run my-script-that-uses-curl
    [ "$status" -eq 0 ]
    [[ "$output" == *"200 OK"* ]]
}
```

### Command Stubs with PATH Manipulation

Create a stub executable in a temporary directory prepended to `PATH`:

```bash
setup() {
    export BATS_TEST_TMP=$(mktemp -d)
    export PATH="$BATS_TEST_TMP:$PATH"
}

teardown() {
    rm -rf "$BATS_TEST_TMP"
}

@test "stub commands via PATH" {
    # Create stub
    cat > "$BATS_TEST_TMP/git" << 'STUB'
#!/bin/bash
echo "mocked git called with: $*"
exit 0
STUB
    chmod +x "$BATS_TEST_TMP/git"

    run my-script-that-runs-git
    [ "$status" -eq 0 ]
    [[ "$output" == *"mocked git called"* ]]
}
```

### Conditional Mock Output

```bash
@test "stub with conditional output" {
    cat > "$BATS_TEST_TMP/git" << 'STUB'
#!/bin/bash
case "$1" in
    rev-parse) echo "abc123def";;
    log)       echo "commit 1\ncommit 2";;
    status)    echo "clean";;
    *)         echo "unknown git subcommand: $1"; exit 1;;
esac
STUB
    chmod +x "$BATS_TEST_TMP/git"

    run my-script
    [ "$status" -eq 0 ]
}
```

### Call-Count Tracking Mocks

```bash
@test "mock with call count tracking" {
    local mock_file="$BATS_TEST_TMP/git_calls"
    echo 0 > "$mock_file"

    cat > "$BATS_TEST_TMP/git" << 'STUB'
#!/bin/bash
calls=$(cat "$BATS_TEST_TMP/git_calls")
echo $((calls + 1)) > "$BATS_TEST_TMP/git_calls"
echo "mocked git: $*"
STUB
    chmod +x "$BATS_TEST_TMP/git"

    run my-script

    local total_calls
    total_calls=$(< "$BATS_TEST_TMP/git_calls")
    [ "$total_calls" -eq 2 ]  # script calls git twice
}
```

### Environment Variable Stubbing

```bash
@test "environment variable stubbing" {
    # Override env vars used by the script
    export HOME="$BATS_TEST_TMP"
    export PATH="/stub-bin:$PATH"

    # Unset a variable the script checks
    unset DISPLAY

    run my-script
    [ "$status" -eq 0 ]
}

@test "restore env vars after test" {
    # Changes to environment in one test do NOT leak to the next
    # because Bats runs each test in a sub-process
    export CUSTOM_VAR="test-value"
    run bash -c 'echo "$CUSTOM_VAR"'
    [ "$output" = "test-value" ]
}
```

## Fixture Management

### Static Fixture Files

Store fixture files in `tests/fixtures/`:

```bash
setup() {
    export FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"
}

@test "process fixture file" {
    run my-script process "$FIXTURES_DIR/input.csv"
    [ "$status" -eq 0 ]
    diff "$FIXTURES_DIR/expected-output.txt" <(echo "$output")
}
```

### Dynamic Fixture Generation

```bash
@test "generate fixture dynamically" {
    local fixture
    fixture=$(mktemp)

    # Write fixture content
    printf "line1\nline2\nline3\n" > "$fixture"

    run my-script < "$fixture"
    [ "$status" -eq 0 ]

    rm -f "$fixture"
}
```

### Large Fixture Generation (Performance)

```bash
@test "generate large fixture efficiently" {
    local fixture
    fixture=$(mktemp)

    # Generate 1000 lines without a loop (fast)
    printf 'data %s\n' {1..1000} > "$fixture"

    run wc -l < "$fixture"
    [ "${output// /}" -eq 1000 ]

    rm -f "$fixture"
}
```

### Work Directory Patterns

Create a dedicated temp directory per test:

```bash
setup() {
    export TEST_DIR=$(mktemp -d)
    # Change into the temp directory for the test
    cd "$TEST_DIR" || exit 1
}

teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "script operates in temp directory" {
    run touch "output.txt"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/output.txt" ]
}

@test "previous test files are gone" {
    # Each test gets a fresh TEST_DIR
    run ls -A "$TEST_DIR"
    [ "$output" = "" ]
    [ "${#lines[@]}" -eq 0 ]
}
```

## Error Condition Testing

### Missing Files

```bash
@test "fails on missing input file" {
    run my-script --input "/nonexistent/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
    [[ "$output" == *"/nonexistent/path"* ]]
}

@test "fails on missing config file" {
    run my-script --config "/tmp/missing-config.yml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"error"* ]] || [[ "$output" == *"Error"* ]]
}
```

### Invalid Input

```bash
@test "rejects invalid input format" {
    run my-script --format invalid
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid"* ]]
    [[ "$output" == *"format"* ]]
}

@test "handles empty input" {
    run my-script < /dev/null
    [ "$status" -eq 0 ]
    [ -z "$output" ] || [ "$output" = "no input" ]
}

@test "rejects negative timeout" {
    run my-script --timeout -1
    [ "$status" -eq 2 ]
    [[ "$output" == *"positive"* ]]
}

@test "rejects malformed JSON input" {
    run my-script --json <<< '{bad json'
    [ "$status" -eq 3 ]
    [[ "$output" == *"parse"* ]] || [[ "$output" == *"invalid"* ]]
}
```

### Permission Denied

```bash
@test "handles permission denied on output file" {
    local outfile="$BATS_TEST_TMP/unwritable.txt"
    touch "$outfile"
    chmod 0444 "$outfile"  # read-only

    run my-script --output "$outfile" <<< "test data"
    [ "$status" -eq 1 ]
    [[ "$output" == *"permission"* ]] || [[ "$output" == *"denied"* ]]
}

@test "handles unreadable input file" {
    local infile="$BATS_TEST_TMP/unreadable.txt"
    echo "data" > "$infile"
    chmod 0000 "$infile"

    run my-script --input "$infile"
    [ "$status" -eq 1 ]
    [[ "$output" == *"permission"* ]] || [[ "$output" == *"denied"* ]]
}
```

## Dependency Mocking with `skip`

Skip tests when optional dependencies are missing:

```bash
@test "requires jq for JSON processing" {
    if ! command -v jq &>/dev/null; then
        skip "jq is not installed"
    fi

    run my-script --format json
    [ "$status" -eq 0 ]
}

@test "requires 4+ CPU cores" {
    local cores
    cores=$(nproc 2>/dev/null || echo 1)
    if [ "$cores" -lt 4 ]; then
        skip "requires 4+ cores (got $cores)"
    fi

    run my-script --parallel
    [ "$status" -eq 0 ]
}
```

### Conditional Test Files

Skip an entire file by checking in `setup_file`:

```bash
setup_file() {
    if ! command -v docker &>/dev/null; then
        skip "Docker tests require docker CLI"
    fi
}

@test "docker container starts" {
    run docker run --rm hello-world
    [ "$status" -eq 0 ]
}

@test "docker container stops" {
    run docker stop my-container 2>/dev/null || true
    [ "$status" -eq 0 ]
}
```

## Shell Compatibility Testing

Test the same scripts against multiple shells:

```bash
# tests/compatibility.bats

setup() {
    export SCRIPT_UNDER_TEST="$BATS_TEST_DIRNAME/../bin/my-script"
}

@test "works with bash" {
    run bash "$SCRIPT_UNDER_TEST"
    [ "$status" -eq 0 ]
}

@test "works with dash (POSIX)" {
    if ! command -v dash &>/dev/null; then
        skip "dash not installed"
    fi
    run dash "$SCRIPT_UNDER_TEST"
    [ "$status" -eq 0 ]
}

@test "works with busybox ash" {
    if ! command -v busybox &>/dev/null; then
        skip "busybox not installed"
    fi
    run busybox sh "$SCRIPT_UNDER_TEST"
    [ "$status" -eq 0 ]
}
```

### Compatibility Test Patterns for Sourced Libraries

```bash
@test "lib sources cleanly under bash" {
    run bash -c 'source "$BATS_TEST_DIRNAME/../lib/my-lib.sh" && my_function'
    [ "$status" -eq 0 ]
}

@test "lib sources cleanly under dash" {
    if ! command -v dash &>/dev/null; then
        skip "dash not installed"
    fi
    run dash -c '
        . "$0/../lib/my-lib.sh"
        my_function
    ' "$BATS_TEST_DIRNAME"
    [ "$status" -eq 0 ]
}
```

### Testing for Bash-Specific Features

```bash
@test "uses arrays (bash-specific)" {
    run bash -c '
        source "$BATS_TEST_DIRNAME/../lib/my-lib.sh"
        declare -a items
        items=("a" "b" "c")
        process_items "${items[@]}"
    ' "$BATS_TEST_DIRNAME"
    [ "$status" -eq 0 ]
}

@test "POSIX fallback tested separately" {
    run dash -c '
        . "$BATS_TEST_DIRNAME/../lib/my-lib-posix.sh"
        process_items "a" "b" "c"
    ' "$BATS_TEST_DIRNAME"
    [ "$status" -eq 0 ]
}
```

## Parallel Execution

### Built-in Parallelism (Bats 1.8+)

```bash
# Run tests with parallel jobs
bats --jobs "$(nproc)" tests/

# Specify exact job count
bats --jobs 4 tests/
```

### Job Specification

```bash
# Use all available cores
bats --jobs "$(nproc)" tests/

# Limit to 2 parallel jobs (preserves I/O sanity)
bats --jobs 2 tests/
```

### Safety Rules for Parallel Tests

```bash
# tests/test_helper.bash — parallel-safe setup

setup() {
    # Each test gets a unique temp dir (parallel-safe)
    export BATS_TEST_TMP=$(mktemp -d "/tmp/bats-test-${BATS_TEST_NAME:-$$}-XXXXXXXXXX")

    # Use BATS_TEST_TMP.BATS_TEST_NAME for unique files
    export TEST_OUTPUT="${BATS_TEST_TMP}/output.txt"
}

teardown() {
    rm -rf "$BATS_TEST_TMP"
}
```

### Avoiding Race Conditions

```bash
# BAD — shared filename causes race in parallel mode
@test "write to shared file" {
    echo "data" > /tmp/shared-output.txt    # RACE!
    run my-script
    [ "$(cat /tmp/shared-output.txt)" = "expected" ]  # WRONG — other test may overwrite
}

# GOOD — unique per test
@test "write to unique file" {
    local outfile="$BATS_TEST_TMP/output.txt"
    echo "data" > "$outfile"
    run my-script --output "$outfile"
    [ "$(cat "$outfile")" = "expected" ]
}
```

### Parallel-Safe Fixture Generation

```bash
setup_file() {
    # Shared fixtures are READ-ONLY
    export FIXTURE_DATA=$(mktemp -d)
    printf "a\nb\nc\n" > "$FIXTURE_DATA/input.txt"
    # Make immutable — parallel tests should never modify shared fixtures
    chmod -R a-w "$FIXTURE_DATA"
}

setup() {
    # Per-test writable copy
    export TEST_DIR=$(mktemp -d)
    cp -r "$FIXTURE_DATA/." "$TEST_DIR/"
}
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shell: [bash, dash, busybox]

    steps:
      - uses: actions/checkout@v4

      - name: Install Bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats

      - name: Install dependencies (${{ matrix.shell }})
        run: |
          if [ "${{ matrix.shell }}" = "dash" ]; then
            sudo apt-get install -y dash
          elif [ "${{ matrix.shell }}" = "busybox" ]; then
            sudo apt-get install -y busybox
          fi

      - name: Run tests
        run: bats tests/
```

### Matrix Testing with Shell Variants

```yaml
# .github/workflows/shell-matrix.yml
jobs:
  test:
    strategy:
      matrix:
        shell: [bash, dash, busybox]
        os: [ubuntu-22.04, ubuntu-24.04]

    steps:
      - uses: actions/checkout@v4
      - name: Install Bats
        run: sudo apt-get install -y bats
      - name: Run tests with ${{ matrix.shell }}
        run: bats --formatter tap tests/
```

### Makefile Targets

```makefile
# Makefile — Bats test targets

BATS        := bats
BATS_FLAGS  := --print-output-on-failure

.PHONY: test test-all test-parallel test-compat

# Run all tests
test:
	$(BATS) $(BATS_FLAGS) tests/

# Run a single test file
test-file:
	$(BATS) $(BATS_FLAGS) tests/$(FILE)

# Run tests in parallel
test-parallel:
	$(BATS) $(BATS_FLAGS) --jobs $$(nproc) tests/

# Run with specific formatter
test-ci:
	$(BATS) --formatter tap13 tests/

# Cross-shell compatibility tests
test-compat:
	for shell in bash dash busybox sh; do \
		if command -v "$$shell" &>/dev/null; then \
			echo "=== Testing with $$shell ==="; \
			bats tests/compatibility.bats; \
		else \
			echo "Skipping $$shell (not installed)"; \
		fi; \
	done

# Run tests and check for regressions
test-regression:
	$(BATS) --recursive tests/
```

### Coverage Tracking

```bash
# Generate coverage data alongside tests
setup() {
    export BASH_COVERAGE=1
}

@test "script executes all paths" {
    # Use kcov to instrument script
    run kcov --include-path=./bin coverage ./bin/my-script --test-mode
    [ "$status" -eq 0 ]
}
```

## Test Helper Library Pattern

Create reusable assertion and utility libraries:

```bash
# tests/test_helper.bash — shared helpers for all test files

# === File Assertions ===

assert_file_contains() {
    local file="$1" pattern="$2"
    if ! grep -q "$pattern" "$file"; then
        echo "expected file $file to contain: $pattern" >&2
        echo "actual content:" >&2
        cat "$file" >&2
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1" pattern="$2"
    if grep -q "$pattern" "$file"; then
        echo "expected file $file to NOT contain: $pattern" >&2
        return 1
    fi
}

# === Command Assertions ===

assert_command_exists() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "expected command '$cmd' to exist" >&2
        return 1
    fi
}

# === Environment Assertions ===

assert_env_var_set() {
    local var="$1"
    if [[ -z "${!var:-}" ]]; then
        echo "expected environment variable '$var' to be set" >&2
        return 1
    fi
}

# === File Generation Utilities ===

generate_test_file() {
    local file="$1" size_kb="$2"
    dd if=/dev/zero bs=1024 count="$size_kb" of="$file" 2>/dev/null
}

generate_csv_fixture() {
    local file="$1" rows="$2"
    {
        echo "id,name,email"
        for i in $(seq 1 "$rows"); do
            echo "$i,user${i},user${i}@example.com"
        done
    } > "$file"
}

# === Test Isolation Utilities ===

# Usage: in_test_dir
# Creates a temp dir and cd's into it. Cleans up on teardown.
in_test_dir() {
    export _TEST_DIR
    _TEST_DIR=$(mktemp -d)
    cd "$_TEST_DIR" || return 1
}

cleanup_test_dir() {
    if [[ -n "${_TEST_DIR:-}" && -d "$_TEST_DIR" ]]; then
        rm -rf "$_TEST_DIR"
    fi
}

# === Fixture Diff ===

# Compare actual output to expected fixture, fail with diff on mismatch
assert_against_fixture() {
    local actual="$1" expected_fixture="$2"
    if ! diff -u "$expected_fixture" "$actual"; then
        echo "FAIL: output differs from fixture" >&2
        return 1
    fi
}
```

### Using the Helper Library

```bash
# tests/my-script.bats

load test_helper

setup() {
    in_test_dir
    export HOME="$PWD"
}

teardown() {
    cleanup_test_dir
}

@test "script generates expected output" {
    generate_csv_fixture "input.csv" 5
    run my-script process "input.csv"

    [ "$status" -eq 0 ]
    assert_file_contains "$output" "processed"
}

@test "script errors on missing input" {
    run my-script process "/nonexistent.csv"
    assert_failure
    [[ "$output" == *"not found"* ]]
}
```

### Recommended Directory Structure with Helpers

```
tests/
├── test_helper.bash          # Shared across all test files
├── helpers/
│   ├── file-helpers.bash     # File-related assertion helpers
│   ├── mock-helpers.bash     # Common mock factories
│   └── data-gen.bash         # Test data generators
├── fixtures/
│   ├── sample-config.yml
│   └── large-input.csv
├── my-script.bats            # Tests for bin/my-script
├── lib/
│   └── utils.bats            # Tests for lib/utils.sh
└── integration/
    ├── full-workflow.bats    # End-to-end workflow tests
    └── network.bats          # Tests requiring network
```

## Verification Markers

After writing tests using this guide, verify correctness:

```bash
# Run all tests
bats tests/

# Run with verbose failure output
bats --print-output-on-failure tests/

# Run a specific test file
bats tests/my-script.bats

# Run a specific test by name pattern
bats --filter "error condition" tests/

# Run with parallel jobs
bats --jobs "$(nproc)" tests/

# Validate shell syntax of test files
bash -n tests/*.bats
```

```bash
# Verify bats is installed and version
bats --version
# bats 1.11.0
```

[Check] Loaded testing.md for domain bash-testing
[Check] Applied bats fundamentals knowledge during test creation
[Check] Verified assertions, mocking, fixture, and error patterns are covered
[Check] CI/CD integration examples include GitHub Actions and Makefile targets
[Check] Shell compatibility testing is covered (bash, dash, busybox)
