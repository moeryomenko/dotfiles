# Performance Patterns

Start from a representative measurement and an explicit constraint such as latency, throughput, allocation rate, memory limit, startup time, or binary size. Keep the simplest implementation that meets the target; re-measure after changes in release-like configuration.

## Iteration and allocation

Iterators, loops, and indexed access can all optimize well. Prefer the form that correctly expresses ownership and traversal, then investigate code generation only for a measured hot path.

```rust
for item in items.iter().map(transform) {
    use_in_loop(item);
}
```

Avoid collecting an intermediate collection unless it is needed for reuse, ownership, ordering, or an API boundary. Reuse allocation capacity when profiling shows it matters, but ensure a reused buffer does not retain unexpectedly large memory or stale sensitive data.

The `HashMap` entry API is useful when an insert-or-update operation needs one lookup:

```rust
for word in words {
    *counts.entry(word).or_insert(0) += 1;
}
```

Choose batching, `extend`, `drain`, buffering, or a different collection based on ownership, allocation, and I/O behavior—not because one spelling is categorically faster. `Iterator::collect_into` remains nightly-only; do not recommend it for stable/MSRV-constrained crates without explicit nightly support.

## I/O and hashing

`BufReader` or `BufWriter` often helps workloads with many small reads or writes. It can be unnecessary or harmful for already-buffered sources, large direct transfers, latency-sensitive flushing, or protocols with explicit framing.

Choose a hash algorithm from throughput, key distribution, attack surface, reproducibility, and compatibility. Replacing the standard map hasher can weaken hash-flood resistance; do so only where the input trust boundary and threat model permit it.

## Benchmarking

Use `std::hint::black_box` to help keep benchmark inputs and outputs observable, while recognizing that it does not make a benchmark realistic. Benchmark enough work to reduce timer noise, prevent setup from dominating, and inspect profiles/flamegraphs before making invasive changes.

## Load next

- Compiler and target settings: `optimization.md`
- Memory and buffer ownership: `memory.md`
- Collection tradeoffs: `collections.md`
