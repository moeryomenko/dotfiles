# Documentation

Document public contracts where a caller needs information not expressed by the type system: purpose, valid input, ownership, effects, errors, panics, safety preconditions, ordering, and compatibility. Follow the repository's public-documentation policy rather than requiring every item to have the same sections or a runnable example.

Use `///` for item documentation and `//!` for module or crate documentation. Intra-doc links are useful when a referenced API is part of the reader's next decision.

## Examples

Doctests should compile when they claim to be runnable. A snippet using `?` needs a result-returning context:

```rust
/// Parses a configuration value.
///
/// ```
/// # fn run() -> Result<(), ParseError> {
/// let config = parse("key=value")?;
/// assert_eq!(config.get("key"), Some("value"));
/// # Ok(())
/// # }
/// ```
/// # Errors
/// Returns `ParseError` when the input is malformed.
fn parse(_: &str) -> Result<Config, ParseError> { todo!() }
# struct Config;
# impl Config { fn get(&self, _: &str) -> Option<&str> { Some("value") } }
# struct ParseError;
```

Hide setup lines with `# ` when that improves readability, but retain enough visible context for users to understand correct use. Mark platform-, feature-, network-, or deliberately illustrative examples accordingly instead of presenting them as universal doctests.

## Crate documentation and metadata

A crate-level inner attribute must appear at the crate root before items:

```rust
#![doc = include_str!("../README.md")]

pub struct Client;
```

Use README inclusion only when the README is appropriate crate API documentation and the path works for the crate layout. Package metadata, repository links, license, categories, MSRV, and examples are publication decisions; keep them accurate rather than copying a generic template.

## Load next

- Documentation tests: `testing.md`
- Unsafe contracts: `unsafe.md`
- Public API design: `api-design.md`
