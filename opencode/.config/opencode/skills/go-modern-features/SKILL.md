---
name: go-modern-features
description: Modern Go language features organized by Go version. Use when writing Go code to prefer modern built-ins and packages (slices, maps, cmp) over legacy patterns. Detects Go version from go.mod.
---

# Modern Go Features by Version

## Version Detection

Run this to detect the project's Go version:
```bash
grep -rh "^go " --include="go.mod" . 2>/dev/null | cut -d' ' -f2 | sort | uniq -c | sort -nr | head -1 | xargs | cut -d' ' -f2
```

When writing code, use ALL features up to the detected version. Never use features from newer versions or outdated patterns when modern alternatives exist.

---

## Go 1.13+

### Error Handling
- `errors.Is(err, target)` instead of `err == target`
- `errors.As(err, &target)` instead of type assertion on error

```go
// Before
if err == os.ErrNotExist { ... }

// After
if errors.Is(err, os.ErrNotExist) { ... }
```

---

## Go 1.18+

### Types
- `any` instead of `interface{}`

### Strings/Bytes
- `bytes.Cut`: `before, after, found := bytes.Cut(b, sep)` instead of Index+slice
- `strings.Cut`: `before, after, found := strings.Cut(s, sep)`

```go
// Before
idx := strings.IndexByte(s, ':')
if idx >= 0 {
    key, value := s[:idx], s[idx+1:]
}

// After
key, value, found := strings.Cut(s, ":")
```

---

## Go 1.19+

### Formatting
- `fmt.Appendf`: `buf = fmt.Appendf(buf, "x=%d", x)` instead of `[]byte(fmt.Sprintf(...))`

### Atomics (type-safe)
- `atomic.Bool`, `atomic.Int64`, `atomic.Pointer[T]` instead of raw `sync/atomic`

```go
var flag atomic.Bool
flag.Store(true)
if flag.Load() { ... }

var ptr atomic.Pointer[Config]
ptr.Store(cfg)
```

---

## Go 1.20+

### Strings/Bytes
- `strings.Clone(s)` / `bytes.Clone(b)` to copy without sharing memory
- `strings.CutPrefix(s, "pre:")` / `strings.CutSuffix(s, "suf")`

```go
if rest, ok := strings.CutPrefix(s, "prefix:"); ok { ... }
if rest, ok := strings.CutSuffix(s, ".txt"); ok { ... }
```

### Errors
- `errors.Join(err1, err2)` to combine multiple errors (works with `errors.Is`/`errors.As`)

### Context
- `context.WithCancelCause(parent)` / `context.Cause(ctx)` for cancellation reasons
- `cancel(err)` passes a reason, `context.Cause(ctx)` retrieves it

---

## Go 1.21+

### Built-ins
- `min(a, b)` / `max(a, b)` instead of if/else comparisons
- `clear(m)` to delete all map entries, `clear(s)` to zero slice elements

### slices package
| Function | Replaces |
|---|---|
| `slices.Contains(s, x)` | Manual search loop |
| `slices.Index(s, x)` | Manual index search |
| `slices.IndexFunc(s, f)` | Search by predicate |
| `slices.Sort(s)` | `sort.Slice` for ordered types |
| `slices.SortFunc(s, f)` | `sort.Slice` for custom ordering |
| `slices.Max(s)` / `slices.Min(s)` | Manual max/min loops |
| `slices.Reverse(s)` | Manual swap loop |
| `slices.Compact(s)` | Manual dedup loop |
| `slices.Clone(s)` | Manual copy |
| `slices.Clip(s)` | Remove unused capacity |

```go
// Before
found := false
for _, v := range items {
    if v == needle {
        found = true
        break
    }
}

// After
found := slices.Contains(items, needle)
```

### maps package
| Function | Replaces |
|---|---|
| `maps.Clone(m)` | Manual map iteration copy |
| `maps.Copy(dst, src)` | Manual copy entries |
| `maps.DeleteFunc(m, f)` | For-range + delete pattern |

```go
// Before
copy := make(map[string]int, len(m))
for k, v := range m { copy[k] = v }

// After
copy := maps.Clone(m)
```

### sync package
- `sync.OnceFunc(f)` — returns a function that runs `f` exactly once
- `sync.OnceValue(f)` — returns a function that returns the cached result of `f()`

```go
var GetConfig = sync.OnceValue(loadConfig)
```

### context package
- `context.AfterFunc(ctx, cleanup)` — runs cleanup when context is cancelled (replaces `go func() { <-ctx.Done(); cleanup() }()`)
- `context.WithTimeoutCause(parent, d, err)` — timeout with custom error

---

## Go 1.22+

### Loops
- `for i := range n` instead of `for i := 0; i < n; i++`
- Loop variables are safe to capture in goroutines (each iteration gets its own copy)

```go
// Before
for i := 0; i < len(items); i++ { ... }

// After
for i := range len(items) { ... }
```

### cmp package
- `cmp.Or(a, b, "default")` — returns first non-zero value (great for defaults)

```go
// Before
name := os.Getenv("NAME")
if name == "" { name = "default" }

// After
name := cmp.Or(os.Getenv("NAME"), "default")

// Chain
result := cmp.Or(a, b, "default")
```

