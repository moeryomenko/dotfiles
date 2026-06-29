# Observability (MEDIUM)

## Use `tracing` for Structured, Span-Aware Diagnostics

Prefer `tracing` over `println!` or bare `log`:

```rust
use tracing::{info, warn, error};

info!("processing item {}", id);
warn!("slow query detected: {:?}", query);
error!(error = %e, "failed to process request");
```

## Libraries Emit Through the Tracing/Log Facade

Libraries should never install a subscriber — they emit through the facade, and the application chooses the output:

```rust
// In library Cargo.toml
tracing = { version = "0.1", default-features = false, features = ["std"] }
```

## Record Structured Key-Value Fields

Not values interpolated into the message string:

```rust
// Bad: values in message
info!("user {} logged in from {}", user.id, user.ip);

// Good: structured fields
info!(user.id, user.ip, "user logged in");
```

## Use `#[tracing::instrument]` and Spans

```rust
#[tracing::instrument(skip(password))]
fn authenticate(user: &str, password: &str) -> Result<Session, AuthError> {
    // Function entry/exit automatically traced
    // Fields: user, function name, duration
}
```

## Use Log Levels Meaningfully

| Level | When to Use |
|-------|------------|
| `error` | Recoverable or unrecoverable failures |
| `warn` | Unexpected but handled situations |
| `info` | Important normal operations (startup, shutdown, state changes) |
| `debug` | Detailed information for debugging |
| `trace` | Very fine-grained function-level tracing |

Filter with `EnvFilter` / `RUST_LOG`:

```bash
RUST_LOG=warn,my_crate=debug cargo run
```

## Log Errors with Their Full Source Chain

Log each error exactly once:

```rust
fn process() -> Result<()> {
    if let Err(e) = do_something() {
        // Log the full chain once
        warn!(error = &*e, "operation failed");
        return Err(e);
    }
    Ok(())
}
```

## Never Log Secrets or PII

Redact or skip sensitive fields:

```rust
#[tracing::instrument(skip(password, secret_key))]
fn process_login(user: &str, password: &str, secret_key: &str) { /* ... */ }
```

## Cross-References

- For error chains: load `error-handling`
- For tracing with async: load `async`
