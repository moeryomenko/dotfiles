# Async and Await

Choose async because the workload needs concurrent waiting or the framework requires it—not as a universal performance feature. Inspect the chosen runtime, its enabled features, task-spawn bounds, and shutdown model before adopting runtime-specific APIs.

## Ownership, `Send`, and spawning

A reference can cross an await when its lifetime remains valid; cloning `Arc` is not inherently required. A future becomes non-`Send` when it retains non-`Send` state across a suspension point, which matters for multithreaded spawning. `'static` is typically required by detached task APIs because the executor may retain a task after the caller returns; it does not mean the task runs forever.

Narrow critical sections before `.await` by default. Holding a standard lock guard across an await risks blocking executor threads and can create deadlocks. Tokio async locks are specifically designed to permit a guard across an await when needed, but using one still needs a contention, cancellation, and ownership argument.

## Blocking and parallel work

Do not run unbounded blocking or CPU-heavy work on async workers. `spawn_blocking` isolates a bounded blocking operation; it is not a universal CPU scheduler. For sustained CPU work, choose bounded concurrency, Rayon, dedicated workers, or a job system based on workload and runtime integration.

Runtime async filesystem APIs may internally use blocking pools. Select them where their scheduling and cancellation behavior fit; a small, startup-only synchronous operation can be clearer.

## Cancellation and coordination

Dropping a future cancels it only in the sense that polling stops; it does not automatically undo external side effects. Design operations to leave a recoverable state or explicitly continue/compensate work. Cancellation safety is operation-specific:

- Tokio channel receive operations are cancellation-safe for messages;
- lock acquisition may lose queue position when cancelled but does not lose protected data;
- operations such as `read_exact` can lose partial progress unless the caller owns and resumes the buffer/protocol state.

Use bounded channels when backpressure is required. Select `mpsc`, `broadcast`, `watch`, or `oneshot` from delivery semantics, lag behavior, and ownership—not by interchangeability. Join task handles/sets when results, panics, resource cleanup, or shutdown sequencing matters.

```rust
use tokio_util::sync::CancellationToken;

async fn worker(cancel: CancellationToken) {
    tokio::select! {
        _ = cancel.cancelled() => {}
        result = do_work() => handle(result),
    }
}

async fn do_work() -> Result<(), std::io::Error> { Ok(()) }
fn handle(_: Result<(), std::io::Error>) {}
```

## Async traits

Native `async fn` in traits is stable on supported modern Rust versions, but those traits are not dyn-compatible and their returned future bounds are part of the public API. `async_trait` or an explicit boxed-future/design adapter may be appropriate when dynamic dispatch is needed. `AsyncFn*` bounds have their own MSRV requirements; use them only after checking the crate's toolchain.

## Load next

- Locks and atomics: `concurrency.md`
- Task patterns: `patterns/async/common-patterns.md`
- Runtime error boundaries: `error-handling.md`
- Resource completion: `lifecycle.md`
