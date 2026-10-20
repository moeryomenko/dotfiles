# Go Optimization

Optimize a measured bottleneck, not a suspected one. First establish the workload, correctness constraints, and a reproducible benchmark or production profile. Prefer a simpler design when the measured gain does not justify its complexity.

## Measure before changing code

Use benchmarks for small, repeatable operations and profiles or traces for application behavior.

```bash
go test ./... -bench=. -benchmem
go test ./... -bench=BenchmarkEncode -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof
go tool pprof -http=:0 cpu.prof
go tool pprof -http=:0 mem.prof
```

Use `go test -count` or a benchmark comparison tool to account for variance. Benchmark representative inputs, validate results outside the timed loop, and reset the timer after one-time setup.

```go
var benchmarkResult uint64

func BenchmarkHash(b *testing.B) {
    data := []byte("hello")
    b.ReportAllocs()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        benchmarkResult = hash(data)
    }
}
```

Capture a trace when scheduler latency, blocking, goroutine behavior, or GC interactions are plausible contributors:

```bash
go test ./... -run '^$' -bench=BenchmarkWork -trace=trace.out
go tool trace trace.out
```

When collecting profiles in application code, check creation and start errors, stop profiling, and close output files. Prefer the test flags above when they model the workload.

## Allocations and escape analysis

The compiler chooses stack versus heap placement based on data flow and implementation details. Returning a pointer, passing through an interface, capturing a variable, or using a closure can affect escape decisions, but none independently guarantees an allocation. Inspect compiler diagnostics and benchmark allocation counts before changing an API.

```bash
go build -gcflags='all=-m=2' ./...
```

Preallocate a slice only when a realistic size estimate prevents growth and profiling indicates the allocation matters.

```go
values := make([]Value, 0, expectedCount)
for _, value := range source {
    values = append(values, transform(value))
}
```

For repeated concatenation, `strings.Builder` can reduce allocations. For small or infrequent work, `+` is usually clearer. Call `Grow` only with a credible size estimate.

```go
var builder strings.Builder
for _, part := range parts {
    builder.WriteString(part)
}
result := builder.String()
```

Conversions between `string` and `[]byte` may allocate. Avoid them by keeping data in the form required by the next operation, or use APIs such as `strconv.AppendInt` when building bytes is already appropriate. Do not introduce unsafe conversions merely to avoid an allocation.

## GC and memory limits

Reducing allocation rate and retaining less memory can reduce GC work. Pointer-rich objects can also increase scanning work, but pointers within live objects are not individually GC roots. Choose value layouts only when their copying, locality, and mutability trade-offs suit the workload.

`GOGC` controls the heap-growth target used by the garbage collector; it is not a fixed heap-doubling guarantee. `GOMEMLIMIT` (Go 1.19+) supplies a soft memory limit and can cause the runtime to collect more aggressively. Set either only after observing production-like memory and latency behavior.

## Pools and resource reuse

`sync.Pool` is for temporary, independently reusable objects under measured allocation pressure. Objects may be discarded at any GC cycle, so it is not a cache or ownership mechanism. Reset an object before putting it back, never retain it after `Put`, and benchmark the added contention and lifecycle complexity.

```go
var buffers = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}

func withBuffer(fn func(*bytes.Buffer)) {
    buffer := buffers.Get().(*bytes.Buffer)
    buffer.Reset()
    defer buffers.Put(buffer)
    fn(buffer)
}
```

## Compiler diagnostics

Use compiler diagnostics to investigate a measured hot path, not to force a particular transformation:

```bash
go build -gcflags='all=-m=2' ./...
go build -gcflags='all=-d=ssa/check_bce/debug=1' ./...
```

Bounds-check elimination depends on provable bounds. Write straightforward loops first, then inspect diagnostics if checks appear in a profile. Do not add artificial indexing solely to influence BCE without a demonstrated improvement.

Inlining decisions vary by compiler version and call shape. Splitting cold error handling from a hot path can be helpful when profiles and diagnostics support it; do not assume smaller functions or early returns guarantee a branch-prediction or inlining improvement.

## Concurrency choices

Choose synchronization for the required semantics, then measure contention and throughput:

| Need | Common fit |
|---|---|
| Transfer work, signals, or ownership | channels |
| Protect shared multi-field state | mutexes |
| Simple independent counters or flags | typed atomics |

Channels add coordination and may require goroutines; mutexes can contend; atomics do not preserve multi-operation invariants. Goroutine stacks grow and shrink dynamically, so use profiles and traces rather than relying on a fixed stack-size assumption when evaluating large concurrency counts.
