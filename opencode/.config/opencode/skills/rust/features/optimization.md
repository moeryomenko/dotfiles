# Compiler Optimization (HIGH)

**Triggers**: inline, LTO, codegen-units, PGO, target-cpu, SIMD, #[inline], #[cold], optimization, release build, profile-guided, bounds check, monomorphization.

## Use `#[inline]` for Small Hot Functions

Guidance:
- `#[inline]` for small functions called from a different crate
- `#[inline(always)]` only for critical hot paths proven by profiling
- `#[inline(never)]` for error paths and cold functions to reduce code size

```rust
#[inline]
pub fn small_hot_function(x: i32) -> i32 {
    x + 1
}

#[cold]
#[inline(never)]
fn error_path() -> ! {
    panic!("unexpected state")
}
```

## Mark Unlikely Code Paths with `#[cold]`

Helps the compiler optimize for the common case:

```rust
#[cold]
fn handle_rate_limit() -> ! {
    std::process::exit(1);
}
```

## Use Code Structure to Hint at Likely Branches

Use `if`/`else` order to indicate which branch is more likely. On nightly, use `std::intrinsics::likely`/`unlikely`.

## Enable LTO in Release Builds

```toml
[profile.release]
lto = "fat"   # Full link-time optimization
```

## Set `codegen-units = 1` for Maximum Optimization

```toml
[profile.release]
codegen-units = 1  # Best optimization, slower compile
```

## Use Profile-Guided Optimization (PGO)

Collect profiles from representative runs, then rebuild with optimization guided by the profile data.

## Use `target-cpu=native` on Known Deployment Targets

```toml
[profile.release]
target-cpu = "native"  # Maximizes CPU-specific optimizations
```

## Use Iterators and Patterns That Eliminate Bounds Checks

Iterators track their bounds at compile time, eliminating runtime bounds checks:

```rust
// Bad: bounds checks on every access
for i in 0..slice.len() {
    process(slice[i]);
}

// Good: no bounds checks
for item in slice {
    process(item);
}
```

## Use Portable SIMD for Vectorized Operations

```rust
use std::simd::{f32x4, StdFloat};

let a = f32x4::from_array([1.0, 2.0, 3.0, 4.0]);
let b = f32x4::from_array([5.0, 6.0, 7.0, 8.0]);
let c = a + b;
```

## Organize Data for Cache-Efficient Access

Prefer struct-of-arrays over array-of-structs for hot paths. Access memory sequentially rather than randomly.

## Cross-References

- For runtime performance: load `performance`
- For memory layout: load `memory`
