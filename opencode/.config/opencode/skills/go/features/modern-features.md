# Modern Go Features

Go features organized by version. Detect Go version from `go.mod`.

## Go 1.24

### `t.Context()` in Tests
```go
func TestFoo(t *testing.T) {
    ctx := t.Context() // cancellable on test timeout, replaces context.Background()
}
```

### Generic Type Alias (spec but not yet in go.mod)
```go
type Set[T comparable] = map[T]struct{}
```

### `omitzero` Struct Tag (encoding/json)
```go
type User struct {
    Name string `json:"name,omitzero"` // omit zero-value fields
}
```

## Go 1.23

### `iter` package (range-over-func)

Forward iterator type: `func(func(K, V) bool)`

```go
import "iter"

func All(ctx context.Context) iter.Seq[Result] {
    return func(yield func(Result) bool) {
        for _, r := range results {
            if !yield(r) { return }
        }
    }
}

for r := range All(ctx) {
    fmt.Println(r)
}
```

### `unique` package
Canonicalize values. Use `unique.Make(value)`.

### `cmp.Or`
Returns first non-zero value: `cmp.Or(s.Name, "default")`

## Go 1.22

### For loop variable fix
Loop variables no longer escape iteration — no more `v := v` copies:

```go
// Go 1.22+ — no bug
for _, v := range slice {
    go func() { fmt.Println(v) }()
}
```

### `math/rand/v2`
New API, faster, better seeding. Replace `math/rand`:

```go
import "math/rand/v2"
n := rand.IntN(100) // replaces rand.Intn(100)
```

### `http.ServeMux` with method patterns
```go
mux.HandleFunc("GET /api/users/{id}", handler) // path params
id := r.PathValue("id")                        // extract param
```

### `range` over int
```go
for i := range 10 { fmt.Println(i) } // 0..9
```

## Go 1.21

### `slices` package

```go
import "slices"

slices.Clone(s)
slices.Compact(s)              // remove adjacent duplicates
slices.Contains(s, v)
slices.Delete(s, i, j)
slices.Equal(s1, s2)
slices.Index(s, v)
slices.Insert(s, i, vs...)
slices.IsSorted(s)
slices.Max(s), slices.Min(s)
slices.Replace(s, i, j, vs...)
slices.Reverse(s)
slices.Sort(s)                 // sorts in place
slices.SortFunc(s, func(a,b T) int { return cmp.Compare(a.Age, b.Age) })
slices.SortStableFunc(s, cmp)
```

### `maps` package

```go
import "maps"

maps.Clone(m)                  // shallow clone
maps.Copy(m1, m2)              // copy entries from m2 to m1
maps.DeleteFunc(m, func(k,v) bool { return v == 0 })
maps.Equal(m1, m2)             // deep equality
maps.Keys(m)                   // returns keys as slice
maps.Values(m)                 // returns values as slice
```

### `cmp` package

```go
import "cmp"

cmp.Compare(a, b)          // -1, 0, 1
cmp.Less(a, b)             // bool
cmp.Or(a, b, ...)          // first non-zero value
```

### `log/slog`
Structured logging:

```go
import "log/slog"

slog.Info("user created", "id", userID, "role", role)
slog.Warn("rate limit", "ip", ip, "count", n)
slog.Error("request failed", "err", err, "status", 500)

// Custom logger
logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
slog.SetDefault(logger)
```

### `context` improvements

- `context.AfterFunc(ctx, f)` — run f when ctx is done
- `context.WithCancelCause(ctx)` — cancel with a cause (retrieve via `context.Cause(ctx)`)

### `max`, `min`, `clear` built-ins

```go
max(1, 2, 3)      // 3
min(-1, 0, 1)     // -1
clear(m)          // delete all map entries
clear(slice)      // zero all elements
```

## Go 1.20

### `errors.Join`
Multiple errors into one:

```go
if err1 != nil || err2 != nil {
    return errors.Join(err1, err2)
}
```

### `http.ResponseController`
Per-handler control over response writer:

```go
rc := http.NewResponseController(w)
rc.SetWriteDeadline(time.Now().Add(5 * time.Second))
rc.Flush()
```

### `bytes`, `strings` prefix/suffix checking
`CutPrefix`, `CutSuffix` for clean prefix removal:

```go
// Before
if strings.HasPrefix(s, "http://") {
    s = strings.TrimPrefix(s, "http://")
}

// After
s, found := strings.CutPrefix(s, "http://")
```

## Go 1.19

### `sync` atomic types

```go
var counter atomic.Int64
counter.Add(1)
n := counter.Load()

var running atomic.Bool
running.Store(true)
running.Swap(false)
```

## Go 1.18

### Generics

```go
// Generic function
func Map[T, U any](s []T, f func(T) U) []U {
    result := make([]U, len(s))
    for i, v := range s { result[i] = f(v) }
    return result
}

// Generic type
type Stack[T any] struct {
    items []T
}

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

// Constraint interface
type Number interface {
    ~int | ~float64
}

func Sum[T Number](values []T) T {
    var sum T
    for _, v := range values { sum += v }
    return sum
}
```

### `net/netip`
New IP address type: `netip.Addr`, `netip.Prefix`. Prefer over `net.IP`.

### `any` alias
`any = interface{}`. Prefer `any` in new code.

## Migration Guide

| Old Pattern | New Pattern | Since |
|---|---|---|
| `context.Background()` in tests | `t.Context()` | 1.24 |
| `math/rand.Intn(n)` | `math/rand/v2.IntN(n)` | 1.22 |
| Loop var copy `v := v` | Remove copy | 1.22 |
| Manual slice ops | `slices` package | 1.21 |
| Manual map ops | `maps` package | 1.21 |
| `*log.Logger` | `log/slog` | 1.21 |
| `interface{}` | `any` | 1.18 |
| `net.IP` | `netip.Addr` | 1.18 |
| `strings.TrimPrefix` | `strings.CutPrefix` (cleaner) | 1.20 |

## Cross-References

- For `slices`, `maps` usage in idiomatic code: load `idioms`
- For `t.Context()` and testing patterns: load `testing`
- For linting modern usage: load `linter-guide`
