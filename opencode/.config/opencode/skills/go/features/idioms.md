# Go Idioms

Use these patterns when they fit the API's ownership, lifecycle, and compatibility requirements. Prefer the repository's established conventions for public APIs.

## Interfaces and receivers

Pass interface values, not pointers to interfaces. A pointer to an interface is rarely the intended abstraction.

```go
func Copy(dst io.Writer, src io.Reader) error
```

Define interfaces at the consuming boundary when that improves substitutability or testing. Returning a concrete type is often useful, but return an interface when the abstraction itself is the stable contract.

Use compile-time assertions when interface conformance is a deliberate part of a type's contract:

```go
var _ http.Handler = (*Handler)(nil)
```

Choose pointer receivers when methods mutate the receiver, copying is undesirable, or the type's method set requires them. Remember that `*T` has methods with both value and pointer receivers, while `T` does not have pointer-receiver methods.

## Mutexes and shared state

`sync.Mutex` and `sync.RWMutex` have usable zero values. Keep a mutex close to the data it protects and avoid copying a value after its first use.

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

A named, unexported mutex field usually gives a clearer API than embedding one. Do not expose a lock as part of a public type's contract unless callers are intentionally expected to coordinate through it.

## Slices, maps, and ownership

Decide whether a slice or map is borrowed, transferred, or copied at each API boundary. Copy it when the caller must not mutate retained state, when returned data must be isolated, or when concurrent access would otherwise race. Avoid defensive copies when ownership and lifetime are already clear and the allocation would be material.

For Go 1.21+, `slices.Clone` and `maps.Clone` make this explicit; use `copy` or a loop when targeting an earlier release.

```go
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = slices.Clone(trips)
}

func (s *Stats) Snapshot() map[string]int {
    s.mu.Lock()
    defer s.mu.Unlock()
    return maps.Clone(s.counters)
}
```

A nil slice is ready for `append`, has length zero, and ranges safely. Select `nil` or an allocated empty slice based on the API's encoding and compatibility contract; callers should usually test `len(s) == 0`.

Use capacity hints only when a measured or known size makes them worthwhile.

## `defer` and resource lifetime

Use `defer` to keep cleanup adjacent to successful acquisition when the cleanup should occur on function exit. In loops that acquire many resources, scope each iteration in a helper or close resources explicitly so they are released before the surrounding function returns.

```go
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

Arguments to an ordinary deferred call are evaluated when `defer` executes. A deferred closure reads captured variables when the closure runs.

```go
status := "starting"
defer func() { log.Printf("status: %s", status) }()
status = "finished"
```

## Channels and goroutines

Choose channel capacity from the required synchronization, burst tolerance, and backpressure behavior. An unbuffered channel synchronizes sender and receiver; a buffer of one is useful for a one-result handoff, not a universal default.

Expose directional channel types when a function only sends or receives.

Every goroutine needs an owner, a completion path, and a shutdown or cancellation strategy where it can outlive its caller. Wait for goroutines when their results, cleanup, or test completion depend on them. Use leak detection only when it is compatible with the repository's test setup.

```go
ctx, cancel := context.WithCancel(parent)
defer cancel()

done := make(chan struct{})
go func() {
    defer close(done)
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            flush()
        }
    }
}()

cancel()
<-done
```

## Enums, atomics, and embedding

Design the zero value intentionally. Start an enum at `iota + 1` when zero should mean invalid or unset; start at zero when it is the natural default.

For Go 1.19+, prefer the standard-library typed atomics (`atomic.Bool`, `atomic.Int64`, and related types) for simple atomic state. Use the function-based `sync/atomic` API for earlier releases. Use a mutex or another synchronization design when operations span multiple fields or require invariants.

Embed a type only when promoting its methods is part of the intended API. Avoid embedding synchronization primitives in exported types, and consider composition when embedding would leak implementation details.

## Initialization, assertions, exits, and panics

Avoid `init` when ordinary initialization makes dependencies and failures clearer. If it is needed, keep it deterministic and free from unexpected I/O or goroutines.

Use the comma-`ok` assertion when a dynamic type mismatch is an expected or externally influenced condition. A direct assertion is appropriate only when a violated internal invariant should fail immediately.

Libraries should return errors rather than terminate the process. Executable entry points may turn a final error into logging and an exit status. `os.Exit` and `log.Fatal` skip deferred cleanup, so perform required cleanup before using them.

Use panic for broken internal invariants or explicitly documented programmer misuse, not ordinary runtime failures. Recover only at a deliberately chosen containment boundary and re-panic unexpected values.
