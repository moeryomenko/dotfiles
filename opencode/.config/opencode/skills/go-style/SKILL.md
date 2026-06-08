---
name: go-style
description: Comprehensive Go coding style guide synthesizing Google Go Style Guide and Uber Go Style Guide. Use when writing, reviewing, or refactoring Go code for naming conventions, declarations, error handling, concurrency patterns, and struct/map/slice idioms.
---

# Go Style Guide

## Style Principles

The following attributes of readable code are listed in order of importance (Google):

1. **[Clarity](#clarity)**: The code's purpose and rationale is clear to the reader.
2. **[Simplicity](#simplicity)**: The code accomplishes its goal in the simplest way possible.
3. **[Concision](#concision)**: The code has a high signal-to-noise ratio.
4. **[Maintainability](#maintainability)**: The code is written such that it can be easily maintained.
5. **[Consistency](#consistency)**: The code is consistent with the broader codebase.

### Clarity

Clarity is viewed through the lens of the **reader**, not the author. Two facets:

- **What** is the code doing? Use descriptive names, commentary, whitespace, and modularization.
- **Why** is it doing it? Explain nuances (business logic, performance tricks) that aren't obvious.

Let the code speak for itself. Prefer self-describing names over redundant comments. Comments should explain **why**, not **what**.

```go
// Good: explains rationale (why), not mechanics (what)
// Gregorian leap years aren't just year%4 == 0.
var (
    leap4   = year%4 == 0
    leap100 = year%100 == 0
    leap400 = year%400 == 0
)
leap := leap4 && (!leap100 || leap400)

// Bad: states the obvious
// Check if year is a leap year
leap := (year%4 == 0) && (!(year%100 == 0) || (year%400 == 0))
```

### Simplicity

Write Go code in the simplest way that accomplishes its goals. Simple code:

- Is easy to read top to bottom.
- Does not assume the reader can memorize preceding code.
- Does not have unnecessary levels of abstraction.
- Is often mutually exclusive with "clever" code.

**Least mechanism** (Google): Prefer the most standard tools. Core language constructs (channels, slices, maps, loops, structs) > standard library > external dependencies.

```go
// Good: simple map for set membership
seen := make(map[string]bool)

// Avoid set libraries unless complex operations needed
```

### Concision

High signal-to-noise ratio. Avoid repetitive code, extraneous syntax, opaque names, unnecessary abstraction.

Repetitive code obscures differences. Use table-driven tests to factor out common code.

When code looks nearly identical to a common idiom but is subtly different, intentionally "boost" the signal:

```go
// Good: calls attention to the subtle difference
if err := doSomething(); err == nil { // if NO error
    // ...
}
```

### Maintainability

Code is edited more times than it is written. Maintainable code:

- Is easy for future programmers to modify correctly.
- Has APIs that grow gracefully.
- Makes assumptions explicit.
- Avoids unnecessary coupling.
- Has a comprehensive test suite with actionable diagnostics.

Interfaces remove information — use them only when they provide sufficient benefit. A concrete type lets editors connect directly to method definitions; an interface requires the maintainer to understand the underlying implementation.

Predictable names matter: function parameters and receiver names for identical concepts should share the same name across the codebase.

### Consistency

Consistent code looks, feels, and behaves like similar code throughout the codebase.

**Local consistency** (Google): Where the guide has nothing to say, authors are free to choose, unless code in close proximity takes a consistent stance.

- **Valid** local style: `%s` vs `%v` for error formatting; buffered channels vs mutexes.
- **Invalid** local style: line length restrictions; assertion-based testing libraries (not standard in Go).

If a change would **worsen** an existing deviation, expose it in more API surfaces, or introduce a bug, then local consistency is no longer valid justification.

---

## Core Guidelines

### Formatting

- All Go source files must conform to `gofmt` output. (Google mandate, enforced by presubmit.)
- There is **no fixed line length** for Go source (Google). Prefer refactoring over line splitting.
  - Uber recommends a soft limit of 99 characters, but this is not a hard rule.
- Do NOT split a line before an indentation change (function declaration, conditional) or to make a long string fit.

### MixedCaps

Go source uses `MixedCaps` or `mixedCaps` (camelCase), not underscores (snake_case), for multi-word names (Google).

```go
// Good
const MaxLength = 100     // exported
var maxLength = 50        // unexported
localVar := "example"     // local (treated as unexported)

// Bad
const MAX_LENGTH = 100
var max_length = 50
```

### Naming (Google Philosophy)

Naming is more art than science. Names should:

- **Not feel repetitive when used**: `Count` not `CountEntries`, especially if the type is already `Entries`.
- **Take context into consideration**: A method on `User` can be `ID()` not `UserID()`.
- **Not repeat concepts already clear**: `ch := make(chan int)` not `channel := make(chan int)`.

Predictable names enable maintainability. If a developer can guess the name of a method or variable in a given context, the code is well-named.

## Guidelines

### 1. Interfaces

#### 1.1 Pointers to Interfaces
Never use a pointer to an interface. Pass interfaces as values; the underlying data can still be a pointer.

```go
// Bad
func F(w *io.Writer) {}

// Good
func F(w io.Writer) {}
```

#### 1.2 Verify Interface Compliance
Use compile-time assertions to verify interface compliance:

```go
var _ http.Handler = (*Handler)(nil)   // pointer types: nil
var _ http.Handler = LogHandler{}      // struct types: empty struct
```

Add these right after the type declaration.

#### 1.3 Receivers and Interfaces
- Methods with **value receivers** can be called on pointers AND values.
- Methods with **pointer receivers** can only be called on pointers or addressable values.
- A pointer type satisfies an interface even if the method has a value receiver.
- A value type does NOT satisfy an interface if the method has a pointer receiver.

### 2. Mutexes

#### 2.1 Zero-value Mutexes
`sync.Mutex` and `sync.RWMutex` zero values are valid. Do not use pointers.

```go
// Bad
mu := new(sync.Mutex)

// Good
var mu sync.Mutex
```

#### 2.2 Do Not Embed Mutexes
Never embed `sync.Mutex` in structs. Use a named field to keep it private.

```go
// Bad
type SMap struct {
    sync.Mutex
    data map[string]string
}

// Good
type SMap struct {
    mu   sync.Mutex
    data map[string]string
}
```

### 3. Slices and Maps

#### 3.1 Copy at Boundaries
When receiving slices/maps from callers or exposing them, always copy to prevent aliasing.

```go
// Receiving: copy into new allocation
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = make([]Trip, len(trips))
    copy(d.trips, trips)
}

// Returning: copy before exposing
func (s *Stats) Snapshot() map[string]int {
    s.mu.Lock()
    defer s.mu.Unlock()
    result := make(map[string]int, len(s.counters))
    for k, v := range s.counters {
        result[k] = v
    }
    return result
}
```

#### 3.2 nil is a Valid Slice
- Return `nil` instead of `[]int{}` for empty slices.
- Check `len(s) == 0`, not `s == nil`.
- Zero-value slice `var s []T` is ready for `append`.

#### 3.3 Map Initialization
- Use `make(map[T1]T2)` for empty/programmatic maps.
- Use map literals for fixed element sets.
- Always provide capacity hints when known.

```go
// Empty + programmatic
m := make(map[string]os.DirEntry, len(files))

// Fixed elements
m := map[string]int{"a": 1, "b": 2}
```

#### 3.4 Slice Capacity
Pre-allocate slice capacity when length is known:

```go
data := make([]int, 0, size)  // Good
data := make([]int, 0)  // Bad when size is known
```

### 4. Defer

Always use `defer` for cleanup (locks, files). The overhead is negligible.

```go
p.Lock()
defer p.Unlock()
// ...
```

### 5. Channels

Channels should have size **one** or be **unbuffered**. Larger buffers need strong justification.

```go
c := make(chan int, 1)  // buffered with size 1
c := make(chan int)     // unbuffered
```

### 6. Enums

Start enums at one using `iota + 1` unless zero-value is the desired default.

```go
type Operation int

const (
    Add Operation = iota + 1
    Subtract
    Multiply
)
```

### 7. Time Handling

- Use `time.Time` for instants, `time.Duration` for periods.
- Use `time.Time` methods: `Before`, `Equal`, `After`, `AddDate`, `Add`.
- Use `time.Since(t)` and `time.Until(t)` for elapsed/remaining time.
- Use `time.RFC3339` for timestamp serialization.
- Name fields with units when numeric: `IntervalMillis`, not `Interval`.

```go
func isActive(now, start, stop time.Time) bool {
    return (start.Before(now) || start.Equal(now)) && now.Before(stop)
}

func poll(delay time.Duration) { time.Sleep(delay) }
poll(10 * time.Second)
```

### 8. Error Handling

#### 8.1 Error Types — Decision Table
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

#### 8.2 Error Wrapping
- `%w`: Caller can match with `errors.Is`/`errors.As` (default for wrapped errors).
- `%v`: Caller cannot match. Use to hide implementation details.
- Keep context succinct: avoid "failed to" chains.

```go
// Good
return fmt.Errorf("new store: %w", err)

// Bad
return fmt.Errorf("failed to create new store: %w", err)
```

#### 8.3 Error Naming
- Exported error vars: `ErrXxx`
- Unexported error vars: `errXxx`
- Custom error types: `XxxError` (exported), `xxxError` (unexported)

#### 8.4 Handle Errors Once
- Do NOT log + return the same error (callers will handle).
- Either: log and degrade gracefully, OR wrap and return.
- If matching: match specific error, handle it, wrap+return everything else.

```go
// Bad: log + return
u, err := getUser(id)
if err != nil {
    log.Printf("could not get user %q: %v", id, err)
    return err
}

// Good: wrap and return
u, err := getUser(id)
if err != nil {
    return fmt.Errorf("get user %q: %w", id, err)
}

// Good: match specific, return others
tz, err := getUserTimeZone(id)
if err != nil {
    if errors.Is(err, ErrUserNotFound) {
        tz = time.UTC
    } else {
        return fmt.Errorf("get user %q: %w", id, err)
    }
}
```

### 9. Type Assertions

Always use the "comma ok" form:

```go
// Bad — panics
t := i.(string)

// Good
t, ok := i.(string)
if !ok {
    // handle gracefully
}
```

### 10. Panics

- Return errors, don't panic.
- Panic only for irrecoverable situations (nil dereference, program initialization).
- In tests, use `t.Fatal`/`t.FailNow`, not `panic`.

```go
// Good pattern
func run(args []string) error {
    if len(args) == 0 {
        return errors.New("an argument is required")
    }
    return nil
}

func main() {
    if err := run(os.Args[1:]); err != nil {
        log.Fatal(err)
    }
}
```

### 11. Atomics

Prefer `go.uber.org/atomic` for type-safe atomic operations:

```go
type foo struct {
    running atomic.Bool
}

func (f *foo) start() {
    if f.running.Swap(true) {
        return
    }
}

func (f *foo) isRunning() bool {
    return f.running.Load()
}
```

### 12. Mutable Globals

Avoid mutable globals. Use dependency injection instead.

```go
// Bad
var _timeNow = time.Now
func sign(msg string) string { return signWithTime(msg, _timeNow()) }

// Good
type signer struct { now func() time.Time }
func (s *signer) Sign(msg string) string { return signWithTime(msg, s.now()) }
```

### 13. Embedding

- Do NOT embed types in public structs (leaks implementation details).
- Embedded types must be at the top of struct fields with an empty line separator.
- Do NOT embed `sync.Mutex`.
- Embed consciously: "would all exported inner methods be added directly?"

```go
// Good embedding: adds value
type countingWriteCloser struct {
    io.WriteCloser
    count int
}

// Bad embedding: exposes internals
type A struct {
    sync.Mutex
}
```

### 14. Built-in Names

Never shadow predeclared identifiers (`error`, `string`, `int`, `len`, `make`, etc.):

```go
// Bad
var error string
func handleErrorMessage(error string) {}

// Good
var errorMessage string
func handleErrorMessage(msg string) {}
```

### 15. `init()` Functions

Avoid `init()`. When unavoidable:
- Be deterministic (no environment-dependent behavior).
- Do not depend on other `init()` ordering.
- Avoid I/O, network, filesystem calls.
- Prefer `var X = fn()` pattern over init.

### 16. Exit in Main

- Call `os.Exit` or `log.Fatal` ONLY in `main()`.
- Delegate business logic to a `run()` function that returns an error.
- Call `os.Exit` at most once in your program.

```go
func main() {
    if err := run(); err != nil {
        log.Fatal(err)
    }
}

func run() error {
    // business logic
}
```

### 17. Struct Tags

Always annotate marshaled struct fields with relevant tags (JSON, YAML, etc.):

```go
type Stock struct {
    Price int    `json:"price"`
    Name  string `json:"name"`
}
```

### 18. Goroutines

- Every goroutine must have a predictable stop time or a way to signal it to stop.
- There must be a way to wait for the goroutine to finish.
- No goroutines in `init()`.
- Use `go.uber.org/goleak` to test for goroutine leaks.
- Wait patterns: `sync.WaitGroup` for multiple, `chan struct{}` for single.

```go
// Good: signal + wait
stop := make(chan struct{})
done := make(chan struct{})
go func() {
    defer close(done)
    for {
        select {
        case <-ticker.C: flush()
        case <-stop: return
        }
    }
}()
close(stop)
<-done
```

## Performance

### 1. Prefer strconv over fmt
`strconv.Itoa` > `fmt.Sprint` for primitive conversions.

### 2. Avoid repeated string-to-byte
Convert once, reuse the result:
```go
data := []byte("Hello world")  // once
for i := 0; i < b.N; i++ {
    w.Write(data)
}
```

### 3. Prefer Specifying Container Capacity
Always provide capacity hints for `make(map[T1]T2, hint)` and `make([]T, 0, capacity)`.

## Style Rules

### Naming & Organization
| Rule | Guideline |
|---|---|
| Line length | No fixed limit (Google). Soft limit 99 chars (Uber). Refactor rather than split. |
| Case | `MixedCaps` / `mixedCaps` (camelCase), never snake_case |
| Package names | Lowercase, no underscores, not plural, not "util"/"common" |
| Function names | MixedCaps. Test functions may use underscores for grouping |
| Import groups | Stdlib first, separated by blank line |
| Group declarations | Group `const`, `var`, `type` declarations by relation |
| Function ordering | Rough call order, grouped by receiver, exported first |
| Unexported globals | Prefix with `_` (except error vars which use `err` prefix) |

### Code Structure
- **Reduce nesting**: Handle errors/special cases first, return early.
- **Unnecessary else**: Set default, override with if.
- **Local variables**: Use `:=` for explicit values; `var` for zero values.
- **Naked parameters**: Add `/* comment */` for unclear bool params; better yet, use custom types.
- **Raw strings**: Use backtick strings to avoid escaping.

### Struct Initialization
- Use field names (enforced by `go vet`).
- Omit zero-value fields.
- Use `var user User` for all-zero structs (not `User{}`).
- Use `&T{...}` for references (not `new(T)`).

### Format Strings
- Use `const` for format strings outside literals (enables `go vet`).
- Name Printf-style functions ending with `f`.

## Patterns

### Test Tables
- Use table-driven tests with subtests (`t.Run`).
- Name the table slice `tests`, each case `tt`.
- Prefix input/output with `give`/`want`.
- Keep test bodies simple — avoid conditional logic in loops.
- Splitting into separate test functions is better than complex table logic.

### Functional Options
Use for optional args in constructors (3+ optional params):

```go
type Option interface {
    apply(*options)
}

type options struct {
    cache  bool
    logger *zap.Logger
}

func WithCache(c bool) Option {
    return cacheOption(c)
}

func Open(addr string, opts ...Option) (*Connection, error) {
    options := options{cache: defaultCache, logger: zap.NewNop()}
    for _, o := range opts {
        o.apply(&options)
    }
    // ...
}
```

## Linting

Recommended base linter set:
- `errcheck` — errors handled
- `goimports` — formatting + imports
- `revive` — style mistakes (successor to golint)
- `govet` — common mistakes
- `staticcheck` — static analysis

Use `golangci-lint` as the lint runner.

## Core Differences: Google vs Uber on Line Length

| Aspect | Google Style Guide | Uber Style Guide |
|---|---|---|
| Line length | No fixed limit. Refactor rather than split. | Soft limit of 99 characters. |
| Philosophy | "If it feels too long, prefer refactoring instead of splitting it." | "We recommend a soft line length limit of 99 characters." |

When writing new code, prefer Google's approach: refactor overly long expressions into named variables or helper functions rather than mechanically splitting lines.
