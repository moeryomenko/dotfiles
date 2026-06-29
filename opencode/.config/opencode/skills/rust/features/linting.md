# Clippy & Linting (LOW)

## Enable `clippy::correctness` as Deny

```rust
#![deny(clippy::correctness)]
```

## Enable Clippy Warning Groups

```rust
#![warn(clippy::suspicious)]    // Likely bugs
#![warn(clippy::style)]        // Idiomatic code
#![warn(clippy::complexity)]   // Simpler alternatives
#![warn(clippy::perf)]         // Performance improvements
```

## Enable Pedantic Lints Selectively

```rust
#![warn(clippy::pedantic)]
// Silence specific noisy lints:
#![allow(clippy::module_name_repetitions)]
#![allow(clippy::must_use_candidate)]
```

## Warn on Missing Documentation

```rust
#![warn(missing_docs)]  // For public items
```

## Require Documentation for Unsafe Blocks

```rust
#![warn(clippy::undocumented_unsafe_blocks)]
```

## Enable Clippy::Cargo for Published Crates

```rust
#![warn(clippy::cargo)]
```

## Run `cargo fmt --check` in CI

## Configure Lints at Workspace Level

```toml
# Cargo.toml (workspace root)
[lints]
workspace = true

[lints.clippy]
correctness = "deny"
suspicious = "warn"
style = "warn"
complexity = "warn"
perf = "warn"
pedantic = "warn"
```

## Enable `unexpected_cfgs` and Declare Known Cfgs

```rust
// In Cargo.toml
[lints.rust]
unexpected_cfgs = { level = "warn", check-cfg = ['cfg(feature, values("serde"))'] }
```

## Enable High-Value Nursery Lints Selectively

```rust
#![warn(clippy::semicolon_if_nothing_returned)]
#![warn(clippy::missing_panics_doc)]
```

## Cross-References

- For unsafe linting: load `unsafe`
- For docs and lints: load `documentation`
