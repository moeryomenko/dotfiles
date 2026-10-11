# Compiler Optimization

Profile representative release workloads before changing compiler settings or source structure. Record the target hardware, input distribution, benchmark method, and the measured metric; a speedup in a microbenchmark can regress code size, compile time, latency, portability, or power use.

## Build configuration

`lto`, `codegen-units`, optimization level, stripping, and PGO are release-engineering tradeoffs. Evaluate them per deployable artifact rather than treating one profile as universally best.

```toml
[profile.release]
lto = "thin"
codegen-units = 1
```

This can improve some whole-program optimizations while increasing build time. Check the target crate/workspace policy and artifact measurements before adopting it.

`target-cpu` is not a Cargo profile key. Set target CPU features through the selected build environment or `RUSTFLAGS` only for a controlled deployment target; binaries built with unsupported CPU instructions can fail on other machines. Do not apply `target-cpu=native` to distributable artifacts unless the deployment contract guarantees that CPU.

## Source-level choices

The optimizer already inlines and removes bounds checks in many cases. Use `#[inline]`, `#[cold]`, or `#[inline(never)]` only where profiling and cross-crate/API needs justify the hint; these attributes are hints, not guarantees. Source branch order is not a reliable portable branch-prediction directive.

Prefer clear iteration when it matches the access pattern, then inspect generated behavior only if it is a measured bottleneck:

```rust
for item in slice {
    process(item);
}
```

Data layout, allocation behavior, and locality depend on the workload. A struct-of-arrays layout may benefit column-oriented hot loops, while an array-of-structs layout may be better for per-record processing.

## SIMD

`std::simd` is nightly-only. Use it only under an explicitly supported nightly toolchain and target-feature policy. On stable Rust, evaluate an established crate, explicit platform intrinsics behind feature detection, or a scalar implementation based on the portability, maintenance, and measured-performance requirements.

## Load next

- Runtime and allocation measurements: `performance.md`
- Representation and layout: `memory.md`
- Numeric semantics: `numeric.md`
