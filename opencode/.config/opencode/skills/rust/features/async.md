# Async/Await (HIGH)

**Triggers**: async, await, Future, tokio, async-std, smol, spawn, JoinSet, select!, join!, channel, mpsc, oneshot, broadcast, CancellationToken, cancellation, async fn in trait, Send across await, spawn_blocking, runtime.

## Configure Tokio Runtime Appropriately

| Runtime | Use Case |
|---------|----------|
| Multi-thread (default) | IO-bound, many concurrent connections |
| Current-thread (`flavor = "current_thread"`) | CLI tools, tests, single connection |
| Custom (`Builder::new_*()`) | Fine-tuned thread count, name, etc. |

```rust
#[tokio::main(flavor = "current_thread")]
async fn main() { /* single-threaded */ }

#[tokio::main(worker_threads = 4)]
async fn main() { /* custom thread count */ }
```

## Never Hold Mutex/RwLock Across `.await`

Holding a lock across an await point can cause deadlocks if the lock is held on the same thread.

```rust
// BAD: lock held across await
let data = lock.lock().unwrap();
some_future.await;

// GOOD: scope the lock
let result = {
    let data = lock.lock().unwrap();
    data.compute()
};
some_future.await;
```

## Use `spawn_blocking` for CPU-Intensive Work

CPU-bound work on the async executor starves IO tasks:

```rust
tokio::task::spawn_blocking(move || {
    heavy_computation(data)
}).await.unwrap()
```

## Use `tokio::fs` Instead of `std::fs` in Async Code

`std::fs` blocks the thread. `tokio::fs` offloads to a blocking thread pool.

## Use `CancellationToken` for Graceful Shutdown

```rust
use tokio_util::sync::CancellationToken;

let token = CancellationToken::new();
let token_clone = token.clone();
tokio::spawn(async move {
    tokio::select! {
        _ = token_clone.cancelled() => return,
        result = do_work() => handle(result),
    }
});
token.cancel();
```

## Use `join!` / `try_join!` for Concurrent Independent Futures

```rust
let (result1, result2) = tokio::join!(fetch_a(), fetch_b());
```

`try_join!` propagates errors early.

## Use `select!` to Race Futures

```rust
tokio::select! {
    result = primary_task() => handle_primary(result),
    _ = timeout(Duration::from_secs(5)) => handle_timeout(),
}
```

## Use Bounded Channels to Apply Backpressure

```rust
let (tx, rx) = tokio::sync::mpsc::channel(256);  // bounded
```

| Channel | Use Case |
|---------|----------|
| `mpsc` | Async message queues between tasks |
| `broadcast` | Pub/sub, all subscribers receive all messages |
| `watch` | Share the latest value with observers |
| `oneshot` | Request-response patterns |

## Use `JoinSet` for Managing Dynamic Task Collections

```rust
let mut set = JoinSet::new();
set.spawn(task1());
set.spawn(task2());
while let Some(res) = set.join_next().await {
    handle(res?);
}
```

## Clone Arc/Rc Data Before Await Points

Avoid holding references across suspension:

```rust
let arc = Arc::clone(&shared);
some_future.await;
process(&arc);
```

## Use Native `async fn` in Traits (Stable 1.75+)

Instead of the `async_trait` macro:

```rust
trait AsyncProcessor {
    async fn process(&self, data: Data) -> Result<Output>;
}
```

## Use `AsyncFn`/`AsyncFnMut`/`AsyncFnOnce` Bounds

Instead of `F: Fn() -> Fut, Fut: Future`:

```rust
async fn run<F: AsyncFn()>(f: F) {
    f().await;
}
```

## Ensure Futures Are Cancellation-Safe

Futures used in `tokio::select!` branches should tolerate being dropped without side effects. Operations like `RecvError` on channels, `read_exact` on partial data, or acquiring locks are not cancellation-safe.

## Cross-References

- For concurrency patterns: load `concurrency`
- For ownership across threads: load `ownership`
- For cancellation safety: load `lifecycle`
- For async patterns with examples: load `patterns/async/common-patterns.md`
- For async error handling: load `error-handling`
