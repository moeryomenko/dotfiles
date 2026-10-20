# Async Patterns

Select patterns from the runtime, task ownership, cancellation semantics, delivery guarantees, and shutdown contract. A spawned task is detached work unless its handle is retained and joined.

## Task groups

Keep handles when task results, panics, cleanup, or ordered shutdown matter. Handle both a task's result and its `JoinError`:

```rust
async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let handle = tokio::spawn(async { do_work().await });
    handle.await??;
    Ok(())
}

async fn do_work() -> Result<(), std::io::Error> { Ok(()) }
```

Use `JoinSet` or structured framework facilities for a dynamic task group. Decide whether one failure cancels siblings, results are collected, or work continues before spawning.

## Channels and backpressure

A bounded `mpsc` channel limits queued work and gives the sender backpressure. Treat `send` failure as an ownership/shutdown decision, not an `unwrap` case.

```rust
async fn send_work(tx: tokio::sync::mpsc::Sender<u64>) -> Result<(), u64> {
    tx.send(42).await.map_err(|error| error.0)
}
```

`broadcast` receivers can return `Lagged`; decide whether a consumer can resynchronize, should fail, or must receive every event. `watch` retains only the latest value; `oneshot` carries one response.

A semaphore bounds concurrent work. It does not impose a time-based rate limit; use a token-bucket, interval, or service-specific policy when requests-per-time is the contract.

## Cancellation and shutdown

Cancellation stops future polling but does not roll back external effects. Design an operation to be safely abandoned, resumed, or compensated. Coordinate cancellation and await child tasks when shutdown requires their cleanup.

```rust
use tokio_util::sync::CancellationToken;

async fn worker(cancel: CancellationToken) {
    tokio::select! {
        _ = cancel.cancelled() => {}
        result = do_work() => { let _ = result; }
    }
}

async fn do_work() -> Result<(), std::io::Error> { Ok(()) }
```

For a server, stop accepting first, signal owned workers, then join them subject to a deadline. Check each selected operation's cancellation-safety documentation; it is not uniform.

## Load next

- Runtime/task constraints: `../../async.md`
- Locks and atomics: `../../concurrency.md`
- Error reporting: `../error-handling/common-patterns.md`
