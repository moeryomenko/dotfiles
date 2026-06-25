# Go Idioms

Common Go patterns for slices, maps, structs, defer, channels, goroutines, enums, and concurrency.

## Interfaces

### Pointers to Interfaces
Never use a pointer to an interface. Pass interfaces as values:

```go
// Bad
func F(w *io.Writer) {}

// Good
func F(w io.Writer) {}
```

### Verify Interface Compliance
Use compile-time assertions:

```go
var _ http.Handler = (*Handler)(nil)   // pointer types: nil
var _ http.Handler = LogHandler{}      // struct types: empty struct
```

### Receivers and Interfaces
- Methods with **value receivers** can be called on pointers AND values.
- Methods with **pointer receivers** can only be called on pointers or addressable values.
- A pointer type satisfies an interface even if the method has a value receiver.
- A value type does NOT satisfy an interface if the method has a pointer receiver.

### Accept Interfaces, Return Structs
Functions should accept interfaces and return concrete types. This keeps callers flexible while ensuring return values are usable without unwrapping.

## Mutexes

### Zero-value Mutexes
`sync.Mutex` and `sync.RWMutex` zero values are valid. Do not use pointers:

```go
// Bad
mu := new(sync.Mutex)

// Good
var mu sync.Mutex
```

### Do Not Embed Mutexes
Use a named field to keep it private:

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

### Define Mutex with Guarded Data
Keep mutex and the data it guards close together:

```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}
```

## Slices and Maps

### Copy at Boundaries
When receiving slices/maps from callers or exposing them, always copy to prevent aliasing:

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

### nil is a Valid Slice
- Return `nil` instead of `[]int{}` for empty slices.
- Check `len(s) == 0`, not `s == nil`.
- Zero-value slice `var s []T` is ready for `append`.

### Map and Slice Initialization
```go
m := make(map[string]os.DirEntry, len(files)) // Capacity hint when known
m := map[string]int{"a": 1, "b": 2}           // Fixed elements
data := make([]int, 0, size)                  // Pre-allocate capacity
```

## Defer

Always use `defer` for cleanup. Overhead is negligible:

```go
p.Lock()
defer p.Unlock()

f, err := os.Open(path)
if err != nil { return err }
defer f.Close()

// Defer evaluation: arguments are evaluated immediately
// Use closure for deferred value access
func doSomething() error {
    var status string
    defer func() {
        log.Printf("status: %s", status) // Evaluated at defer time
    }()
    status = "started"
    // ...
    status = "finished"
    return nil
}
```

## Channels

Channels should have size **one** or be **unbuffered**. Larger buffers need strong justification:

```go
c := make(chan int, 1)  // buffered with size 1
c := make(chan int)     // unbuffered
```

Specify channel direction where possible:

```go
func sum(values <-chan int) int {     // receive-only
    for v := range values {
        out += v
    }
    return out
}
```

## Goroutines

- Every goroutine must have a predictable stop time or a way to signal it to stop.
- There must be a way to wait for the goroutine to finish.
- No goroutines in `init()`.
- Use `go.uber.org/goleak` to test for goroutine leaks.

```go
stop := make(chan struct{})
done := make(chan struct{})
go func() {
    defer close(done)
    for {
        select {
        case <-ticker.C:
            flush()
        case <-stop:
            return
        }
    }
}()
close(stop)
<-done
```

## Enums

Start enums at one using `iota + 1` unless zero-value is the desired default:

```go
type Operation int

const (
    Add Operation = iota + 1
    Subtract
    Multiply
)
```

## Atomics

Prefer `go.uber.org/atomic` or Go 1.19+ stdlib atomic types for type-safe operations:

```go
type Server struct {
    running atomic.Bool
}

func (s *Server) Start() {
    if s.running.Swap(true) {
        return // Already running
    }
    // Start logic
}

func (s *Server) IsRunning() bool {
    return s.running.Load()
}
```

## Embedding

- Do NOT embed types in public structs (leaks implementation details).
- Embedded types must be at the top of struct fields.
- Do NOT embed `sync.Mutex`.
- Embed consciously: "would all exported inner methods be added directly?"

```go
// Good embedding: adds value
type countingWriteCloser struct {
    io.WriteCloser
    count int
}
```

## Built-in Names

Never shadow predeclared identifiers:

```go
// Bad
var error string

// Good
var errorMessage string
```

## init() Functions

Avoid `init()`. When unavoidable: be deterministic, avoid I/O, prefer `var X = fn()`.

## Exit in Main

- Call `os.Exit` or `log.Fatal` ONLY in `main()`.
- Delegate to a `run()` function that returns an error.

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

## Type Assertions

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

## Panics

- Return errors, don't panic.
- Panic only for irrecoverable situations.
- In tests, use `t.Fatal` / `t.FailNow`, not `panic`.

## Cross-References

- For naming conventions and formatting: load `style`
- For error patterns: load `error-handling`
- For modern Go features: load `modern-features`
- For linter configuration: load `linter-guide`
