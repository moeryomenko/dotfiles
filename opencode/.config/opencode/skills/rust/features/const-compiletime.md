# Const & Compile-Time (MEDIUM)

## Use Inline `const { }` Blocks for Compile-Time Evaluation

```rust
const SIZE: usize = {
    let mut count = 0;
    for item in DATA {
        count += item.len();
    }
    count
};
```

## Make Functions `const fn` When They Can Run at Compile Time

```rust
const fn factorial(n: u64) -> u64 {
    let mut result = 1;
    let mut i = 2;
    while i <= n {
        result *= i;
        i += 1;
    }
    result
}

const FACT_10: u64 = factorial(10);
```

## Use Const Generics for Value Parameterization

```rust
struct FixedArray<T, const N: usize> {
    data: [T; N],
}

impl<T, const N: usize> FixedArray<T, N> {
    fn len(&self) -> usize { N }
}
```

## Use `const` for Inlined Values and `static` for Single Addressed Instances

```rust
// Inlined at every use site
const BUFFER_SIZE: usize = 4096;

// Single memory address
static LOG_LEVEL: AtomicU8 = AtomicU8::new(3);
```

## Cross-References

- For numeric types: load `numeric`
- For type system: load `type-safety`
