---
name: domain-web
description: Use when building web services in Rust. Keywords: web server, HTTP, REST API, axum, actix, warp, tower, middleware, extractors, state management, authentication, JWT, CORS, rate limiting, WebSocket.
---

# Domain: Web (Rust)

**Triggers**: web server, HTTP, REST API, axum, actix-web, warp, rocket, tower, hyper, reqwest, middleware, router, handler, extractor, state management, auth, JWT, session, cookie, CORS, rate limiting.

## Domain Constraints -> Design Implications

| Domain Rule | Design Constraint | Rust Implication |
|-------------|-------------------|------------------|
| Stateless HTTP | No request-local globals | State in extractors |
| Concurrency | Handle many connections | Async, Send + Sync |
| Latency SLA | Fast response | Efficient ownership |
| Security | Input validation | Type-safe extractors |
| Observability | Request tracing | tracing + tower layers |

---

## Critical Constraints

### Async by Default

```
RULE: Web handlers must not block
WHY: Blocking one async task blocks other requests
RUST: async/await, spawn_blocking for CPU work
```

### State Management

```
RULE: Shared state must be thread-safe
WHY: Handlers can run on any thread
RUST: Arc<T>, Arc<RwLock<T>> for mutable state
```

### Request Lifecycle

```
RULE: Resources live only for request duration
WHY: Memory management, no leaks
RUST: Extractors with proper ownership
```

---

## Framework Comparison

| Framework | Style | Best For |
|-----------|-------|----------|
| axum | Functional, tower-based | Modern REST APIs |
| actix-web | Actor-based | High throughput |
| warp | Filter composition | Composable APIs |
| rocket | Macro-driven | Rapid prototyping |

## Key Crates

| Purpose | Crate |
|---------|-------|
| HTTP server | axum, actix-web |
| HTTP client | reqwest |
| JSON | serde_json |
| Auth/JWT | jsonwebtoken |
| Session | tower-sessions |
| Database | sqlx, diesel |
| Middleware | tower |

## Design Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| Extractors | Request parsing | `State(db)`, `Json(payload)` |
| Error response | Unified errors | `impl IntoResponse` |
| Middleware | Cross-cutting | Tower layers |
| Shared state | App config | `Arc<AppState>` |

## Code Pattern: Axum Handler

```rust
async fn handler(
    State(db): State<Arc<DbPool>>,
    Json(payload): Json<CreateUser>,
) -> Result<Json<User>, AppError> {
    let user = db.create_user(&payload).await?;
    Ok(Json(user))
}

// Error handling
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            Self::NotFound => (StatusCode::NOT_FOUND, "Not found"),
            Self::Internal(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Internal error"),
        };
        (status, Json(json!({"error": message}))).into_response()
    }
}
```

---

## Common Mistakes

| Mistake | Domain Violation | Fix |
|---------|-----------------|-----|
| Blocking in handler | Latency spike | spawn_blocking |
| Rc in state | Not Send + Sync | Use Arc |
| No validation | Security risk | Type-safe extractors |
| No IntoResponse for errors | Bad UX | Implement IntoResponse |

## Layer Mapping

| Constraint | Feature File |
|------------|--------------|
| Async handlers | load `features/async.md` |
| Thread-safe state | load `features/concurrency.md` |
| Request lifecycle | load `features/lifecycle.md` |
| Middleware composition | load `features/traits.md` |
