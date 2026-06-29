# Concurrency (HIGH)

**Triggers**: parallel, thread, spawn, rayon, par_iter, Send, Sync, Mutex, RwLock, Atomic, atomics, Ordering, thread-local, thread_local, cross-thread, data race, deadlock.

## Use Rayon's `par_iter()` for CPU-Bound Data Parallelism

Rayon automatically manages a thread pool and splits work across available cores:

```rust
use rayon::prelude::*;

let sum: i32 = (0..1000000).into_par_iter().sum();
let results: Vec<Output> = items.par_iter().map(process).collect();
```

## Use `std::thread::scope` to Borrow Stack Data Across Threads

Scoped threads allow borrowing stack data without requiring `'static`:

```rust
let data = vec![1, 2, 3];
std::thread::scope(|s| {
    s.spawn(|| {
        println!("{:?}", data);  // Borrows from parent scope
    });
    s.spawn(|| {
        println!("{:?}", data);  // Multiple threads can share
    });
});
```

## Use the Weakest Correct Memory Ordering

For every atomic operation, use the weakest `Ordering` that is correct:

```rust
use std::sync::atomic::{AtomicBool, Ordering};

let flag = AtomicBool::new(false);

// Producer:
flag.store(true, Ordering::Release);

// Consumer:
if flag.load(Ordering::Acquire) {
    // Guaranteed to see all writes before the store
}
```

**Guidelines:**
- `Relaxed`: Single atomic variable, no ordering constraints
- `Acquire`/`Release`: Pairs of operations that need synchronization
- `AcqRel`: Read-modify-write that both acquires and releases
- `SeqCst`: Strongest ordering, use only when nothing else works

## Prefer `thread_local!` with `Cell`/`RefCell` Over `static mut`

```rust
use std::cell::RefCell;

thread_local! {
    static CACHE: RefCell<HashMap<String, Data>> = RefCell::new(HashMap::new());
}

CACHE.with(|cache| {
    cache.borrow_mut().insert(key, value);
});
```

## Cross-References

- For async abstractions: load `async`
- For shared ownership patterns: load `ownership`
- For concurrency errors with examples: load `patterns/concurrency/common-errors.md`
- For concurrent resource lifecycle: load `lifecycle`
