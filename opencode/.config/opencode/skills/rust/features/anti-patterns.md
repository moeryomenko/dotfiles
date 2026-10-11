# Anti-Patterns

Treat these as review prompts, not unconditional bans. Choose the simpler representation and error behavior that preserves the target crate's contract, then measure performance-sensitive paths.

## Errors and invariants

Use `Result` for expected input, I/O, and integration failures. `expect` or `unwrap` is appropriate only when a documented local invariant makes failure a bug and panicking is an acceptable contract. Do not silently discard a `Result`; propagate it, deliberately recover, or record a failure at the selected handling boundary.

```rust
fn load(path: &std::path::Path) -> std::io::Result<String> {
    std::fs::read_to_string(path)
}
```

## Ownership and interfaces

Avoid clones that do not serve an ownership boundary, but do not turn a clear owned API into borrowed plumbing merely to avoid allocation. Prefer `&str` or `&[T]` when the API only reads string or sequence data; accept owned or generic inputs when that genuinely improves the contract.

Narrow standard-lock critical sections before `.await` by default. Async-aware locking can intentionally span an await, but requires a deadlock, contention, cancellation, and shutdown argument.

## Abstraction and dispatch

Stay concrete until variability is required. Choose generic dispatch, enum dispatch, trait objects, or a closure based on extensibility, code size, allocation, and caller ergonomics. `Box<dyn Trait>` is useful for heterogeneous or runtime-selected behavior; `impl Trait` is useful when the concrete type can remain hidden without dynamic dispatch.

## Performance

Avoid optimizing from folklore. Reuse buffers, avoid intermediate collections, or choose a different data structure only after identifying a relevant allocation, latency, memory, or throughput cost. `format!` allocates a new `String`; use it when that ownership is appropriate, and use a reusable buffer only when measurement justifies it.

## Domain representation

Use enums or newtypes when they represent a meaningful closed set or distinction. A string is appropriate when the domain is intentionally open-ended or interoperates with external text.

## Load next

- Error boundaries: `error-handling.md`
- Ownership and locks: `ownership.md`, `async.md`
- Measured optimization: `performance.md`, `optimization.md`
