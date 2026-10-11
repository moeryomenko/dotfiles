# Collections

Choose a collection from access pattern, ordering, mutation, memory layout, and expected size. Prefer the standard library until a measured or semantic requirement justifies another container.

| Need | Common fit |
|---|---|
| Growable contiguous sequence | `Vec<T>` |
| Front and back queue operations | `VecDeque<T>` |
| Expected fast key lookup without order | `HashMap<K, V>` / `HashSet<T>` |
| Sorted iteration or range lookup | `BTreeMap<K, V>` / `BTreeSet<T>` |
| Insertion-order map | `indexmap` when the dependency is justified |
| Repeated highest/lowest priority work | `BinaryHeap<T>` |

Hash maps and sets provide expected/amortized constant-time lookup under their hashing assumptions; they do not make every membership test categorically faster. A small `Vec` may be simpler and faster for small, short-lived, or one-off membership tests because it avoids hashing and allocation.

```rust
fn contains_small(values: &[u32], wanted: u32) -> bool {
    values.contains(&wanted)
}

fn contains_many(values: &std::collections::HashSet<u32>, wanted: u32) -> bool {
    values.contains(&wanted)
}
```

`LinkedList` has valid specialized uses, but cache locality and allocator behavior make it a poor default for general sequences. Benchmark the actual mutation pattern before replacing a `Vec`.

## Load next

- Allocation and layout: `memory.md`
- Measured hot-path decisions: `performance.md`
