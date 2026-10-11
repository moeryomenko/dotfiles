# Testing

Choose tests from the failure modes and contract under change. Keep fast unit tests near implementation when private behavior matters; use integration tests for public API, process, feature, and packaging boundaries.

## Test layers

Use ordinary `#[test]` cases for examples and edge cases, property tests for general invariants, and integration tests in `tests/` for externally visible behavior. Avoid mocks when a cheap real implementation better represents the boundary; use a trait or test double when the dependency is slow, nondeterministic, unavailable, or must be observed precisely.

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn reverse_twice_is_identity(mut values: Vec<i32>) {
        let original = values.clone();
        values.reverse();
        values.reverse();
        prop_assert_eq!(values, original);
    }
}
```

Test error results and externally visible diagnostics where they are contractual, not incidental wording. `#[should_panic]` suits a narrow intentional panic contract; explicit `catch_unwind` or result assertions are often clearer for behavior under test.

## Async and concurrency

Use the runtime's test support when the production API requires it, but do not hide timeout, cancellation, or task-cleanup behavior. Join spawned tasks when their output, panic, or cleanup matters.

Loom explores bounded interleavings only for synchronization code built with Loom-modeled primitives. It can expose races and ordering bugs; it does not prove arbitrary production code correct.

## Measurements and generated cases

Benchmark representative workloads separately from correctness tests. Snapshot tests are useful when output is reviewed intentionally; normalize nondeterministic data. Fuzzers, property tests, and corpus regression cases complement one another rather than substitute for example-based tests.

## Load next

- Executable examples: `documentation.md`
- Async coordination: `async.md`
- Numerical comparison policy: `numeric.md`
