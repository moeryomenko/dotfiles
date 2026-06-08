---
name: go-best-practices
description: Google Go Style Best Practices covering naming, error handling, testing, API design, documentation, and package organization. Use when writing Go code that needs to follow Google's idiomatic patterns.
---

# Go Best Practices

This skill documents practical guidance from the Google Go Style Guide's best practices. It covers common design situations and trade-offs, complementing the core style guide rules.

---

## 1. Naming

### 1.1 Avoid Repetition

When naming functions and methods, consider the call site context. Omit what's already clear:

```go
// Bad — repeats package name
package yamlconfig
func ParseYAMLConfig(input string) (*Config, error)

// Good
package yamlconfig
func Parse(input string) (*Config, error)
```

**Omit from names:**
- Types of inputs/outputs (when unambiguous)
- The type of a method's receiver
- Whether an input/output is a pointer

```go
// Bad: repeats receiver type
func (c *Config) WriteConfigTo(w io.Writer) (int64, error)

// Good
func (c *Config) WriteTo(w io.Writer) (int64, error)

// Bad: repeats parameter names
func OverrideFirstWithSecond(dest, source *Config) error

// Good
func Override(dest, source *Config) error

// Bad: repeats return types
func TransformToJSON(input *Config) *jsonconfig.Config

// Good
func Transform(input *Config) *jsonconfig.Config
```

Use extra words only for disambiguation:

```go
func (c *Config) WriteTextTo(w io.Writer) (int64, error)
func (c *Config) WriteBinaryTo(w io.Writer) (int64, error)
```

### 1.2 Function Naming Conventions

- **Return something** → noun-like names. **Avoid `Get` prefix.**

```go
// Good
func (c *Config) JobName(key string) (value string, ok bool)

// Bad
func (c *Config) GetJobName(key string) (value string, ok bool)
```

- **Do something** → verb-like names:

```go
func (c *Config) WriteDetail(w io.Writer) (int64, error)
```

- **Identical functions differing by type** → append type name at end:

```go
func ParseInt(input string) (int, error)
func ParseInt64(input string) (int64, error)
```

### 1.3 Test Double & Helper Packages

When creating test double packages, name them by appending `test` to the production package name:

```go
// Package creditcard -> creditcardtest
package creditcardtest

// Stub stubs creditcard.Service and provides no behavior of its own.
type Stub struct{}
func (Stub) Charge(*creditcard.Card, money.Money) error { return nil }
```

For multiple behaviors, name stubs by behavior:

```go
type AlwaysCharges struct{}
type AlwaysDeclines struct{}
```

For multiple types needing doubles, prefix with type name:

```go
type StubService struct{}
type StubStoredValue struct{}
```

**Local variable naming in tests**: Prefix double variable names for clarity:

```go
// Good — clear what it is
var spyCC creditcardtest.Spy
proc := &Processor{CC: spyCC}

// Bad — ambiguous
var cc creditcardtest.Spy
```

### 1.4 Shadowing

Be careful with `:=` in nested scopes — it creates a new variable (shadowing), while `=` in the same scope reassigns (stomping):

```go
// Bad: shadowing creates a new ctx only inside the if block
func (s *Server) innerHandler(ctx context.Context, req *pb.MyRequest) *pb.MyResponse {
    if *shortenDeadlines {
        ctx, cancel := context.WithTimeout(ctx, 3*time.Second) // shadows outer ctx
        defer cancel()
    }
    // BUG: ctx is the ORIGINAL, uncapped context here
}

// Good: use = to stomp (reassign) rather than shadow
func (s *Server) innerHandler(ctx context.Context, req *pb.MyRequest) *pb.MyResponse {
    if *shortenDeadlines {
        var cancel func()
        ctx, cancel = context.WithTimeout(ctx, 3*time.Second) // reassigns outer ctx
        defer cancel()
    }
    // ctx is the capped context here
}
```

### 1.5 Avoid "Util" Packages

Package names should be related to what the package provides. Names like `util`, `helper`, `common` are poor choices — they make code harder to read and cause import conflicts.

```go
// Good — clear what each import provides
db := spannertest.NewDatabaseFromFile(...)
_, err := f.Seek(0, io.SeekStart)
b := elliptic.Marshal(curve, x, y)

// Bad — vague names obscure meaning
db := test.NewDatabaseFromFile(...)
_, err := f.Seek(0, common.SeekStart)
b := helper.Marshal(curve, x, y)
```

---

## 2. Package Organization

### 2.1 Package Size

- If client code needs two different types to interact, they belong in the same package.
- If types are tightly coupled in implementation (share unexported details), keep them in the same package.
- If a user must import two packages together to use either, merge them.
- **Convention**: One cohesive idea per package. The standard library is the model.

