# Go Linter Guide

## Setup

### Recommended Config (golangci-lint)

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck      # unchecked errors
    - gosimple      # simplify code
    - govet         # correctness (run at minimum)
    - ineffassign   # ineffective assignments
    - staticcheck   # static analysis (high-value)
    - typecheck     # type errors
    - unused        # unused code
    - asasalint     # variadic arg passing
    - asciicheck    # non-ASCII identifiers
    - bodyclose     # HTTP response body not closed
    - canonicalheader # canonical HTTP header casing
    - containedctx  # struct contains context.Context
    - contextcheck  # context.WithValue key type
    - copyloopvar   # loop var copied by value
    - cyclop        # cyclomatic complexity
    - decorder      # declaration order
    - dupl          # duplicate code
    - durationcheck # time.Duration multiplication
    - errname       # error naming convention
    - errorlint     # error wrapping
    - exhaustive    # exhaustive enum checks
    - fatcontext    # t.Fatal in goroutines
    - forcetypeassert # type assertion without ok
    - funlen        # function length
    - gochecknoglobals # no globals (library code)
    - gochecknoinits  # no init functions
    - goconst       # repeated string to const
    - gocritic      # opinionated style checks
    - godot         # comments end in period
    - gofmt         # formatting
    - goheader      # license header
    - goimports     # import grouping
    - gomoddirectives # replace/retract directives
    - gomodguard    # banned/blocked modules
    - gosec         # security
    - lll           # line length
    - loggercheck   # key-value pairs
    - makezero      # make(..., 0) then append
    - mirror        # mirror to stdlib
    - mnd           # magic numbers
    - musttag       # struct tags
    - nakedret      # naked returns
    - nestif        # deeply nested ifs
    - nilerr        # nil error return
    - nilnil        # nil, nil returns
    - nlreturn      # newline before return
    - noctx         # no context.Context
    - nolintlint    # nolint directives
    - nonamedreturns # named returns
    - nosprintfhostport # sprintf host:port
    - paralleltest  # parallel test detection
    - perfsprint    # fmt.Sprintf to strconv
    - predeclared   # shadowing predeclared
    - promlinter    # Prometheus metrics
    - protogetter   # proto getters
    - reassign      # reassigning variables
    - revive        # golint replacement
    - rowserrcheck  # sql.Rows errors
    - sloglint      # slog usage
    - spancheck     # otel spans
    - sqlclosecheck # sql.Rows, sql.Stmt close
    - tagalign      # struct tag alignment
    - tagliatelle   # naming convention tags
    - tenv          # testing os.Setenv
    - testableexamples # examples
    - testifylint   # testify assertions
    - testpackage   # _test.go packages
    - thelper       # testing.T helper
    - unconvert     # unnecessary conversion
    - unparam       # unused params
    - usestdlibvars # standard library vars
    - wastedassign  # wasted assignments
    - whitespace    # blank lines
    - wrapcheck     # error wrapping
    - wsl           # whitespace (strict)
  disable:
    - depguard      # restrictive
    - exhaustruct   # struct literal exhaustiveness
    - forbidigo     # forbidding identifiers
    - ireturn       # interface return restriction
    - prealloc      # premature slice preallocation
    - varnamelen    # short var names (noisy)

issues:
  max-issues-per-linter: 0
  max-same-issues: 0
```

## Linter Categories

### Critical (must-have for correctness)

| Linter | What it catches |
|---|---|
| `govet` | Suspicious constructs |
| `staticcheck` | Bugs, dead code, bad practices (SA series) |
| `errcheck` | Unchecked errors |
| `ineffassign` | Assignments with no effect |
| `bodyclose` | HTTP body leaks |
| `contextcheck` | Context misuse |

### Recommended (style + simplicity)

| Linter | What it enforces |
|---|---|
| `gofmt` / `goimports` | Formatting, import grouping |
| `gosimple` | Simpler constructs (S series) |
| `revive` | Golint replacement |
| `gocritic` | Opinionated style checks |
| `errorlint` | Error wrapping correctness |
| `mirror` | Mirror operations to stdlib (slices, maps) |

### Go Version–Aware

| Linter | Watches for |
|---|---|
| `copyloopvar` | Unnecessary loop var copies (Go 1.22+) |
| `perfsprint` | `fmt.Sprintf` → `strconv` (Go 1.21+) |
| `sloglint` | `log/slog` usage (Go 1.21+) |

### Testing

| Linter | What it enforces |
|---|---|
| `paralleltest` | Parallel test detection |
| `testifylint` | Require/assert consistency |
| `thelper` | `t.Helper()` calls |
| `fatcontext` | `t.Fatal` in goroutines |
| `tenv` | `os.Setenv` → `t.Setenv` |

## Linter Coverage by Concern

| Concern | Tool |
|---------|------|
| Package naming & documentation | `revive` (package-comments) |
| Formatting (`gofmt`) | `gofmt` / `goimports` |
| Variable shadowing | `govet` (-shadow) |
| Unique interface names | Manual review |
| Enum size optimization | Manual review |
| Deterministic initialization | `gochecknoinits` |
| Minimal variable scope | `gocritic` (paramTypeCombine) |
| Performance invariants | Manual review |
| Duplicate code | `dupl` |
| Zero-value readiness | Manual review |

## CI Integration

```yaml
# GitHub Actions
- name: Lint
  uses: golangci/golangci-lint-action@v6
  with:
    version: latest
    args: --out-format=colored-line-number
    only-new-issues: true  # comment on PR diffs
```

## Cross-References

- For Go style enforced by linters: load `style`
- For error linting rules: load `error-handling`
- For test linting rules: load `testing`
- For modern features that avoid legacy lint warnings: load `modern-features`
