# Resource Lifecycle

Choose a resource's owner, scope, failure behavior, and required completion semantics before choosing a guard, pool, or global. RAII makes ordinary scope exits—including unwinding—reliable, but it is not guaranteed during aborts, `process::exit`, intentional leaks, or `mem::forget`.

## `Drop` and explicit completion

Use `Drop` for best-effort, non-fallible local cleanup such as releasing memory, locks, or a borrowed pool handle. Do not rely on it for protocol completion, durable writes, or errors callers must observe. Expose an explicit `close`, `shutdown`, `commit`, or `finish` returning `Result` when successful completion matters; use `Drop` as a fallback such as rollback or cancellation.

Never panic in `Drop`. A panic while unwinding aborts the process, and cleanup errors normally cannot be reported from `Drop`.

`mem::forget(value)` is safe but leaks the value and its resources. `ManuallyDrop<T>` suppresses automatic destruction; recover its owned value with `ManuallyDrop::into_inner` when appropriate. Manual destruction introduces additional validity obligations and should be justified by a concrete invariant.

## Scope guards

A normal scope guard runs on every scope exit. Use it for unconditional cleanup, or select a disarmable/conditional guard when the cleanup must occur only on failure.

```rust
use scopeguard::guard;

fn write_file(path: &std::path::Path, data: &[u8]) -> std::io::Result<()> {
    std::fs::write(path, data)?;
    let cleanup = guard(path, |path| { let _ = std::fs::remove_file(path); });
    validate_written_file(path)?;
    scopeguard::ScopeGuard::into_inner(cleanup);
    Ok(())
}

fn validate_written_file(_: &std::path::Path) -> std::io::Result<()> { Ok(()) }
```

## Transactions and fallible resources

Bind operations to the transaction, rather than re-borrowing the underlying connection while it is borrowed by the transaction. The concrete API belongs to the selected database crate, but the ownership shape is generally:

```rust
fn transfer(conn: &mut Connection, from: AccountId, to: AccountId) -> Result<(), Error> {
    let mut tx = conn.begin()?;
    tx.debit(from)?;
    tx.credit(to)?;
    tx.commit()?;
    Ok(())
}
```

The transaction type may roll back on drop, but `commit` remains explicit and fallible.

## Initialization and pooling

Use `OnceLock` or `LazyLock` for process-wide state only when global lifetime and initialization failure behavior are intentional. Avoid hiding fallible configuration or network initialization behind an `expect` unless process termination is the contract.

Use a pool when a resource is expensive, concurrently reusable, and has a bounded capacity/lifetime policy. Pool behavior is crate- and protocol-specific; always return/reset/check resources according to the pool's contract.

## Async and threads

A task or thread needs an owner, completion policy, and shutdown path if it can outlive its caller. Do not hold locks across an await by default; when doing so is deliberate, verify the runtime primitive and contention behavior. A spawned thread without a join handle may be intentional, but its lifetime and errors then need another observability mechanism.

## Load next

- Ownership and shared state: `ownership.md`, `concurrency.md`
- Async task cancellation: `async.md`
- Unsafe manual-destruction invariants: `unsafe.md`