File organization (standard library examples):
- **Small**: `encoding/csv` — split into `reader.go` + `writer.go`
- **Medium**: `flag` — single `flag.go`
- **Large**: `net/http` — `client.go`, `server.go`, `cookie.go`

No "one type, one file" convention. Files should be focused enough that a maintainer can find things.

### 2.2 Import Ordering

Two groups: standard library first, then everything else, separated by a blank line.

### 2.3 Proto Imports

Use descriptive renamed imports for proto packages:

```go
import (
    foopb   "path/to/package/foo_service_go_proto"
    foogrpc "path/to/package/foo_service_go_grpc"
)
```

Prefer whole words. Use the proto package name up to `_go` with a `pb` suffix:

```go
import (
    pushqueueservicepb "path/to/package/push_queue_service_go_proto"
)
```

---

## 3. Error Handling

### 3.1 Error Structure

Give errors structure so callers can interrogate them programmatically, not via string matching.

**Sentinel errors** (global values, compared with `==` or `errors.Is`):

```go
var ErrDuplicate = errors.New("duplicate")
var ErrMarsupial = errors.New("marsupials are not supported")

func process(animal Animal) error {
    switch {
    case seen[animal]:
        return ErrDuplicate
    case marsupial(animal):
        return ErrMarsupial
    }
    return nil
}

// Caller
switch err := process(an); {
case errors.Is(err, ErrDuplicate):
    return fmt.Errorf("feed %q: %v", an, err)
case errors.Is(err, ErrMarsupial):
    // handle differently
}
```

**Never match on error strings:**

```go
// Bad
if regexp.MatchString(`duplicate`, err.Error()) { ... }
```

### 3.2 Adding Information to Errors

Add context without being redundant:

```go
// Good — adds relevant context without repeating path
if err := os.Open("settings.txt"); err != nil {
    return fmt.Errorf("launch codes unavailable: %v", err)
}
// Output: launch codes unavailable: open settings.txt: no such file or directory

// Bad — duplicates what os.Open already says
if err := os.Open("settings.txt"); err != nil {
    return fmt.Errorf("could not open settings.txt: %v", err)
}
```

### 3.3 `%v` vs `%w` in Error Wrapping

| Verb | When to use |
|---|---|
| `%v` | Adding non-redundant context; creating fresh errors at system boundaries (RPC, IPC, storage); hiding underlying implementation details |
| `%w` | Callers need to inspect the error chain with `errors.Is`/`errors.As`; documented and tested as part of API contract |

```go
// %v: at system boundary, translate to canonical error
func (*FortuneTeller) SuggestFortune(...) (*pb.SuggestionResponse, error) {
    if err != nil {
        return nil, fmt.Errorf("couldn't find fortune database: %v", err)
    }
}

// %w: caller expected to inspect the chain
func (s *Server) internalFunction(ctx context.Context) error {
    if err != nil {
        return fmt.Errorf("couldn't find remote file: %w", err)
    }
}
```

### 3.4 Placement of `%w` in Error Strings

Prefer placing `%w` at the **end** of the error string (`[...]: %w`) so the error text mirrors the chain structure (newest-to-oldest):

```go
// Good — error text mirrors chain: err3: err2: err1
err1 := fmt.Errorf("err1")
err2 := fmt.Errorf("err2: %w", err1)
err3 := fmt.Errorf("err3: %w", err2)
fmt.Println(err3) // "err3: err2: err1"

// Bad — prints oldest-to-newest, confusing
err2 := fmt.Errorf("%w: err2", err1)
fmt.Println(err2) // "err1: err2"

// Bad — neither newest-to-oldest nor oldest-to-newest
err2 := fmt.Errorf("err2-1 %w err2-2", err1)
```

**Exception**: Sentinel errors identifying a failure category (e.g., `os.ErrInvalid`) place `%w` at the **beginning** so the category is immediately visible:

```go
// Good — sentinel at front for immediate categorization
return fmt.Errorf("%w: invalid header: %v", ErrParseInvalidHeader, err)
```

### 3.5 Logging Errors

- **Don't log + return**: Let the caller decide how to handle. Avoid logspam.
- Use `log.Error` sparingly — it causes a flush and is expensive.
- ERROR should be **actionable**, not just "more serious" than WARNING.
- Prefer monitoring/alerting systems over log scraping.
- **Verbose logging** (`log.V`): Guard expensive calls:

```go
// Good — sql.Explain not called unless V(2) enabled
if log.V(2) {
    log.Infof("Handling %v", sql.Explain())
}

// Bad — sql.Explain called even when not logged
log.V(2).Infof("Handling %v", sql.Explain())
```

### 3.6 Program Checks and Panics

