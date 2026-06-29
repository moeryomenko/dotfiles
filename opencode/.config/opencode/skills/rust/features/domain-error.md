# Domain Error Strategy (HIGH)

**Triggers**: domain error, error categorization, retry, fallback, recovery strategy, circuit breaker, graceful degradation, transient vs permanent error, error context, backoff, error code design.

## Core Question

**Who needs to handle this error, and how should they recover?**

Before designing error handling:
- Is this error user-facing or internal?
- Is recovery possible or is it permanent?
- What context is needed for debugging vs. for the user?
- Should the caller retry or fail fast?

---

## Error Categorization

| Category | Audience | Recovery | Example |
|----------|----------|----------|---------|
| User-facing | End users | Guide corrective action | `InvalidEmail`, `NotFound` |
| Internal | Developers | Debug, fix code | `DatabaseError`, `ParseError` |
| System | Ops/SRE | Monitor, alert, page | `ConnectionTimeout`, `RateLimited` |
| Transient | Automation | Retry with backoff | `NetworkError`, `ServiceUnavailable` |
| Permanent | Human | Investigate, patch | `ConfigInvalid`, `DataCorrupted` |

### Decision Flowchart

```
What kind of failure is this?
├─ Bug (invariant violation)
│   └─ panic!, assert!, unreachable!
├─ Expected operational failure
│   ├─ Transient (network, timeout, rate-limit)
│   │   └─ Retry with backoff
│   ├─ Recoverable (validation, not-found)
│   │   └─ Return Result, let caller decide
│   └─ Permanent (config error, corrupt data)
│       └─ Fail fast, alert
└─ Absence is normal (find, get, lookup)
    └─ Option<T>
```

---

## Error Type Design

