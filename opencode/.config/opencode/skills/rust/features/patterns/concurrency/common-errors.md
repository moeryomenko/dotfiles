# Common Concurrency Errors

Start with the invariant, ownership boundary, progress requirement, and shutdown behavior. Replace a primitive only when it implements the required semantics.

## `Send`, `Sync`, and shared state

`std::thread::spawn` requires moved captures to be `Send`; sharing `Arc<T>` across threads also requires the relevant `T: Sync` behavior. `Rc` and `RefCell` are useful for single-threaded ownership/interior mutability, not cross-thread sharing.

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0_u64));
let worker_counter = Arc::clone(&counter);
let worker = std::thread::spawn(move || {
    *worker_counter.lock().expect("mutex poisoned") += 1;
});
worker.join().expect("worker panicked");
```

Choose a mutex for related shared state, a channel when work ownership moves, and an atomic only for a fully specified atomic protocol. `RwLock` is not automatically better for read-heavy code; measure contention and writer progress.

## Deadlocks and waiting

Avoid holding multiple locks where possible. If they are necessary, define and enforce a global acquisition order. A non-reentrant mutex may deadlock if the same thread tries to acquire it again; redesign the ownership/control flow rather than making reentrancy a default. A reentrant mutex changes what mutation can safely mean and does not solve arbitrary locking design problems.

In async code, release standard mutex guards before `.await` by default. An async mutex permits holding a guard over an await, but requires an explicit contention, cancellation, and deadlock argument.

Do not spin on `try_recv` or `try_lock` without a bounded backoff, readiness mechanism, or a reason a busy wait is correct. Prefer blocking/async wait facilities when latency and scheduling allow.

## Panics and executor blocking

Join threads/tasks when a panic or completion matters. `catch_unwind` is not a general recovery boundary: it only catches unwinding panics, requires `UnwindSafe` (or a justified assertion), and cannot repair partially mutated shared state. Avoid blocking a runtime worker with long blocking work; use a bounded blocking facility or dedicated workers based on workload.

## Load next

- Atomic ordering: `../../concurrency.md`
- Async task lifecycle: `../async/common-patterns.md`
- Unsafe thread-safety claims: `../../unsafe.md`