- Standard error handling: return errors, don't panic.
- Use `log.Fatal` (not `panic`) for unrecoverable invariant violations.
- **Don't recover panics to avoid crashes** — corrupted state can cause worse problems.
- The only exception: panic as an internal implementation detail in tightly coupled code, where a deferred `recover` at the public API boundary translates it to an error. Panics must **never escape the package**.

```go
// Good: panic as internal mechanism, recovered at public API
func parseInt(in string) int {
    n, err := strconv.Atoi(in)
    if err != nil {
        panic(&syntaxError{"not a valid integer"})
    }
}

func Parse(in string) (_ *Node, err error) {
    defer func() {
        if p := recover(); p != nil {
            sErr, ok := p.(*syntaxError)
            if !ok {
                panic(p) // re-panic unknown panics
            }
            err = fmt.Errorf("syntax error: %v", sErr.msg)
        }
    }()
    // ...
}
```

**When to use panic:**
- API misuse (like `reflect` panics) — caught in code review/tests.
- Unreachable code detection (after `log.Fatalf`).
- Package initialization functions (before flags are parsed).

---

## 4. Documentation

### 4.1 Parameter & Configuration Docs

Don't enumerate obvious parameters. Document what's error-prone or non-obvious:

```go
// Bad — states the obvious
// format is the format, and data is the interpolation data.
func Sprintf(format string, data ...any) string

// Good — explains non-obvious behavior
// The provided data is used to interpolate the format string. If the data does
// not match the expected format verbs or the amount of data does not satisfy
// the format specification, the function will inline warnings about formatting
// errors into the output string as described by the Format errors section.
func Sprintf(format string, data ...any) string
```

### 4.2 Context Documentation

It's implied that context cancellation interrupts the function and returns `ctx.Err()`. Don't restate this. Only document non-obvious behavior:

```go
// Bad — restates implied behavior
// Run executes until the context is cancelled and returns ctx.Err().
func (Worker) Run(ctx context.Context) error

// Good — let the code speak
func (Worker) Run(ctx context.Context) error
```

Document when context behavior differs from normal:

```go
// Document if it returns a nil error on cancellation (not ctx.Err())
// Run executes the worker's run loop.
// If the context is cancelled, Run returns a nil error.
func (Worker) Run(ctx context.Context) error

// Document special expectations about context
// NewReceiver starts receiving messages sent to the specified queue.
// The context should not have a deadline.
func NewReceiver(ctx context.Context) *Receiver
```

### 4.3 Concurrency Documentation

Read-only operations are assumed safe for concurrent use — don't restate.
Mutating operations are assumed NOT safe — don't restate.

Only document when behavior is non-obvious:

```go
// Good — LRU caches mutate on read, not obvious
// Lookup returns the data associated with the key from the cache.
// This operation is not safe for concurrent use.
func (*Cache) Lookup(key string) (data []byte, ok bool)

// Good — explicitly safe, important for RPC clients
// NewFortuneTellerClient returns an *rpc.Client for the FortuneTeller service.
// It is safe for simultaneous use by multiple goroutines.
func NewFortuneTellerClient(cc *rpc.ClientConn) *FortuneTellerClient
```

---

## 5. Variable Declarations

### 5.1 Zero Value Declaration

Use zero value when the value is empty but **ready for later use**:

```go
// Good — clear intent
var (
    coords Point
    magic  [4]byte
    primes []int
)

// Bad — noisy, adds no information
var (
    coords = Point{X: 0, Y: 0}
    magic  = [4]byte{0, 0, 0, 0}
    primes = []int(nil)
)
```

Common use: output variable for unmarshalling:

```go
var coords Point
if err := json.Unmarshal(data, &coords); err != nil { ... }
```

For pointer types, `new(T)` or `&T{}`:

```go
msg := new(pb.Bar)
```

### 5.2 Composite Literals

Use when you know initial elements:

```go
var (
    coords   = Point{X: x, Y: y}
    magic    = [4]byte{'I', 'W', 'A', 'D'}
    primes   = []int{2, 3, 5, 7, 11}
    captains = map[string]string{"Kirk": "James Tiberius", "Picard": "Jean-Luc"}
)
```

### 5.3 Size Hints

Preallocate when final size is known (e.g., converting between map and slice). Most code doesn't need it — let the runtime grow as necessary.

```go
buf := make([]byte, 131072)         // known buffer size
q := make([]Node, 0, 16)            // typical capacity
seen := make(map[string]bool, n)    // known element count
```

### 5.4 Channel Direction

Specify channel direction where possible to prevent programming errors:

```go
// Good — read-only channel
func sum(values <-chan int) int {
    for v := range values {
        out += v
    }
    return out
}

// Bad — could accidentally close a receive-only channel
func sum(values chan int) int { ... close(values) }
```

