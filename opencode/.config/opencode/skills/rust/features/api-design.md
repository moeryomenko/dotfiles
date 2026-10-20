# API Design

Design public APIs from caller needs and compatibility commitments. Inspect the crate's MSRV, edition, public feature flags, serialization formats, and semver policy before changing an exposed type, trait, error, or method.

## Boundaries and construction

Validate and convert untrusted input at the boundary, then expose domain types that preserve the invariant. Use a builder when construction has independent optional settings, validation needs accumulated context, or positional arguments would be unclear; a constructor is clearer for a small required set.

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UserId(u64);

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UserIdError {
    Zero,
}

impl UserId {
    pub fn new(value: u64) -> Result<Self, UserIdError> {
        if value == 0 { return Err(UserIdError::Zero); }
        Ok(Self(value))
    }
}
```

Accept `&str`, `&[T]`, or a concrete type when that expresses the actual requirement. Use `impl Into<T>` or `AsRef<T>` only where accepting alternatives meaningfully helps callers without obscuring conversions, inference, or error behavior.

## Traits and extensibility

Use a sealed trait only when external implementations would undermine invariants or future evolution. Use extension traits to add a coherent operation to external types, not as a namespace substitute. Implement `From` for infallible, unsurprising conversions; use `TryFrom` where conversion can fail.

`#[must_use]` fits values whose accidental discard is plausibly a bug. `#[non_exhaustive]` is a deliberate forward-compatibility commitment that changes downstream construction and matching ergonomics; apply it before releasing the public type, not reflexively.

Derive or implement traits such as `Debug`, `Clone`, `Eq`, `Hash`, and `Default` only when their semantics, cost, and compatibility are appropriate. These implementations are part of the public contract.

## Compatibility

Preserve source, behavioral, serialization, and error-handling compatibility unless the release intentionally permits a break. Model optional integrations as features only when the dependency and API shape are actually optional; verify feature names and dependency configuration in `Cargo.toml`.

## Load next

- Type distinctions and representation: `type-safety.md`, `type-driven.md`
- Conversion details: `conversions.md`
- Serialization contracts: `serde.md`
- Error contracts: `error-handling.md`
