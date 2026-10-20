# Numeric and Arithmetic Safety

Choose numeric behavior as part of the domain contract: valid range, overflow result, rounding, NaN/infinity policy, representation, and error reporting. Debug and release overflow behavior is not a substitute for that decision.

## Integer operations and casts

Use the operation matching the intended result:

- `checked_*` when overflow must be reported;
- `saturating_*` when clamping is explicitly correct;
- `wrapping_*` for modulo arithmetic;
- `overflowing_*` when both value and overflow flag are meaningful.

Use `From` for guaranteed conversions and `TryFrom` or explicit validation for narrowing/possibly lossy conversion. An `as` cast can be intentional for low-level or protocol code, but should be visibly justified at a boundary.

## Floating-point policy

Exact equality is correct for some cases (for example, values produced by the same discrete operation), and inappropriate for others. Define comparison policy from the algorithm: absolute tolerance near zero, relative tolerance across magnitudes, and a deliberate NaN/infinity policy. ULP comparison may suit particular numerical algorithms.

```rust
fn approx_eq(a: f64, b: f64, absolute: f64, relative: f64) -> bool {
    if a == b {
        return true;
    }
    if !a.is_finite() || !b.is_finite() {
        return false;
    }
    (a - b).abs() <= absolute.max(relative * a.abs().max(b.abs()))
}
```

Use `total_cmp` when a total order is needed, such as sorting `f64` values; it is not an approximate-equality operation.

## Domain types

Use `NonZero*` types when zero is invalid and their API benefits fit the type. For money, measurements, timestamps, and protocol fields, select a representation with the required scale, range, serialization, and rounding behavior.

## Load next

- Conversion boundaries: `conversions.md`
- Domain-specific financial representation: `../domain-fintech/SKILL.md`
- Newtypes/invariants: `type-safety.md`
