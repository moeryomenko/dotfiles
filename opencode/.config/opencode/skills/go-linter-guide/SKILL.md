---
name: go-linter-guide
description: Comprehensive golangci-lint linter reference organized by category. Use when configuring linting for Go projects, selecting linters for code quality, or diagnosing linter output.
---

# golangci-lint Linter Guide

## Quick Start

The Uber Go Style Guide recommends this **base set** of linters:

| Linter | Purpose |
|---|---|
| `errcheck` | Ensure errors are handled |
| `goimports` | Format code + manage imports |
| `revive` | Style mistakes (successor to `golint`) |
| `govet` | Common mistakes (built-in `go vet`) |
| `staticcheck` | Broad static analysis |

Use `golangci-lint` as the runner with a `.golangci.yml` config.

---

## Linter Categories

### 1. Bugs & Correctness (CRITICAL — enable always)

| Linter | Description | Auto-fix |
|---|---|---|
| `govet` | Reports suspicious constructs. `go vet` passes. | Yes |
| `errcheck` | Checks for unchecked errors | No |
| `staticcheck` | Broad static analysis (SA series) | Yes |
| `bodyclose` | Ensures HTTP response bodies are closed | No |
| `sqlclosecheck` | Ensures sql.Rows, sql.Stmt are closed | No |
| `rowserrcheck` | Ensures sql.Rows.Err is checked | No |
| `noctx` | Detects missing context.Context usage | No |
| `durationcheck` | Detects multiplying two durations | No |
| `nilerr` | Finds code returning nil after checking err != nil | No |
| `nilnil` | Checks for simultaneous nil error + invalid value | No |
| `errorlint` | Finds issues with Go 1.13 error wrapping scheme | Yes |
| `gosec` | Inspects for security problems | No |
| `spancheck` | Checks OpenTelemetry/Census span mistakes | No |
| `wastedassign` | Finds wasted assignment statements | No |
| `fatcontext` | Detects nested contexts in loops | Yes |

### 2. Performance (HIGH — enable in CI)

| Linter | Description | Auto-fix |
|---|---|---|
| `prealloc` | Finds slices that could be pre-allocated | No |
| `makezero` | Finds slice declarations with non-zero initial length | No |
| `copyloopvar` | Detects loop variable copies | Yes |
| `mirror` | Reports wrong bytes/strings usage patterns | Yes |
| `perfsprint` | Checks for fmt.Sprintf that can be faster | Yes |
| `predeclared` | Finds shadowing of Go predeclared identifiers | No |

### 3. Style & Formatting (MEDIUM — configure per project)

| Linter | Description | Auto-fix |
|---|---|---|
| `revive` | Configurable style linter (golint replacement) | Yes |
| `gofmt` / `gofumpt` | Formatting | Yes |
| `goimports` | Import formatting | Yes |
| `whitespace` | Checks unnecessary newlines in functions/blocks | Yes |
| `nlreturn` | Requires newline before return | Yes |
| `wsl_v5` | Add/remove empty lines | Yes |
| `lll` | Reports long lines | No |
| `nestif` | Reports deeply nested if statements | No |
| `gocognit` | Computes cognitive complexity | No |
| `gocyclo` / `cyclop` | Cyclomatic complexity | No |
| `funlen` | Checks for long functions | No |
| `maintidx` | Measures maintainability index | No |
| `goconst` | Finds repeated strings that could be constants | No |
| `decorder` | Checks declaration order | No |

### 4. Naming & Conventions (MEDIUM)

| Linter | Description | Auto-fix |
|---|---|---|
| `errname` | Checks sentinel errors are `Err` prefixed, types `Error` suffixed | No |
| `goprintffuncname` | Checks printf-like functions end with `f` | No |
| `inamedparam` | Reports interfaces with unnamed method parameters | No |
| `varnamelen` | Checks variable name length matches scope | No |
| `nonamedreturns` | Reports all named returns | No |

### 5. Modern Go & Best Practices (RECOMMENDED)

| Linter | Description | Auto-fix |
|---|---|---|
| `modernize` | Suggests modern Go simplifications | Yes |
| `usestdlibvars` | Suggests stdlib vars/constants instead of literals | Yes |
| `exptostd` | Detects `golang.org/x/exp/` functions replaceable by std | Yes |
| `intrange` | Finds `for` loops that could use integer range | Yes |
| `unconvert` | Removes unnecessary type conversions | No |
| `musttag` | Enforces field tags in marshaled structs | No |
| `unparam` | Reports unused function parameters | No |
| `usetesting` | Reports uses of functions with testing package replacements | Yes |

### 6. Error Handling (RECOMMENDED)

| Linter | Description | Auto-fix |
|---|---|---|
| `errcheck` | Ensures errors are checked | No |
| `errorlint` | Finds problems with error wrapping | Yes |
| `errchkjson` | Checks types passed to json encoding | No |
| `err113` | Checks error handling expressions | Yes |
| `nilerr` | Nil error checks | No |
| `nilnesserr` | Reports returning different nil value error | No |
| `wrapcheck` | Checks external errors are wrapped | No |

### 7. Testing (RECOMMENDED)

| Linter | Description | Auto-fix |
|---|---|---|
| `testifylint` | Checks testify usage | Yes |
| `thelper` | Checks test helpers call t.Helper() | No |
| `paralleltest` | Detects missing t.Parallel() | No |
| `tparallel` | Detects inappropriate t.Parallel() usage | No |
| `testpackage` | Requires separate `_test` package | No |
| `ginkgolinter` | Enforces ginkgo/gomega standards | Yes |
| `testableexamples` | Checks examples have expected output | No |

