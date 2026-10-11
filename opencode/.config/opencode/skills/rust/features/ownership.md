# Ownership and Borrowing

Start from the API boundary: does this operation borrow, consume, retain, mutate, or share a value? Prefer the narrowest ownership contract that expresses that requirement, not an automatic clone or reference.

## Borrowed inputs and returned data

Accept `&str`, `&[T]`, or `&T` when the operation only needs to inspect data. These are references and deref coercions—not conversions of owned values themselves:

```rust
fn summarize(name: &str, values: &[i64]) -> i64 {
    println!("{name}");
    values.iter().sum()
}

let name = String::from("daily");
let values = vec![2, 3, 5];
assert_eq!(summarize(&name, &values), 10);
```

Clone when the receiving side must own an independent value, when a value outlives its lender, or when the clone is the clearest semantic operation. `Clone` can be allocation-free for some types and can allocate for others; measure material hot paths rather than assuming either outcome.

Use `Cow<'a, T>` when an API genuinely has both borrowed and owned outcomes and callers benefit from that distinction. Do not introduce it merely to avoid a cheap clone.

## Shared and interior mutability

Choose a synchronization design from the required access and invariants:

| Need | Typical fit |
|---|---|
| One owner, ordinary mutation | `T` / `&mut T` |
| Shared read-only ownership on one thread | `Rc<T>` |
| Shared read-only ownership across threads | `Arc<T>` |
| Runtime-checked mutable borrowing on one thread | `RefCell<T>` |
| Cross-thread mutable shared state | `Mutex<T>`, `RwLock<T>`, or a message-passing design |

`RwLock` helps only when its read/write behavior, contention, and fairness characteristics fit the workload. A lock protects data; it does not define a complete multi-object consistency protocol.

## `Copy`, moves, and replacement

Implement `Copy` only when implicit duplication matches the type's public semantics and will remain a reasonable API commitment. Small, plain value types often qualify; small types with identity, invalidation, or meaningful copy cost may not. Heap-owning types cannot implement `Copy`.

Moving a value is usually inexpensive metadata movement. `Box<T>` changes layout by introducing allocation and indirection; use it for recursive types, enum-size control, ownership boundaries, or measured movement/locality tradeoffs—not as a general response to a large type.

Use `mem::take` or `mem::replace` to transfer a field out through `&mut` while leaving a valid replacement:

```rust
let mut pending = vec![1, 2, 3];
let batch = std::mem::take(&mut pending);
assert!(pending.is_empty());
assert_eq!(batch, [1, 2, 3]);
```

## Lifetimes

Rely on elision where the relationship is clear. Write an explicit lifetime only when it expresses the actual relationship between references. `'static` means data can be valid for the program's lifetime; it is not a general remedy for borrow-checker errors or a synonym for "owned."

## Load next

- Cleanup and drop guarantees: `lifecycle.md`
- Cross-thread semantics: `concurrency.md`
- Common ownership diagnostics: `patterns/ownership/common-errors.md`
- Allocation/layout tradeoffs: `memory.md`
