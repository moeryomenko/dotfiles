# Go Testing

## Table-Driven Tests

The standard Go testing pattern. Name the table `tests`, each case `tt`. Prefix inputs/outputs with `give`/`want`:

```go
func TestJoin(t *testing.T) {
    tests := []struct {
        give []string
        sep  string
        want string
    }{
        {give: []string{"a", "b"}, sep: ",", want: "a,b"},
        {give: []string{}, sep: ",", want: ""},
    }
    for _, tt := range tests {
        got := strings.Join(tt.give, tt.sep)
        if got != tt.want {
            t.Errorf("Join(%v, %q) = %q, want %q", tt.give, tt.sep, got, tt.want)
        }
    }
}
```

### Subtests

Use `t.Run` for subtests, especially with table-driven tests:

```go
func TestJoin(t *testing.T) {
    tests := []struct {
        name string
        give []string
        sep  string
        want string
    }{
        {name: "two elements", give: []string{"a", "b"}, sep: ",", want: "a,b"},
        {name: "empty slice", give: []string{}, sep: ",", want: ""},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := strings.Join(tt.give, tt.sep)
            if got != tt.want {
                t.Errorf("got %q, want %q", got, tt.want)
            }
        })
    }
}
```

### Filtering by Subtest

```bash
go test -run TestJoin/two_elements
go test -run TestJoin/empty
```

## Test Helpers vs Assertion Helpers

- **Test helpers**: Setup/cleanup. Failures are environment issues. Call `t.Helper()`.
- **Assertion helpers**: NOT idiomatic in Go. Keep assertions in the `Test` function.

```go
// Good — test helper, uses t.Fatal for environment failures
func mustAddGameAssets(t *testing.T, dir string) {
    t.Helper()
    if err := os.WriteFile(path.Join(dir, "pak0.pak"), pak0, 0644); err != nil {
        t.Fatalf("Setup failed: could not write pak0 asset: %v", err)
    }
}

// Bad — assertion helper pattern, not idiomatic
func assertEqual(t *testing.T, got, want interface{}) {
    t.Helper()
    if got != want { t.Errorf("got %v, want %v", got, want) }
}
```

### `t.Error` vs `t.Fatal`

| Scenario | Use |
|---|---|
| Test setup failure (can't proceed) | `t.Fatal` |
| Single table entry (no subtests) | `t.Error` + `continue` |
| Single subtest (inside `t.Run`) | `t.Fatal` (ends only the subtest) |

### `t.Fatal` from Goroutines

Only the test goroutine can call `t.Fatal`. Use `t.Error` from goroutines:

```go
go func() {
    if err := engine.Vroom(); err != nil {
        t.Errorf("No vroom left on engine: %v", err) // NOT t.Fatalf
        return
    }
}()
```

## Keep Setup Scoped

Call setup functions explicitly in tests that need them, not globally:

```go
func TestParseData(t *testing.T) {
    data := mustLoadDataset(t) // Only this test pays the cost
}

func TestFast(t *testing.T) {
    // No dataset needed
}
```

For expensive shared setup, use `sync.Once`:

```go
var dataset struct {
    once sync.Once
    data []byte
    err  error
}

func mustLoadDataset(t *testing.T) []byte {
    t.Helper()
    dataset.once.Do(func() {
        dataset.data, dataset.err = os.ReadFile("path/to/dataset")
    })
    return dataset.data
}
```

## Use Real Transports

When testing HTTP/RPC integrations, use real clients connected to test servers — don't hand-implement clients.

## Use `t.Context()` (Go 1.24+)

Always use `t.Context()` for test contexts:

```go
// Before
func TestFoo(t *testing.T) {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
}

// After
func TestFoo(t *testing.T) {
    ctx := t.Context()
}
```

## Field Names in Test Structs

Specify field names in table-driven tests, especially with many fields:

```go
tests := []struct {
    slice     []string
    separator string
    skipEmpty bool
    want      string
}{
    {
        slice:     []string{"a", "b", ""},
        separator: ",",
        want:      "a,b,",
    },
}
```

## Test Double Packages

Name test double packages by appending `test` to the production package name:

```go
// Package creditcard -> creditcardtest
package creditcardtest

type Stub struct{}
func (Stub) Charge(*creditcard.Card, money.Money) error { return nil }
```

Prefix double variable names for clarity:

```go
var spyCC creditcardtest.Spy
proc := &Processor{CC: spyCC}
```

## Functional Test Infrastructure

For black-box HTTP functional tests with Docker Compose + pytest, use a 3-layer architecture:

```
Layer 1: Infrastructure (Docker Compose)
    Data deps → SUT → Test runner

Layer 2: Test Code (Python pytest)
    conftest.py → helpers.py → test_*.py

Layer 3: Orchestration (Makefile)
    make functional-tests
```

### Directory Structure

```
tests/
  functional/
    conftest.py          # Session-scoped fixtures (URLs, payloads)
    helpers.py           # HTTP wrappers, validators
    requirements.txt     # pytest + requests
    test_core.py         # Happy path, edge cases, errors
  docker-compose.test.yml
```

### Key Patterns

| Pattern | Implementation |
|---|---|
| **Fixtures** | Session-scoped, env vars with defaults |
| **Helpers** | Single `make_request()` entry point; typed wrappers |
| **Infra** | `service_healthy` condition prevents races |
| **Cleanup** | `down --volumes --remove-orphans` always runs |
| **CI** | Only `docker` + `docker compose` required |

## Cross-References

- For error handling patterns in tests: load `error-handling`
- For modern Go testing features (Go 1.24+): load `modern-features`
- For linting test code: load `linter-guide`