### 8. Import Management

| Linter | Description | Auto-fix |
|---|---|---|
| `goimports` | Standard import formatting | Yes |
| `grouper` | Analyzes expression groups | No |
| `importas` | Enforces consistent import aliases | Yes |
| `depguard` | Package import allow/blocklist | No |
| `gomoddirectives` | Manages replace/retract/exclude in go.mod | No |
| `gomodguard_v2` | Module allow/blocklist with version constraints | No |

### 9. Type & Interface Safety

| Linter | Description | Auto-fix |
|---|---|---|
| `forcetypeassert` | Finds forced type assertions (no comma-ok) | No |
| `iface` | Detects interface pollution | Yes |
| `interfacebloat` | Checks number of methods in interfaces | No |
| `ireturn` | Enforces "accept interfaces, return concrete types" | No |
| `containedctx` | Detects structs containing context.Context | No |
| `recvcheck` | Checks receiver type consistency | No |

### 10. Documentation & Comments

| Linter | Description | Auto-fix |
|---|---|---|
| `godot` | Checks comments end in period | Yes |
| `godox` | Detects TODO/FIXME/BUG comments | No |
| `godoclint` | Checks golang documentation practice | No |
| `misspell` | Finds misspelled English words | Yes |
| `dupword` | Checks for duplicate words | Yes |

### 11. Specialized Linters (Domain-Specific)

| Linter | Domain | Auto-fix |
|---|---|---|
| `protogetter` | Protobuf — detect direct field reads | Yes |
| `sloglint` | log/slog — consistent style | Yes |
| `zerologlint` | zerolog — detect missing Msg/Send | No |
| `loggercheck` | Common logger libs (kitlog, klog, logr, slog, zap) | No |
| `tagalign` | Struct tag alignment | Yes |
| `tagliatelle` | Struct tag conventions (camelCase, snake_case) | No |
| `promlinter` | Prometheus metrics naming | No |
| `nosprintfhostport` | Sprintf for host:port | No |
| `unqueryvet` | SELECT * in SQL queries | No |
| `canonicalheader` | net/http canonical headers | Yes |
| `spancheck` | OpenTelemetry spans | No |

---

## Recommended Configuration (.golangci.yml)

```yaml
linters:
  enable:
    # Bugs & Correctness
    - govet
    - errcheck
    - staticcheck
    - bodyclose
    - sqlclosecheck
    - durationcheck
    - errorlint
    - nilerr
    
    # Performance
    - prealloc
    - makezero
    - copyloopvar
    
    # Modern Go
    - modernize
    - usestdlibvars
    - intrange
    - unconvert
    - musttag
    - unparam
    
    # Style
    - revive
    - goimports
    - whitespace
    - goconst
    
    # Testing
    - testifylint
    - thelper
    - paralleltest
    
    # Naming
    - errname
    - goprintffuncname
    
    # Imports
    - grouper
    - importas
    
    # Safety
    - forcetypeassert
    - containedctx
    - recvcheck
    
    # Documentation
    - godot
    - misspell

linters-settings:
  errcheck:
    check-type-assertions: true
  
  revive:
    rules:
      - name: exported
      - name: blank-imports
      - name: context-as-argument
      - name: error-return
      - name: error-strings
      - name: increment-decrement
      - name: indent-error-flow
      - name: range
      - name: receiver-naming
      - name: time-equal
      - name: time-naming
      - name: var-naming
  
  staticcheck:
    checks:
      - all
  
  govet:
    enable:
      - fieldalignment
      - shadow
  
  misspell:
    locale: US

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

---

## Deprecated Linters (DO NOT USE)

| Linter | Replacement |
|---|---|
| `golint` | `revive` |
| `gomodguard` | `gomodguard_v2` |
| `wsl` | `wsl_v5` |
| `scopelint` | Removed (fixed in Go 1.22) |
| `interfacer` | Removed |
| `maligned` | Removed (use `govet` fieldalignment) |

---

## Linter Selection Guidelines by Project Type

### Library/Module
- Enable all bug + correctness linters.
- Enable `iface`, `interfacebloat`, `ireturn` to prevent API bloat.
- Enable `musttag` for serialization correctness.
- Enable `testifylint`, `thelper`, `paralleltest`.

### Web Service/API
- Add `bodyclose`, `noctx`, `canonicalheader`.
- Add `gosec` for security scanning.
- Add `loggercheck` for consistent logging.

### CLI Tool
- Enable all style linters (`revive`, `nlreturn`, `wsl_v5`).
- Enable `gochecknoglobals`, `gochecknoinits`.

### Data Pipeline
- Enable `durationcheck`, `prealloc`.
- Enable `spancheck` for OpenTelemetry.
- Add `exhaustive` for enum exhaustiveness.

---

## Quick Troubleshooting

| Linter Error | Likely Fix |
|---|---|
| "string `X` X times" (goconst) | Extract repeated string to const |
| "unnecessary conversion" (unconvert) | Remove type cast |
| "error not checked" (errcheck) | Handle or explicitly `_ =` |
| "deeply nested if" (nestif) | Return early, reduce nesting |
| "cognitive complexity X" (gocognit) | Extract helper functions |
| "st1000" (staticcheck) | Add package comment |
| "fieldalignment" (govet) | Reorder struct fields to reduce padding |
| "SA4006" (staticcheck) | Unused value — check or remove |
| "SA1029" (staticcheck) | Use context.WithValue with custom key type |
| "not used" (unused) | Remove dead code |