### reflect package
- `reflect.TypeFor[T]()` instead of `reflect.TypeOf((*T)(nil)).Elem()`

### net/http
- Enhanced `http.ServeMux` patterns with method and path params

```go
// Before
mux.HandleFunc("/users/", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet { return }
    id := strings.TrimPrefix(r.URL.Path, "/users/")
})

// After
mux.HandleFunc("GET /users/{id}", func(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")
})
```

---

## Go 1.23+

### Iterators
- `maps.Keys(m)` / `maps.Values(m)` — return iterators (not slices)
- `slices.Collect(iter)` — collect iterator into slice
- `slices.Sorted(iter)` — collect and sort in one step

```go
// Before
keys := make([]string, 0, len(m))
for k := range m {
    keys = append(keys, k)
}
sort.Strings(keys)

// After
keys := slices.Collect(maps.Keys(m))
sortedKeys := slices.Sorted(maps.Keys(m))

// Direct iteration (allocates less)
for k := range maps.Keys(m) { process(k) }
```

### time package
- `time.Tick` is now safe — GC can recover unreferenced tickers (Go 1.23+). No need for `NewTicker` + `Stop` anymore.

---

## Go 1.24+

### Testing
- `t.Context()` instead of `context.WithCancel(context.Background())`

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

### JSON Tags
- `omitzero` instead of `omitempty` for `time.Duration`, `time.Time`, structs, slices, maps

```go
type Config struct {
    Timeout time.Duration `json:"timeout,omitzero"`  // omitempty doesn't work for Duration!
}
```

### Benchmarks
- `b.Loop()` instead of `for i := 0; i < b.N; i++`

```go
// Before
func BenchmarkFoo(b *testing.B) {
    for i := 0; i < b.N; i++ { doWork() }
}

// After
func BenchmarkFoo(b *testing.B) {
    for b.Loop() { doWork() }
}
```

### Strings/Bytes
- `strings.SplitSeq` / `strings.FieldsSeq` instead of `Split`/`Fields` when iterating (avoids allocation)
- `bytes.SplitSeq` / `bytes.FieldsSeq` also available

```go
// Before
for _, part := range strings.Split(s, ",") { process(part) }

// After
for part := range strings.SplitSeq(s, ",") { process(part) }
```

---

## Go 1.25+

### sync.WaitGroup
- `wg.Go(fn)` instead of `wg.Add(1)` + `go func() { defer wg.Done(); ... }()`

```go
// Before
var wg sync.WaitGroup
for _, item := range items {
    wg.Add(1)
    go func() {
        defer wg.Done()
        process(item)
    }()
}
wg.Wait()

// After
var wg sync.WaitGroup
for _, item := range items {
    wg.Go(func() { process(item) })
}
wg.Wait()
```

---

## Go 1.26+

### Pointers to Values
- `new(val)` instead of `x := val; &x` — returns pointer to any value. Type is inferred.

```go
// Before
timeout := 30
debug := true
cfg := Config{
    Timeout: &timeout,
    Debug:   &debug,
}

// After
cfg := Config{
    Timeout: new(30),   // *int
    Debug:   new(true), // *bool
}
```

### Error Type Matching
- `errors.AsType[*T](err)` instead of `errors.As(err, &target)`

```go
// Before
var pathErr *os.PathError
if errors.As(err, &pathErr) { handle(pathErr) }

// After
if pathErr, ok := errors.AsType[*os.PathError](err); ok {
    handle(pathErr)
}
```

---

## Quick Reference: Top Replacements by Impact

| Pattern | Modern Replacement | Go Version | Impact |
|---|---|---|---|
| `interface{}` | `any` | 1.18 | Critical |
| `for i := 0; i < n; i++` | `for i := range n` | 1.22 | Critical |
| Manual `contains` loop | `slices.Contains` | 1.21 | Critical |
| `err == sentinel` | `errors.Is(err, sentinel)` | 1.13 | Critical |
| Manual max/min | `min(a, b)` / `max(a, b)` | 1.21 | High |
| `sort.Slice` | `slices.Sort` / `slices.SortFunc` | 1.21 | High |
| `HasPrefix` + `TrimPrefix` | `strings.CutPrefix` | 1.20 | High |
| Manual map key collect | `slices.Collect(maps.Keys(m))` | 1.23 | High |
| `x := val; &x` | `new(val)` | 1.26 | High |
| `cmp.Or(a, "default")` | Default value chain | 1.22 | High |
| `if err == nil { return }` | `context.WithCancelCause` | 1.20 | Medium |
| `context.WithCancel(context.Background())` in tests | `t.Context()` | 1.24 | High |
| `wg.Add(1)` + `go func() { defer wg.Done()` | `wg.Go(fn)` | 1.25 | High |
| `for i := 0; i < b.N; i++` | `b.Loop()` | 1.25 | Medium |
| `omitempty` on `time.Duration` | `omitzero` | 1.24 | Medium |
| `for _, part := range strings.Split(s, ",")` | `SplitSeq` for-range | 1.24 | High |
