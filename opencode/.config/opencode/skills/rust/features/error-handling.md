# Error Handling

Design errors from the caller's recovery and diagnostic needs. Keep failure information structured at reusable boundaries; add context at meaningful semantic transitions; report or log once at a chosen handling boundary.

## Error types and reporting types

A library should expose a typed error when callers need to distinguish causes, retry behavior, or compatibility. `thiserror` is useful for implementing `std::error::Error` without changing the public semantics. An executable boundary can use an ergonomic report type such as `anyhow::Error` when it owns final presentation.

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ParseError {
    #[error("invalid syntax at line {line}")]
    Syntax { line: usize },
    #[error("failed to read input")]
    Io(#[from] std::io::Error),
}
```

`#[from]` both marks an error source and generates a conversion only when the variant shape permits it. Add separate context fields with a dedicated variant or constructor when needed.

## Propagation and context

Use `?` to preserve the error flow where the current layer adds no useful meaning. Add `context` or `with_context` at operations such as opening a named resource, crossing a protocol boundary, or translating into a domain action—not mechanically at every fallible expression.

```rust
use anyhow::{Context, Result};

fn load_config(path: &std::path::Path) -> Result<String> {
    std::fs::read_to_string(path)
        .with_context(|| format!("failed to read configuration at {}", path.display()))
}
```

Avoid logging the same error at every propagation layer; logs multiply without improving diagnosis. Preserve source chains and ensure final reports render them according to the application's observability setup.

## Panics and expectations

Return `Result` for recoverable input, I/O, and external failures. `expect` is appropriate when an explicit, local invariant would make failure a bug; include that invariant in the message. `unwrap` in production code is acceptable only when the invariant is equally clear and a panic is contractually acceptable—not merely because error handling is inconvenient.

Document error conditions for public fallible APIs where callers need them. Error-message capitalization/punctuation should follow repository and user-interface conventions rather than a universal style rule.

## Load next

- Retry and fault boundaries: `domain-error.md`
- Async cancellation/error ownership: `async.md`
- Error-pattern examples: `patterns/error-handling/common-patterns.md`
- Public contracts: `api-design.md`
