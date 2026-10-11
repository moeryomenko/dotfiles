# Go Testing

## Table-driven tests and subtests

Use table-driven tests when cases exercise the same behavior through different inputs. Name fields for cases with enough values that positional literals obscure intent. Use subtests when independent case names, filtering, setup, or failure isolation help the reader.

```go
func TestJoin(t *testing.T) {
    tests := []struct {
        name string
        give []string
        sep  string
        want string
    }{
        {name: "two elements", give: []string{"a", "b"}, sep: ",", want: "a,b"},
        {name: "empty slice", give: nil, sep: ",", want: ""},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := strings.Join(tt.give, tt.sep)
            if got != tt.want {
                t.Errorf("Join(%v, %q) = %q, want %q", tt.give, tt.sep, got, tt.want)
            }
        })
    }
}
```

Run a named subtest with `go test -run 'TestJoin/two_elements'`.

## Helpers and failure control

Call `t.Helper()` in helpers so failures point to the caller. Helpers are appropriate for repeated setup, assertions with domain-specific diagnostics, or test fixtures; keep one-off assertions local when that is clearer.

Use `t.Fatal` or `t.FailNow` only from the test goroutine. They stop that goroutine with `runtime.Goexit`, not work launched by it. A worker should return its result through synchronization, then the test goroutine decides how to fail.

```go
func TestEngine(t *testing.T) {
    errCh := make(chan error, 1)
    go func() {
        errCh <- engine.Vroom()
    }()

    if err := <-errCh; err != nil {
        t.Fatalf("Vroom: %v", err)
    }
}
```

`t.Error` may be called from another goroutine, but arrange for the test to wait for that goroutine. Prefer sending errors back when it makes ownership and completion explicit.

## Scope setup and cleanup

Keep setup as narrow as practical: tests that do not need an expensive fixture should not pay for it. For shared immutable setup, `sync.Once` can avoid repeated work; record and check initialization errors on every caller.

```go
var dataset struct {
    once sync.Once
    data []byte
    err  error
}

func loadDataset(t *testing.T) []byte {
    t.Helper()
    dataset.once.Do(func() {
        dataset.data, dataset.err = os.ReadFile("testdata/dataset")
    })
    if dataset.err != nil {
        t.Fatalf("read dataset: %v", dataset.err)
    }
    return dataset.data
}
```

Use `t.Cleanup` for cleanup associated with the current test. Avoid package-global mutable fixtures unless isolation and reset behavior are explicit.

## Contexts

`testing.T.Context` is available in Go 1.24 and later. It is useful for work that should end with the test, but derive a context with its own cancellation, timeout, or lifetime when that is the behavior under test.

```go
func TestWorker(t *testing.T) {
    ctx := t.Context() // Go 1.24+
    _ = ctx
}
```

For earlier Go versions, start with an appropriate context and ensure the test cancels contexts it creates.

## Selecting test boundaries

Choose the narrowest test that proves the behavior:

| Boundary | Typical tools |
|---|---|
| Pure logic | direct unit tests and table cases |
| Owned dependency behavior | fakes or stubs implementing a consumer-owned interface |
| HTTP handler or client behavior | `httptest` server/recorder and real request/response encoding |
| Database, broker, or service integration | the real dependency when its semantics are what must be proven |
| End-to-end behavior | the repository's deployment and orchestration tooling |

Do not hand-implement a protocol client merely to test it when `httptest` or a real test server exercises the intended boundary more faithfully. Conversely, use fakes when an external system is not part of the behavior under test.

## Test doubles

Name and package test doubles according to local conventions. A separate `foo_test` helper package can make a reusable fake clear, but keeping a small fake next to its tests is often simpler. Model the minimum behavior the consumer relies on and expose observations needed for assertions.

Use `t.Setenv`, `t.TempDir`, and `t.Cleanup` where supported instead of manually restoring process-scoped test state.