---

## 6. Function Argument Lists

Don't let function signatures get too long. Use one of two strategies.

### 6.1 Option Structure

Use a struct for configurable parameters when most callers need most options:

```go
type ReplicationOptions struct {
    Config              *replicator.Config
    PrimaryRegions      []string
    ReadonlyRegions     []string
    ReplicateExisting   bool
    OverwritePolicies   bool
    ReplicationInterval time.Duration
    CopyWorkers         int
    HealthWatcher       health.Watcher
}

func EnableReplication(ctx context.Context, opts ReplicationOptions) { ... }
```

Benefits: Self-documenting, easy to add fields, defaults by omission.

### 6.2 Variadic Options (Functional Options)

Use when most callers need **few or no** options:

```go
type replicationOptions struct { /* unexported fields */ }
type ReplicationOption func(*replicationOptions)

func ReadonlyCells(cells ...string) ReplicationOption {
    return func(opts *replicationOptions) {
        opts.readonlyCells = append(opts.readonlyCells, cells...)
    }
}

func EnableReplication(ctx context.Context, config *placer.Config,
    primaryCells []string, opts ...ReplicationOption) { ... }
```

Benefits: No-arg callers pass nothing; callers with needs compose what they want.

**Prefer option structure** when: all callers specify multiple options, options are shared between functions.

**Prefer variadic options** when: most callers specify none, options are many but rarely used.

---

## 7. Tests

### 7.1 Test Helpers vs Assertion Helpers

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

### 7.2 `t.Error` vs `t.Fatal`

| Scenario | Use |
|---|---|
| Test setup failure (can't proceed at all) | `t.Fatal` |
| Single table entry failure (not using subtests) | `t.Error` + `continue` |
| Single subtest failure (inside `t.Run`) | `t.Fatal` (ends the subtest only) |

### 7.3 Don't Call `t.Fatal` from Separate Goroutines

Only the test goroutine can call `t.Fatal`. Use `t.Error` from goroutines:

```go
go func() {
    if err := engine.Vroom(); err != nil {
        t.Errorf("No vroom left on engine: %v", err) // NOT t.Fatalf
        return
    }
}()
```

### 7.4 Keep Setup Scoped

Call setup functions explicitly in tests that need them, not in a global `init`:

```go
// Good — only tests that need the dataset pay the cost
func TestParseData(t *testing.T) {
    data := mustLoadDataset(t) // expensive call
    // ...
}

func TestRegression682831(t *testing.T) {
    // No dataset needed — fast test
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

### 7.5 Use Real Transports

When testing integrations with HTTP/RPC, use real clients connected to test servers — don't hand-implement clients.

### 7.6 Field Names in Test Literals

Specify field names in table-driven tests, especially with many fields or adjacent same-type fields:

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
    {
        slice:     []string{"a", "b", ""},
        separator: ",",
        skipEmpty: true,
        want:      "a,b",
    },
}
```

### 7.7 Use `t.Context()` (Go 1.24+)

Always use `t.Context()` for test contexts instead of `context.WithCancel(context.Background())`.

---

## 8. String Concatenation

| Method | When to use |
|---|---|
| `+` operator | Concatenating few strings. Simplest, no import. |
| `fmt.Sprintf` | Building complex strings with formatting. |
| `strings.Builder` | Building strings bit-by-bit in a loop. |
| `text/template` | Complex formatting with templates. |
| `fmt.Fprintf` | Writing directly to an `io.Writer` (no temporary string). |

```go
// + for simple
key := "projectid: " + p

// fmt.Sprintf for formatting
str := fmt.Sprintf("%s [%s:%d]-> %s", src, qos, mtu, dst)

// strings.Builder for piecemeal
b := new(strings.Builder)
for i, d := range digitsOfPi {
    fmt.Fprintf(b, "the %d digit of pi is: %d\n", i, d)
}
str := b.String()

// Backticks for constant multi-line
usage := `Usage:

custom_tool [args]`
```

---

## 9. Global State

Libraries must not force clients to rely on global/package-level state. Allow clients to create and use instance values:

```go
// Good — clients create instances
package sidecar

type Registry struct { plugins map[string]*Plugin }
func New() *Registry { return &Registry{plugins: make(map[string]*Plugin)} }
func (r *Registry) Register(name string, p *Plugin) error { ... }

// Bad — global state forces fragile, order-dependent tests
package sidecar
var registry = make(map[string]*Plugin)
func Register(name string, p *Plugin) error { ... }
```

Global state causes:
- Order-dependent test failures
- Tests cannot run in parallel
- Broken with test filters/sharding
- Hidden coupling across tests
