# Error Handling (CRITICAL)

**Triggers**: Result, Option, Error, ?, unwrap, expect, panic, anyhow, thiserror, recoverable error, fallible, error propagation, error chaining, context, From, try.

## Use `thiserror` for Library Error Types

Libraries should expose typed, matchable errors. `thiserror` generates `Error` trait implementations with minimal boilerplate.

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParseError {
    #[error("invalid syntax at line {line}: {message}")]
    Syntax { line: usize, message: String },
    #[error("io error reading input")]
    Io(#[from] std::io::Error),
}
```

Key attributes: `#[error("...")]` for messages, `#[from]` for automatic `From` impls, `#[source]` for error chaining, `#[error(transparent)]` for delegation.

## Use `anyhow` for Application Error Handling

Applications benefit from `anyhow::Result` and `.context()` for ergonomic error handling with rich context.

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let path = format!("users/{}.json", id);
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read {}", path))?;
    Ok(serde_json::from_str(&content)?)
}
```

## Return `Result<T, E>` Instead of Panicking for Recoverable Errors

Panics unwind the stack and crash the thread. `Result` gives callers the choice to retry, fallback, propagate, or log.

**Panic is appropriate for:** invariant violations (bugs), initialization failures where the program cannot proceed, tests, and examples.

## Use `?` Operator for Clean Propagation

The `?` operator is Rust's idiomatic way to propagate errors, automatically converting between compatible error types via `From`.

```rust
fn load_config() -> Result<Config, Error> {
    let content = std::fs::read_to_string("config.toml")?;
    Ok(toml::from_str(&content)?)
}
```

`?` works with `Option` too:
```rust
fn get_first_word(text: &str) -> Option<&str> {
    let first_line = text.lines().next()?;
    first_line.split_whitespace().next()
}
```

## Add Context with `.context()` or `.with_context()`

Always add context when propagating errors to make debugging easier:

```rust
.content(|| "failed to read config")
// vs
.context("failed to read config")  // For simple strings
```

## Avoid `unwrap()` in Production Code

Use `?`, `.expect()`, or handle errors properly. Reserve `unwrap()` for tests and truly impossible cases.

## Use `expect()` Only for Invariants That Indicate Bugs

```rust
let value = cache.get(key).expect("key was just inserted");
```

## Implement `From<E>` for Error Conversions

This enables the `?` operator to convert between error types automatically. `thiserror`'s `#[from]` generates these.

## Preserve Error Chains

Use `#[source]` (thiserror) or implement `source()` to preserve error chains. Log errors with their full source chain.

## Start Error Messages Lowercase, No Trailing Punctuation

Consistent with standard library conventions:
```rust
#[error("invalid value: {0}")]  // ✅ lowercase, no period
#[error("Invalid value: {0}.")]  // ❌
```

## Document Error Conditions

Include `# Errors` section in doc comments for fallible functions:
```rust
/// Parses a configuration string.
///
/// # Errors
/// Returns `ParseError` if the input is malformed or contains invalid values.
```

## Define Custom Error Types for Domain-Specific Failures

Custom error types carry domain semantics and can include relevant context fields.

## Cross-References

- For type definitions: load `type-safety`
- For doc sections: load `documentation`
- For unwrap anti-patterns: load `anti-patterns`
- For Result in async: load `async`
- For domain error strategies: load `domain-error`
- For error recovery and retry: load `domain-error`
- For error handling patterns with examples: load `patterns/error-handling/common-patterns.md`
