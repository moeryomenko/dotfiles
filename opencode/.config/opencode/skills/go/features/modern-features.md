# Modern Go Features

Start with the module's `go` directive and selected toolchain. A newer local compiler does not make a language feature or standard-library API available to a module targeting an older Go release. Adopt newer APIs when they improve the code's contract or readability; they are not mandatory migrations.

## Go 1.24

### `testing.T.Context`

`T.Context` provides a context canceled when the test completes. Use it for test-owned work; derive a context when the code requires an independent lifetime or cancellation policy.

```go
func TestWorker(t *testing.T) {
    ctx := t.Context()
    _ = ctx
}
```

### Generic type aliases

Generic type aliases are supported by Go 1.24.

```go
type Set[T comparable] = map[T]struct{}
```

### `encoding/json` `omitzero`

Use `omitzero` when a JSON field should be omitted according to its Go zero value, including a type's `IsZero() bool` method when applicable.

```go
type User struct {
    Name string `json:"name,omitzero"`
}
```

## Go 1.23

### Iteration

Go 1.23 adds range-over-function iteration and the `iter` package. Return an iterator when lazy traversal or early termination is valuable; a slice remains clearer for small, already-materialized results.

```go
func All(values []string) iter.Seq[string] {
    return func(yield func(string) bool) {
        for _, value := range values {
            if !yield(value) {
                return
            }
        }
    }
}

for value := range All(values) {
    fmt.Println(value)
}
```

`maps.Keys` and `maps.Values` became iterator-based in Go 1.23. Collect them when a slice is required:

```go
keys := slices.Collect(maps.Keys(m))
```

### `unique`

`unique.Make` provides canonicalized comparable values. Use it only when identity sharing or its comparison behavior benefits the design.

## Go 1.22

### Per-iteration variables

For modules declaring Go 1.22 or later, `for` iteration variables are distinct per iteration. Closures therefore capture the iteration's value rather than a single reused variable. This does not remove ordinary data-race or lifetime concerns.

```go
for _, value := range values {
    go func() { fmt.Println(value) }()
}
```

Do not remove compatibility copies from a module that still targets an earlier language version without reviewing its build matrix.

### `cmp.Or`

`cmp.Or` returns the first non-zero value.

```go
name := cmp.Or(user.Name, "anonymous")
```

### Other options

Go 1.22 includes method-and-wildcard patterns in `http.ServeMux`, `Request.PathValue`, range over integers, and `math/rand/v2`. Choose them when their behavior is appropriate and supported by the module.

```go
mux.HandleFunc("GET /users/{id}", handler)
for i := range 10 {
    fmt.Println(i)
}
```

## Go 1.21

### `slices`, `maps`, and `cmp`

These packages express common operations clearly when the module targets Go 1.21 or later.

```go
clone := slices.Clone(values)
slices.SortFunc(users, func(a, b User) int {
    return cmp.Compare(a.Age, b.Age)
})
slices.SortStableFunc(users, func(a, b User) int {
    return cmp.Compare(a.Name, b.Name)
})

copyOfMap := maps.Clone(m)
maps.Copy(dst, src)
```

In Go 1.21 and 1.22, `maps.Keys(m)` and `maps.Values(m)` return slices. In Go 1.23+, they return iterators; use `slices.Collect` when materialization is needed.

### `log/slog` and contexts

`log/slog` offers structured logging. Adopt it when it fits the repository's logging interface and operational conventions; avoid mixing logging systems without a migration plan.

Go 1.21 also adds `context.WithCancelCause`, `context.Cause`, and `context.AfterFunc` for code that needs those semantics.

### Built-ins

`min`, `max`, and `clear` are available in Go 1.21.

```go
limit := min(requested, maximum)
clear(cache)
```

## Go 1.20 and earlier notable additions

- Go 1.20: `errors.Join`, `http.ResponseController`, `strings.CutPrefix`, and `strings.CutSuffix`.
- Go 1.19: typed atomic values such as `atomic.Int64` and `atomic.Bool`.
- Go 1.18: generics, `any`, and `net/netip`.

Use these when they make the intent clearer or provide semantics the older alternative cannot. For example, `netip.Addr` is often a stronger value type than `net.IP`, but changing a public API requires a compatibility decision.
