# Go Optimization

## Profiling

### CPU Profiling
```go
import "runtime/pprof"

f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()
```

### Memory Profiling
```go
import "runtime/pprof"

f, _ := os.Create("mem.prof")
runtime.GC()
pprof.WriteHeapProfile(f)
```

### Interactive Analysis
```bash
go tool pprof -http :9090 cpu.prof
go tool pprof -http :9090 mem.prof
```

### Trace Profiling
```go
import "runtime/trace"

f, _ := os.Create("trace.out")
trace.Start(f)
defer trace.Stop()
```
```bash
go tool trace trace.out
```

### Benchmarks with Profiles
```bash
go test -bench=. -cpuprofile=cpu.prof -memprofile=mem.prof -trace=trace.out
go test -bench=. -benchmem -benchtime=10s
```

## Memory

### Escape Analysis
The Go compiler decides where to allocate. Values that escape to heap:
- Returned via pointer
- Assigned to interface
- Captured by closure
- Assigned to global/captured variable

```bash
go build -gcflags="-m -m" 2>&1 | grep "escapes to heap"
```

Common heap allocations:
| Pattern | Heap Escape | Fix |
|---|---|---|
| Returning `*T` | Yes | Return `T` if caller can copy |
| `fmt.Sprintf` | Yes | Use `strconv` for simple int/float/string |
| `interface{}` param | Yes | Use generics (Go 1.18+) |
| `[]byte(string)` | Usually | Use `strings.Builder`, `strconv.AppendFloat` |
| `defer` in hot loop | Closure escapes | Move `defer` outside loop or inline |

### Slice Capacity Pre-allocation
```go
// Avoids multiple reallocations
data := make([]int, 0, expectedSize)
for _, v := range source {
    data = append(data, v)
}
```

### String Concatenation Performance
```go
// Worst: creates new string each iteration
str := ""
for _, s := range parts { str += s }

// Best: strings.Builder with capacity
var b strings.Builder
b.Grow(totalLen)
for _, s := range parts { b.WriteString(s) }
str := b.String()
```

### Avoid String Conversion Overhead

| Conversion | Cost | Alternative |
|---|---|---|
| `string([]byte)` | Allocates | `strings.Builder` |
| `[]byte(string)` | Allocates | `slices` package (Go 1.21+) |
| `fmt.Sprintf("%d", n)` | Allocates | `strconv.Itoa`, `strconv.AppendInt` |
| `fmt.Errorf(...)` | Allocates | `errors.New` for static messages |

## Benchmarking

### Writing Benchmarks
```go
func BenchmarkFoo(b *testing.B) {
    for range b.N {
        Foo()
    }
}

func BenchmarkAlloc(b *testing.B) {
    b.ReportAllocs() // show allocation stats
    for range b.N {
        Foo()
    }
}

// Reset timer after setup
func BenchmarkPool(b *testing.B) {
    pool := NewPool()
    b.ResetTimer()
    for range b.N {
        pool.Get()
    }
}
```

### Benchmark Gotchas
- The compiler can eliminate dead code — store results:
```go
func BenchmarkHash(b *testing.B) {
    d := []byte("hello")
    var result uint64 // prevent elimination
    for range b.N {
        result = hash(d)
    }
    _ = result
}
```

- Avoid costly setup in the loop (call `b.ResetTimer()` after setup).
- Use `-benchtime=10x` to run exactly 10 iterations for slow benchmarks.

## GC Tuning

### Reduce Pointer Count

Each pointer is a GC root. Reduce allocations to reduce GC pressure:

```go
// Before: each Entry is a pointer (heap allocation)
type Cache struct {
    entries []*Entry
}

// After: value type, no pointer chasing
type Cache struct {
    entries []Entry
}
```

### GOGC and GOMEMLIMIT
```go
// GOGC=off disables GC (risk of OOM)
// GOGC=100 means GC triggers when heap doubles
// GOMEMLIMIT=2GiB sets soft memory limit (Go 1.19+)
```

In Go 1.19+, set `GOMEMLIMIT` and keep default `GOGC=100` for better latency:

```bash
GOMEMLIMIT=2GiB go run .
```

### Object Pooling
Use `sync.Pool` for reusable objects. Only for allocations that are **large** or **frequent**.

```go
var pool = sync.Pool{
    New: func() any { return new(Buffer) },
}

func Get() *Buffer { return pool.Get().(*Buffer) }
func Put(b *Buffer) { b.Reset(); pool.Put(b) }
```

## Compiler Optimizations

### Inlining

```go
// Small, simple functions are inlined automatically
// -gcflags="-l" disables inlining
// -gcflags="-m" shows inlining decisions
```

### Bounds Check Elimination (BCE)

```go
// Before: compiler inserts bounds checks
b = s[i] + s[j]

// After: first access checks bounds, rest are eliminated
_ = s[7]
b = s[i] + s[j] // s[i] and s[j] may skip check
```

## Concurrency Optimization

### Channel vs Mutex

| Pattern | Best for | Notes |
|---|---|---|
| Channel | Signal, coordination, fan-out | Goroutine involved; GC pressure from goroutine stacks |
| Mutex | Hot-path, fine-grained state | No goroutine overhead; blocking can contend |
| Atomic | Counters, flags | Lowest overhead; limited to single-word ops |

Use `sync.Pool` under high allocation pressure. Profile before introducing complexity.

### Goroutine Stack Size

Goroutines start at ~8 KB stack (grows as needed). For high-concurrency workloads (100k+ goroutines), minimize per-goroutine allocation. Avoid deep call stacks on many goroutines.

## Code Layout Optimizations

### Hot-Path Fast Returns
Structure hot functions so the compiler generates better branch prediction:

```go
func Validate(v Value) error {
    if v.err != nil { return v.err } // cold path last
    // hot path first
    if v.Count > max { return ErrTooBig }
    return nil
}
```

### Function Size
- Keep hot functions small (compiler inlines small functions).
- Split large functions: hot path inlined, cold path separate.

## Cross-References

- For allocation-free patterns: load `idioms`
- For modern features that eliminate allocations: load `modern-features`
- For benchmark testing patterns: load `testing`
- For linting performance issues: load `linter-guide`
