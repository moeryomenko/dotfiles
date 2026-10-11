---
name: domain-web
description: Use when building Rust HTTP services or clients, including handlers, middleware, state, extractors, authentication, and runtime behavior.
---

# Rust Web Guidance

Inspect the selected framework, runtime, feature flags, deployment model, and service-level objectives before choosing handler shapes or shared state. Framework APIs and required `Send`/`Sync` bounds vary, so do not transfer patterns blindly between Axum, Actix Web, Hyper, Tower, or other stacks.

## Handler work and runtime health

Do not perform unbounded blocking work on an async runtime worker. A blocking task may delay other work sharing that worker; the impact depends on the runtime topology and load. For blocking I/O, use an asynchronous client when practical. For bounded CPU or blocking work, use the framework/runtime's approved offload mechanism and bound concurrency. Sustained CPU workloads may instead need a worker pool, Rayon, or an external worker system.

Keep lock guards across `.await` only with a deliberate runtime and contention analysis. Prefer taking a snapshot, narrowing the critical section, or redesigning ownership when possible. Tokio's async synchronization primitives may intentionally support a guard across an await, but that does not remove deadlock, latency, or queueing concerns.

## State and lifetime

Application-scoped resources commonly include immutable configuration, pools, clients, caches, metrics, and background-service handles. They usually outlive an individual request. Make state shareable only where the framework and topology require it:

- immutable, cheap-to-clone handles may need no lock;
- connection pools and clients commonly provide their own concurrency control;
- mutable in-process state needs an explicit consistency and contention design;
- `Arc<RwLock<T>>` is one option, not a default.

`Rc` is unsuitable for state required to cross threads or for futures that must be `Send`, but can be valid in a deliberately local, single-threaded configuration.

## Input, authentication, and responses

Framework extractors parse and deserialize; they do not replace semantic validation, authorization, body-size limits, content-type policy, rate limiting, or CSRF/CORS policy. Validate at the HTTP boundary, convert into domain types, and avoid exposing internal errors in responses.

Use a single application error-to-response policy that maps expected client errors deliberately and logs unexpected failures with request context at an appropriate boundary. Do not treat an HTTP status mapping as the full error-reporting strategy.

```rust
// Axum-shaped excerpt: imports and application types are intentionally omitted.
async fn create_user(
    State(state): State<AppState>,
    Json(request): Json<CreateUser>,
) -> Result<Json<User>, AppError> {
    let input = request.validate()?;
    let user = state.users.create(input).await?;
    Ok(Json(user))
}
```

## Operational choices

Add request IDs, tracing spans, timeouts, backpressure, health endpoints, and graceful shutdown according to the service's deployment and observability requirements. Treat authentication, secrets, TLS, and rate limits as system policies rather than handler-local details.

## Load next

- Runtime, cancellation, task ownership: `features/async.md`
- Locks, atomics, and parallel work: `features/concurrency.md`
- Error boundaries: `features/error-handling.md`, `features/domain-error.md`
- Structured diagnostics: `features/observability.md`
- API types and compatibility: `features/api-design.md`, `features/serde.md`
