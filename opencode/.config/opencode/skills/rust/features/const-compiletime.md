# Const and Compile-Time Evaluation

Use compile-time evaluation when the value and operations are supported by the crate's MSRV and the result improves correctness, initialization, or API shape. Do not assume a runtime-looking expression is const-evaluable across toolchains.

## Constants, statics, and inline const

`const` defines a value item without a stable address identity. `static` defines one addressed storage location and may need synchronization for mutation. Neither description guarantees a particular inlining or code-generation result.

An inline const is an expression-level construct:

```rust
let size = const {
    let mut index = 0;
    let mut total = 0;
    let values = [2, 3, 5];
    while index < values.len() {
        total += values[index];
        index += 1;
    }
    total
};
assert_eq!(size, 10);
```

The set of operations permitted in const contexts evolves. Prefer a const-compatible `while` loop when targeting an MSRV where iterator traits or `for` behavior in const evaluation is not available.

## `const fn` and const generics

Mark a function `const fn` when compile-time callers materially benefit and its constraints remain suitable for the MSRV. It can still run at runtime. Const generics fit types parameterized by a compile-time value, such as `[T; N]`; avoid them when a runtime collection is simpler or where bounds become disproportionately complex.

## Load next

- Numeric bounds: `numeric.md`
- Type-level modeling: `type-driven.md`
- Toolchain/MSRV policy: `project-structure.md`
