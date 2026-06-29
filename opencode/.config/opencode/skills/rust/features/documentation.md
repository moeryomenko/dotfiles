# Documentation (MEDIUM)

## Document All Public Items with `///` Doc Comments

Every public function, struct, trait, enum, type, constant, and module needs documentation.

## Use `//!` for Module-Level Documentation

```rust
//! This module provides parsing utilities.
//!
//! It includes tokenizers, AST builders, and error types.
```

## Include Standard Doc Sections

| Section | When |
|---------|------|
| `# Examples` | On all public items (with runnable code) |
| `# Errors` | On fallible functions |
| `# Panics` | On functions that can panic |
| `# Safety` | On unsafe functions |

```rust
/// Parses a configuration string.
///
/// # Examples
/// ```
/// let config = parse("key=value")?;
/// assert_eq!(config.get("key"), Some("value"));
/// ```
///
/// # Errors
/// Returns `ParseError` if the input is malformed.
///
/// # Panics
/// Panics if the internal buffer overflows (only for strings > 1MB).
fn parse(input: &str) -> Result<Config, ParseError> { /* ... */ }
```

## Use `?` in Examples, Not `.unwrap()`

```rust
/// ```
/// use my_crate::parse;
/// let config = parse("key=value")?;
/// # Ok::<(), my_crate::Error>(())
/// ```
```

## Use `# ` Prefix to Hide Example Setup Code

```rust
/// ```
/// # use my_crate::Config;
/// # let mut config = Config::new();
/// config.set("key", "value");  // Only this line is visible
/// ```
```

## Use Intra-Doc Links to Reference Types

```rust
/// See also [`Config`] and [`parse`](crate::parse::parse).
```

## Fill `Cargo.toml` Metadata

```toml
[package]
name = "my-crate"
version = "0.1.0"
description = "A concise description"
authors = ["Author Name"]
license = "MIT OR Apache-2.0"
repository = "https://github.com/user/my-crate"
documentation = "https://docs.rs/my-crate"
readme = "README.md"
keywords = ["rust", "cli", "tool"]
categories = ["command-line-utilities"]
edition = "2021"
```

## Unify README and Crate Root Docs

```rust
//! # My Crate
//!
//! [![crates.io](https://img.shields.io/crates/v/my-crate.svg)](https://crates.io/crates/my-crate)
//!
#![doc = include_str!("../README.md")]
```

## Cross-References

- For doc examples that test: load `testing`
- For safety sections in docs: load `unsafe`
