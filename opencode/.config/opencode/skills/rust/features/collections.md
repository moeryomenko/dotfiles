# Collections (MEDIUM)

## Pick the Map by Access Pattern

| Map | Use Case |
|-----|----------|
| `HashMap<K, V>` | Fast, unordered lookups (default choice) |
| `BTreeMap<K, V>` | Sorted keys, range queries |
| `IndexMap<K, V>` | Insertion-order preservation |

## Default to `Vec` for Sequences

| Sequence | Use Case |
|----------|----------|
| `Vec<T>` | Default — fast index, push/pop. Best for most cases. |
| `VecDeque<T>` | Queue/deque behavior — push/pop at both ends |
| `LinkedList<T>` | Avoid — poor cache locality, rarely beneficial |

## Use `HashSet`/`BTreeSet` for Membership Tests

Not linear `Vec::contains`:

```rust
// Bad: O(n) per check
let items = vec![1, 2, 3];
items.contains(&4);

// Good: O(1) per check
let items: HashSet<i32> = vec![1, 2, 3].into_iter().collect();
items.contains(&4);
```

## Use `BinaryHeap` for Priority Queues

When you need repeated max-extraction:

```rust
use std::collections::BinaryHeap;

let mut heap = BinaryHeap::new();
heap.push(3);
heap.push(1);
heap.push(4);
assert_eq!(heap.pop(), Some(4));  // Max value first
```

## Cross-References

- For memory optimization: load `memory`
- For performance: load `performance`
