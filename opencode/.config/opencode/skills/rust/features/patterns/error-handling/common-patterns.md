# Error-Handling Patterns

Choose `Option` for meaningful absence and `Result` for failures callers need to observe or recover from. Error representation follows API boundaries and recovery needs, not whether a crate is called a library or application.

## Typed boundaries and reporting

Expose typed, matchable errors where a caller needs distinctions such as invalid input, retryability, or compatibility. Use a report type such as `anyhow::Error` at an executable boundary that owns final presentation.

```rust
#[derive(Debug, thiserror::Error)]
enum ConfigError {
    #[error("failed to read configuration")]
    Read(#[from] std::io::Error),
    #[error("configuration has no endpoint")]
    MissingEndpoint,
}
```

`#[from]` belongs on a permitted single-field source variant. Add separate variants or constructors when the conversion requires extra context.

## Propagation and context

Propagate with `?` where the current layer adds no semantic information. Add context when opening a named resource, converting an external format, or crossing an ownership/domain boundary. Log or render a failure once at a deliberate handling boundary rather than at each propagation layer.

```rust
use anyhow::{Context, Result};

fn load(path: &std::path::Path) -> Result<String> {
    std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {}", path.display()))
}
```

## Intentional non-fatal failures

Ignore an error only after confirming it is harmless to the contract. Match the expected condition and propagate or report unexpected errors:

```rust
match std::fs::remove_file("cache.tmp") {
    Ok(()) => {}
    Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
    Err(error) => return Err(error),
}
```

For partial iterator results, `partition(Result::is_ok)` produces `Vec<Result<T, E>>` on both sides; it does not unwrap values/errors. Explicitly convert those results, or use a helper whose output contract is understood.

`expect` documents a local invariant when a panic is contractually appropriate; it is not ordinary error handling.

## Load next

- Error API design: `../../error-handling.md`
- Retrying/fault boundaries: `../../domain-error.md`
- Async cancellation: `../async/common-patterns.md`