### Categorizing with Custom Error Types

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    // User-facing errors (actionable)
    #[error("user '{0}' not found")]
    NotFound(String),

    #[error("invalid input: {0}")]
    Validation(String),

    // Transient errors (retryable)
    #[error("service unavailable: {0}")]
    ServiceUnavailable(String),

    #[error("request timed out")]
    Timeout(#[source] Box<dyn std::error::Error + Send>),

    // Internal errors (debug info)
    #[error("database error")]
    Database(#[from] sqlx::Error, #[source] Box<dyn std::error::Error + Send>),

    // System errors (alert-worthy)
    #[error("configuration error: {0}")]
    Config(String),
}
```

### Retry vs. Fail-Fast Signaling

```rust
/// Marker trait for errors that are safe to retry
trait Retryable {
    fn is_retryable(&self) -> bool;
    fn retry_after(&self) -> Option<Duration>;
}

impl Retryable for AppError {
    fn is_retryable(&self) -> bool {
        matches!(self, Self::ServiceUnavailable(_) | Self::Timeout(_))
    }

    fn retry_after(&self) -> Option<Duration> {
        match self {
            Self::ServiceUnavailable(msg) if msg.contains("rate limit") => {
                Some(Duration::from_secs(60))
            }
            Self::Timeout(_) => Some(Duration::from_millis(100)),
            _ => None,
        }
    }
}
```

---

## Recovery Patterns

### Retry with Exponential Backoff

```rust
use std::time::Duration;
use tokio::time::sleep;

async fn retry_with_backoff<F, T, E>(f: F, max_attempts: u32) -> Result<T, E>
where
    F: Fn() -> futures::future::LocalBoxFuture<'static, Result<T, E>>,
    E: Retryable,
{
    let mut attempt = 0u32;
    loop {
        match f().await {
            Ok(val) => return Ok(val),
            Err(e) if attempt >= max_attempts || !e.is_retryable() => return Err(e),
            Err(e) => {
                let delay = e.retry_after()
                    .unwrap_or_else(|| Duration::from_millis(100 * 2u64.pow(attempt)));
                sleep(delay).await;
                attempt += 1;
            }
        }
    }
}
```

### Circuit Breaker

```rust
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::Arc;
use std::time::Instant;

enum CircuitState {
    Closed,       // Normal operation
    Open,         // Failing — reject immediately
    HalfOpen,     // Testing if service recovered
}

struct CircuitBreaker {
    failure_count: AtomicU32,
    failure_threshold: u32,
    open_until: parking_lot::Mutex<Option<Instant>>,
    cooldown: Duration,
}

impl CircuitBreaker {
    fn call<F, T, E>(&self, f: F) -> Result<T, E>
    where
        F: FnOnce() -> Result<T, E>,
        E: std::fmt::Display,
    {
        // Check if circuit is open
        if let Some(until) = *self.open_until.lock() {
            if Instant::now() < until {
                return Err(/* fast-fail error */);
            }
            // Cooldown expired — half-open
            self.open_until.lock().take();
        }

        // Attempt the call
        match f() {
            Ok(val) => {
                self.failure_count.store(0, Ordering::Release);
                Ok(val)
            }
            Err(e) => {
                let count = self.failure_count.fetch_add(1, Ordering::AcqRel) + 1;
                if count >= self.failure_threshold {
                    *self.open_until.lock() = Some(Instant::now() + self.cooldown);
                }
                Err(e)
            }
        }
    }
}
```

### Fallback

```rust
async fn fetch_user_preferences(user_id: &str) -> Preferences {
    // Try primary cache
    if let Some(prefs) = cache::get(user_id).await {
        return prefs;
    }

    // Fall back to database
    match db::get_preferences(user_id).await {
        Ok(prefs) => {
            cache::set(user_id, &prefs).await;
            prefs
        }
        Err(_) => {
            // Last resort: return defaults
            Preferences::default()
        }
    }
}
```

---

## Error Context Patterns

### Rich Context for Debugging

```rust
use std::backtrace::Backtrace;

#[derive(Error, Debug)]
pub enum OperationError {
    #[error("failed to process order {order_id}")]
    OrderProcessing {
        order_id: String,
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
        backtrace: Backtrace,
    },
}

impl OperationError {
    pub fn order_processing(
        order_id: impl Into<String>,
        source: impl Into<Box<dyn std::error::Error + Send + Sync>>,
    ) -> Self {
        Self::OrderProcessing {
            order_id: order_id.into(),
            source: source.into(),
            backtrace: Backtrace::capture(),
        }
    }
}
```

### Structured Error Logging

```rust
use tracing::{error, warn, info, Span};

fn log_error_with_context(err: &AppError, request_id: &str) {
    match err {
        // User errors: log at info level
        AppError::Validation(msg) => {
            info!(
                error.type = "validation",
                error.message = %msg,
                request.id = request_id,
                "validation error"
            );
        }
        // Transient errors: warn level
        AppError::Timeout(_) => {
            warn!(
                error.type = "timeout",
                request.id = request_id,
                "request timed out, will retry"
            );
        }
        // System errors: error level with full context
        AppError::Config(msg) => {
            error!(
                error.type = "config",
                error.message = %msg,
                request.id = request_id,
                "configuration error — service may be unstable"
            );
        }
    }
}
```

---

## Library vs Application Error Philosophy

| Context | Tool | Why |
|---------|------|-----|
| Library | `thiserror` | Typed, matchable errors for consumers |
| Application | `anyhow` | Ergonomic propagation with context |
| Mixed | Both | thiserror at API boundaries, anyhow internally |

### Boundary Conversion

```rust
// Library layer: typed errors
use thiserror::Error;

#[derive(Error, Debug)]
pub enum StorageError {
    #[error("item not found: {key}")]
    NotFound { key: String },
    #[error("storage backend unavailable: {0}")]
    BackendUnavailable(String),
}

// Application layer: convert to anyhow at boundary
use anyhow::Context;

fn load_user(id: &str) -> anyhow::Result<User> {
    let raw = storage::get(id)
        .with_context(|| format!("failed to load user {id}"))?;
    Ok(serde_json::from_str(&raw)?)
}
```

---

## Common Mistakes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| Retrying permanent errors | Wastes resources, delays alerting | Classify errors as retryable/permanent |
| Logging at error level for user errors | Alert fatigue, noise | Match log level to audience |
| Swallowing error context | Impossible to debug | Use `.context()` or wrap with source |
| Infinite retry loop | Resource exhaustion | Set max attempts and backoff |
| No circuit breaker for downstream | Cascade failures | Add circuit breaker to external calls |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| One error type for everything | No recovery clues | Categorized error types |
| Panic on transient failure | Crash the process | Return Result, retry |
| `Box<dyn Error>` for all errors | Lost type info | thiserror variants |
| Silent `Result::ok()` | Hidden failures | Log or propagate |
| Retrying without backoff | Thundering herd | Exponential backoff + jitter |

---

## Cross-References

- For error type design: load `error-handling`
- For type safety: load `type-safety`
- For observability: load `observability`
- For async error handling: load `async`
