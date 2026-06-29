# Performance Patterns (MEDIUM)

**Triggers**: performance, slow, hot path, iterator, entry API, drain, reuse, batch, buffer, profile, benchmark, flamegraph, bottleneck, optimize, BufReader, BufWriter.

## Prefer Iterators Over Manual Indexing

```rust
// Bad: bounds checks and manual index management
for i in 0..items.len() {
    process(items[i]);
}

// Good: no bounds checks, clearer
for item in items {
    process(item);
}
```

## Keep Iterators Lazy

Collect only when needed:

```rust
// Bad: allocates intermediate Vec
let processed: Vec<_> = items.iter().map(f).collect();
for item in &processed {
    use_in_loop(item);
}

// Good: lazy, no intermediate allocation
for item in items.iter().map(f) {
    use_in_loop(item);
}
```

## Use Entry API for Map Insert-or-Update

```rust
use std::collections::HashMap;

let mut counts = HashMap::new();
for word in words {
    // Bad: double lookup
    // if counts.contains_key(word) {
    //     *counts.get_mut(word).unwrap() += 1;
    // } else {
    //     counts.insert(word, 1);
    // }

    // Good: single lookup
    *counts.entry(word).or_insert(0) += 1;
}
```

## Use `drain` to Reuse Allocations

```rust
let mut buffer = Vec::with_capacity(1024);
for chunk in data.chunks(1024) {
    buffer.extend(chunk);
    let processed: Vec<_> = buffer.drain(..).map(process).collect();
    // buffer retains capacity
}
```

## Use `extend` for Batch Insertions

```rust
// Bad: push in a loop
for item in items {
    dest.push(transform(item));
}

// Good: single batch operation
dest.extend(items.into_iter().map(transform));
```

## Avoid `chain` in Hot Loops

`chain` can inhibit iterator optimizations in tight loops.

## Use `collect_into` for Reusing Containers

```rust
#![feature(iter_collect_into)]

let mut buffer = Vec::with_capacity(1000);
items.iter().map(f).collect_into(&mut buffer);
```

## Use `black_box` in Benchmarks

Prevents the compiler from optimizing away the benchmarked computation:

```rust
use std::hint::black_box;

c.bench_function("compute", |b| {
    b.iter(|| compute(black_box(42)))
});
```

## Optimize Release Profile Settings

```toml
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
strip = true
```

## Profile Before Optimizing

Use `perf`, `flamegraph`, `cargo flamegraph`, or `tokio-console` to identify real bottlenecks before optimizing.

## Use a Faster Hasher When DoS Resistance Is Not Needed

```rust
use rustc_hash::FxHashMap;  // Faster than default SipHash
use ahash::AHashMap;       // Very fast, good quality
```

## Wrap `Read`/`Write` in `BufReader`/`BufWriter`

```rust
let file = File::open("data.txt")?;
let reader = BufReader::new(file);  // Buffered for many small reads
```

## Cross-References

- For compiler optimization: load `optimization`
- For memory optimization: load `memory`
- For collection choices: load `collections`
