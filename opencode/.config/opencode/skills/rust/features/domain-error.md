# Domain Error Strategy

Classify failures by caller action, not only by where they arose. Preserve structured information at reusable boundaries; attach diagnostic context at meaningful domain or ownership transitions; report or log once at a deliberate application boundary.

## Error categories

Distinguish invalid input, absence, conflict, authorization, transient dependency failure, timeout, cancellation, and invariant failure only when callers need different recovery or presentation. `Option<T>` fits normal absence; `Result<T, E>` fits an actionable failure. A bug may justify an assertion only when violating the invariant is not recoverable under the API contract.

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PaymentError {
    #[error("payment {id} was not found")]
    NotFound { id: String },
    #[error("payment input is invalid: {reason}")]
    Invalid { reason: String },
    #[error("gateway is unavailable")]
    Gateway(#[source] std::io::Error),
}
```

`#[from]` generates a conversion only for a compatible single-source variant. Add a separate constructor or variant when the error also needs domain fields.

## Retry and fallback

Retry only an operation known to be safe to repeat or protected with an idempotency key. Bound attempts and total deadline, respect cancellation, classify errors from explicit metadata rather than message text, cap exponential backoff, and use jitter where coordinated retries could overload a dependency. Observe server-provided retry delays only when they are trusted and fit the caller deadline.

Fallbacks can hide data loss, stale reads, or authorization failures. Define their consistency, freshness, and user-visible behavior before using one. Circuit breakers require a domain-specific open-state outcome, half-open admission policy, metrics, and concurrency model; do not manufacture a generic `E` fast-fail value inside a wrapper.

## Status and presentation boundaries

Map errors to protocol/status responses at the transport boundary. Make matching exhaustive so a newly added error category receives an intentional response:

```rust
fn status(error: &PaymentError) -> u16 {
    match error {
        PaymentError::NotFound { .. } => 404,
        PaymentError::Invalid { .. } => 400,
        PaymentError::Gateway(_) => 503,
    }
}
```

Do not expose internal sources or sensitive context to untrusted clients. Keep typed errors where a library caller needs matching or recovery; an executable can convert to an ergonomic reporting error at its top-level boundary.

## Load next

- General propagation and context: `error-handling.md`
- Async cancellation: `async.md`
- Observability: `observability.md`
