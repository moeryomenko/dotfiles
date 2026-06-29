# Numeric & Arithmetic Safety (HIGH)

## Handle Integer Overflow Explicitly

Use `checked_`/`saturating_`/`wrapping_`/`overflowing_` methods instead of relying on overflow behavior:

```rust
// Checked - returns Option
let sum = a.checked_add(b)?;

// Saturating - clamps at min/max
let clamped = a.saturating_add(b);

// Wrapping - wraps around
let wrapped = a.wrapping_add(b);

// Overflowing - returns (result, overflowed)
let (result, overflowed) = a.overflowing_add(b);
```

## Avoid `as` for Narrowing Casts

Use `From` for safe widening conversions and `TryFrom` for narrowing:

```rust
// Widening - always safe, use From
let x: i64 = val.into();

// Narrowing - might truncate, use TryFrom
let x: i32 = val.try_into()?;
```

## Don't Compare Floats with `==`

Use a tolerance for equality comparisons, and `total_cmp` for ordering:

```rust
fn approx_eq(a: f64, b: f64, epsilon: f64) -> bool {
    (a - b).abs() < epsilon
}

// For sorting/ordering:
vec.sort_by(|a, b| a.total_cmp(&b));
```

## Bound Values with `clamp` and Saturating Arithmetic

```rust
let value = raw_value.clamp(min, max);
let saturated = a.saturating_add(b);
```

## Use `NonZero*` Types to Forbid Zero

`NonZeroU8`, `NonZeroU16`, `NonZeroU32`, etc. forbid zero at the type level and unlock niche optimization (e.g., `Option<NonZeroUsize>` is pointer-sized):

```rust
use std::num::NonZeroUsize;

let nz = NonZeroUsize::new(42).unwrap();
// Option<NonZeroUsize> is the same size as usize
```

## Cross-References

- For type system patterns: load `type-safety`
- For conversions: load `conversions`
