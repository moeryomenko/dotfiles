# Go Error Handling

## Core Principles

- Return errors, don't panic.
- Give errors structure so callers can interrogate them programmatically.
- Handle errors once — do NOT log + return the same error.

## Error Types Decision Table

| Need matching? | Message type | Tool |
|---|---|---|
| No | Static | `errors.New` |
| No | Dynamic | `fmt.Errorf` |
| Yes | Static | `var ErrX = errors.New(...)` |
| Yes | Dynamic | Custom error type (implement `Error() string`) |

```go
// Sentinel error (static, matchable)
var ErrCouldNotOpen = errors.New("could not open")

// Dynamic, matchable
type NotFoundError struct { File string }
func (e *NotFoundError) Error() string {
    return fmt.Sprintf("file %q not found", e.File)
}
```

## Error Wrapping

### `%w` vs `%v`

| Verb | When to use |
|---|---|
| `%w` | Callers inspect with `errors.Is`/`errors.As`; documented API contract |
| `%v` | Adding context; creating fresh errors at system boundaries; hiding implementation details |

```go
// %w: caller expected to inspect the chain
return fmt.Errorf("new store: %w", err)

// %v: at system boundary, translate to canonical error
return nil, fmt.Errorf("couldn't find database: %v", err)
```

### Placement of `%w`

Prefer placing `%w` at the **end** so error text mirrors chain order (newest-to-oldest):

```go
// Good — error text mirrors chain: err3: err2: err1
err1 := fmt.Errorf("err1")
err2 := fmt.Errorf("err2: %w", err1)
err3 := fmt.Errorf("err3: %w", err2)

// Exception: sentinel errors placing %w at the beginning so category is visible
return fmt.Errorf("%w: invalid header: %v", ErrParseInvalidHeader, err)
```

### Keep Context Succinct

```go
// Good
return fmt.Errorf("new store: %w", err)

// Bad — redundant with wrapped error
return fmt.Errorf("failed to create new store: %w", err)
```

## Error Matching

```go
// Bad — string matching is fragile
if regexp.MatchString(`duplicate`, err.Error()) { ... }

// Good — use errors.Is/errors.As
if errors.Is(err, os.ErrNotExist) { ... }

var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Println(pathErr.Path)
}
```

## Error Naming

- Exported error vars: `ErrXxx`
- Unexported error vars: `errXxx`
- Custom error types: `XxxError` (exported), `xxxError` (unexported)

## Handling Errors Once

```go
// Bad: log + return (logspam, caller double-handles)
u, err := getUser(id)
if err != nil {
    log.Printf("could not get user %q: %v", id, err)
    return err
}

// Good: wrap and let caller decide
u, err := getUser(id)
if err != nil {
    return fmt.Errorf("get user %q: %w", id, err)
}

// Good: match specific error, degrade gracefully
tz, err := getUserTimeZone(id)
if err != nil {
    if errors.Is(err, ErrUserNotFound) {
        tz = time.UTC // Degrade gracefully
    } else {
        return fmt.Errorf("get user %q: %w", id, err)
    }
}
```

## Panics and Program Checks

- Standard error handling: return errors, don't panic.
- Use `log.Fatal` (not `panic`) for unrecoverable invariant violations.
- **Don't recover panics to avoid crashes** — corrupted state can cause worse problems.
- Exception: panic as internal mechanism in tightly coupled code, recovered at public API boundary:

```go
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
- API misuse (caught in code review/tests).
- Unreachable code detection.
- Package initialization (before flags are parsed).

## Logging Errors

- **Don't log + return**: Let caller decide. Avoids logspam.
- `log.Error` is expensive (causes flush). Use sparingly.
- ERROR should be **actionable**, not just "more serious" than WARNING.
- **Verbose logging**: Guard expensive calls:

```go
// Good — sql.Explain not called unless V(2) enabled
if log.V(2) {
    log.Infof("Handling %v", sql.Explain())
}

// Bad — sql.Explain called even when not logged
log.V(2).Infof("Handling %v", sql.Explain())
```

## Mutable Globals

Avoid mutable globals. Use dependency injection:

```go
// Bad
var _timeNow = time.Now
func sign(msg string) string { return signWithTime(msg, _timeNow()) }

// Good
type signer struct { now func() time.Time }
func (s *signer) Sign(msg string) string { return signWithTime(msg, s.now()) }
```

Libraries must not force clients to rely on global/package-level state:

```go
// Good — clients create instances
type Registry struct { plugins map[string]*Plugin }
func New() *Registry { return &Registry{plugins: make(map[string]*Plugin)} }

// Bad — global state, order-dependent tests
var registry = make(map[string]*Plugin)
func Register(name string, p *Plugin) error { ... }
```

## String Concatenation

| Method | When to use |
|---|---|
| `+` operator | Few strings, simplest |
| `fmt.Sprintf` | Complex formatting |
| `strings.Builder` | Building bit-by-bit in a loop |
| `text/template` | Complex templating |
| `fmt.Fprintf` | Writing directly to `io.Writer` |

## Cross-References

- For zero values and error types: load `style`
- For panic/recover patterns: load `idioms`
- For testing error scenarios: load `testing`
- For linter configuration: load `linter-guide`
