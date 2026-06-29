# Conversions (MEDIUM)

## Implement `TryFrom` for Fallible Conversions

Use instead of ad-hoc conversion functions:

```rust
struct Point { x: i32, y: i32 }

impl TryFrom<(i32, i32)> for Point {
    type Error = String;
    
    fn try_from((x, y): (i32, i32)) -> Result<Self, Self::Error> {
        if x >= 0 && y >= 0 {
            Ok(Self { x, y })
        } else {
            Err("coordinates must be non-negative".into())
        }
    }
}
```

## Implement `FromStr` to Enable `str::parse`

```rust
use std::str::FromStr;

impl FromStr for MyId {
    type Err = ParseError;
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let n: u64 = s.parse()?;
        Ok(Self(n))
    }
}

// Usage:
let id: MyId = "42".parse()?;
```

## Accept `impl AsMut<T>` for Flexible Mutable Inputs

Instead of concrete mutable references:

```rust
fn reset(data: impl AsMut<[u8]>) {
    data.as_mut().fill(0);
}
```

## Cross-References

- For error handling patterns: load `error-handling`
- For API design conventions: load `api-design`
