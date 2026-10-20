# Memory and Allocation

Optimize allocation count, retained memory, and layout only after identifying a workload and a measurable bottleneck. Allocation avoidance can worsen locality, lifetime complexity, or destructor behavior.

## Capacity and reuse

Use capacity hints when a credible size estimate avoids observed growth. A bad estimate or one-off allocation can be less useful than straightforward code.

```rust
let mut output = String::with_capacity(estimated_bytes);
for part in parts {
    output.push_str(part);
}
```

Reuse an allocation with `clear`, `clone_from`, or a caller-owned buffer when ownership and retention are explicit. Do not retain a very large buffer indefinitely merely because reuse is possible.

## Layout choices

`SmallVec`, `ArrayVec`, compact strings, arenas, and boxed variants are workload-specific tools:

- `SmallVec` stores an inline capacity in the container and allocates only after it is exceeded.
- `ArrayVec` stores elements inline in the container; whether the container itself is stack, heap, or static allocated depends on where it is stored.
- `Box<T>` can reduce an enum's inline size but adds allocation, pointer indirection, and locality costs.
- `Vec<T>::into_boxed_slice()` can discard spare capacity when growth is complete, subject to allocation behavior.
- Arenas can help batch allocation, but retained arenas delay all contained drops and can increase peak memory.

Select narrower integer types only when their range, alignment, serialization, and interoperability remain correct. Inspect actual type layout when it matters; do not infer it from source shape.

## Zero-copy and sharing

Borrowed slices, `Cow`, `bytes::Bytes`, and reference-counted buffers can reduce copying when lifetimes and ownership match the pipeline. They can also retain large backing allocations or complicate APIs. Choose them from observed data flow, not as a default.

## Formatting

Use literals rather than `format!` when no formatting is needed. Write into an existing `String` only when buffer reuse or incremental formatting matters, and handle formatting errors according to the destination:

```rust
use std::fmt::Write;

let mut output = String::new();
write!(&mut output, "value: {}", 42).expect("writing to String cannot fail");
```

## Load next

- Borrowing and cloning semantics: `ownership.md`
- Collection selection: `collections.md`
- Measured runtime behavior: `performance.md`, `optimization.md`
- Cleanup/lifetime tradeoffs: `lifecycle.md`
