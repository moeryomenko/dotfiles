# Conversions

Make conversions visible at representation and trust boundaries. Implement standard conversion traits when their semantics are unsurprising and stable; use named constructors or methods when context, policy, or lossy behavior needs to be explicit.

## Standard traits

Use `From` for infallible, value-preserving conversions. Use `TryFrom` or `FromStr` when validation can fail, with a typed error when callers need to distinguish failure modes.

```rust
use std::str::FromStr;

struct Port(u16);

impl FromStr for Port {
    type Err = std::num::ParseIntError;

    fn from_str(value: &str) -> Result<Self, Self::Err> {
        Ok(Self(value.parse()?))
    }
}
```

If parsing needs semantic validation beyond the syntactic conversion, return an application error or expose a named `parse` constructor instead of forcing it into a generic conversion trait.

## Borrowing and mutation

Prefer a direct borrowed interface when that is the actual contract:

```rust
fn reset(data: &mut [u8]) {
    data.fill(0);
}
```

`impl AsMut<[u8]>` is appropriate only when accepting multiple owning/container forms provides real API value; bind it as `mut data` before calling `data.as_mut()`.

Avoid lossy `as` casts at external or numeric boundaries. Use checked/explicit conversions and document truncation, rounding, encoding, and ownership behavior.

## Load next

- Error representation: `error-handling.md`
- Public conversion APIs: `api-design.md`
- Numeric casts: `numeric.md`
