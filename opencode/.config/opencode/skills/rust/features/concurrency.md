# Concurrency

Start with the required invariant, owner, progress behavior, and shutdown policy. Use the simplest synchronization design that preserves them, then measure contention and throughput under representative load.

## Threads and parallelism

Rayon is often useful for data-parallel CPU work, but pool ownership, nested parallelism, blocking operations, order, and workload size still matter. Use `std::thread::scope` when child threads should borrow data from the enclosing scope; scoped threads remove the `'static` requirement but still require data to satisfy the relevant `Send`/`Sync` constraints.

## Locks and message passing

Use channels when ownership or work moves between components; use locks for shared, multi-field state; use atomics for independently synchronized values with a proven protocol. `RwLock` and lock-free designs are not automatically faster than a mutex.

`thread_local!` is valid for genuinely per-thread state, not as a generic replacement for shared mutable global state. It creates one value per thread and changes semantics rather than synchronizing shared data.

## Atomics

Select memory ordering from a justified happens-before relationship, not a slogan about always choosing the weakest ordering. `Relaxed` only synchronizes the atomic modification order itself. An acquire load provides visibility when it observes the appropriate release sequence. `SeqCst` can be a sound clarity-first baseline while designing or reviewing a protocol.

```rust
use std::sync::atomic::{AtomicBool, Ordering};

// The producer initializes the associated data before this release store.
ready.store(true, Ordering::Release);

// On observing that store (or its release sequence), this acquire load
// synchronizes with it.
if ready.load(Ordering::Acquire) {
    consume_initialized_data();
}
```

Do not derive an ordering for a multi-atomic protocol from this small example. Document the invariant and test/review the whole protocol. Loom can explore bounded schedules for synchronization code modeled with Loom primitives; it does not prove arbitrary production concurrency correct.

## Load next

- Async runtime constraints: `async.md`
- Ownership choices: `ownership.md`
- Common concurrency failures: `patterns/concurrency/common-errors.md`
- Unsafe auto-trait claims: `unsafe.md`
