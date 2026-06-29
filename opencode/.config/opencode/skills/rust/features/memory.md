# Memory Optimization (CRITICAL)

**Triggers**: allocation, heap, memory, capacity, with_capacity, SmallVec, Box, arena, zero-copy, compact, shrink, reuse, leak, memory optimization, reduce allocation, pre-allocate.

## Use `with_capacity()` When Size Is Known

Pre-allocating avoids multiple reallocations as collections grow.

```rust
let mut results = Vec::with_capacity(1000);
let mut map = HashMap::with_capacity(pairs.len());
let estimated = words.iter().map(|w| w.len() + 1).sum();
let mut output = String::with_capacity(estimated);
```

## Use `SmallVec` for Usually-Small Collections

When a collection is typically small but occasionally large, `SmallVec` stores the small case on the stack.

```rust
use smallvec::{smallvec, SmallVec};

let mut vec: SmallVec<[i32; 4]> = smallvec![1, 2, 3];
// No heap allocation until more than 4 elements
```

## Use `ArrayVec` for Fixed-Capacity Collections

For collections that never exceed a known maximum, `ArrayVec` allocates entirely on the stack.

## Box Large Enum Variants

When an enum has a variant much larger than others, `Box` the large variant to reduce overall enum size:

```rust
enum Message {
    Small(String),                    // 24 bytes
    Large(Box<HugeDataStructure>),    // 8 bytes on stack, data on heap
}
```

## Use `Box<[T]>` Instead of `Vec<T>` for Fixed-Size Heap Data

Once a `Vec` stops growing, shrink it to a boxed slice to reclaim unused capacity:

```rust
let vec: Vec<u8> = (0..100).collect();
let slice: Box<[u8]> = vec.into_boxed_slice();  // Shrinks to exact size
```

## Use `clone_from()` to Reuse Allocations

```rust
let mut dest = String::with_capacity(100);
// Instead of: dest = source.clone();
dest.clone_from(&source);  // Reuses existing capacity
```

## Clear and Reuse Collections in Loops

```rust
let mut buffer = Vec::with_capacity(1024);
for chunk in data.chunks(1024) {
    buffer.clear();    // Reuses allocation
    buffer.extend(chunk);
    process(&buffer);
}
```

## Avoid `format!()` When String Literals Work

```rust
// Bad: allocates a String
let msg = format!("error");

// Good: &'static str
let msg = "error";
```

## Use `write!()` Into Existing Buffers Instead of `format!()`

```rust
use std::fmt::Write;

let mut output = String::with_capacity(100);
write!(output, "value: {}", 42).unwrap();  // Reuses buffer
```

## Use Arena Allocators for Batch Allocations

For workloads that allocate many short-lived objects, arena allocators (like `bumpalo` or `typed-arena`) provide significant savings.

## Use Zero-Copy Patterns with Slices and `Bytes`

Use `Cow<'a, str>` or `bytes::Bytes` to share underlying buffers instead of copying.

## Use Compact String Types

For memory-constrained environments, use `compact_str` or `smol_str` instead of `String`.

## Use Appropriately-Sized Integers

Prefer `u32`/`i32` over `u64`/`i64` when the value range fits, especially in large arrays or collections.

## Use Static Assertions to Guard Against Type Size Growth

```rust
use static_assertions::assert_eq_size;

assert_eq_size!(MyStruct, [u8; 64]);
```

## Use `mem::take` / `mem::replace` to Move Out of `&mut` Without Cloning

```rust
let old = mem::take(&mut vec);  // Replaces with default/empty
```

## Know and Control Drop Order

Struct fields drop top-to-bottom, locals in reverse declaration order. Use `ManuallyDrop` to control drop order when necessary.

## Cross-References

- For performance patterns: load `performance`
- For ownership patterns: load `ownership`
- For collection choices: load `collections`
