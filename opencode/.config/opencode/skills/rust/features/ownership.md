# Ownership & Borrowing (CRITICAL)

**Triggers**: E0382, E0597, E0506, E0507, E0515, E0716, E0106, moved value, borrowed, lifetime, 'a, 'static, move, clone, Copy, borrow checker, Rc, Arc, RefCell, Cow, NLL.

## Prefer `&T` Borrowing Over `.clone()`

Cloning allocates new memory and copies data, while borrowing is free. Unnecessary clones significantly impact performance, especially in hot paths.

**Bad:**
```rust
fn process(data: &String) {
    let local = data.clone();  // Unnecessary allocation
    println!("{}", local);
}
```

**Good:**
```rust
fn process(data: &str) {
    println!("{}", data);  // No allocation
}
```

**Clone is acceptable** for: storing owned data, sending across threads (`'static`), and Copy types.

## Accept `&[T]` Not `&Vec<T>`, `&str` Not `&String`

Accepting `&[T]` and `&str` makes functions more flexible — they accept slices from arrays, vectors, or other sources.

**Bad:** `fn sum(numbers: &Vec<i32>)` — only accepts `Vec`.
**Good:** `fn sum(numbers: &[i32])` — accepts `Vec`, arrays, slices.

Coercions happen automatically: `Vec<T> -> &[T]`, `String -> &str`, `Box<T> -> &T`.

## Use `Cow<'a, T>` for Conditional Ownership

`Cow` (Clone-on-Write) lets a function return either a borrowed or owned value, avoiding clones when the original is sufficient.

```rust
use std::borrow::Cow;

fn normalize(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        Cow::Owned(input.replace(' ', "_"))
    } else {
        Cow::Borrowed(input)
    }
}
```

## Use `Arc<T>` for Thread-Safe Shared Ownership

`Arc` provides shared ownership across threads. Use `Arc<Mutex<T>>` or `Arc<RwLock<T>>` for mutable shared state.

**Decision tree:**
- Single-threaded shared ownership: `Rc<T>`
- Multi-threaded shared ownership: `Arc<T>`
- Need mutation (single-threaded): `Rc<RefCell<T>>`
- Need mutation (multi-threaded): `Arc<Mutex<T>>` or `Arc<RwLock<T>>`

## Implement `Copy` for Small, Simple Types

Types that are trivially copyable (like `i32`, `bool`, simple wrappers) should implement `Copy` to avoid requiring explicit `.clone()` calls.

```rust
#[derive(Copy, Clone)]
pub struct Color { pub r: u8, pub g: u8, pub b: u8 }
```

## Use Explicit `Clone` for Types Where Copying Has Meaningful Cost

Types with heap allocations (like `Vec`, `String`) should only implement `Clone`, not `Copy`.

## Move Large Types Instead of Copying

Large types benefit from move semantics. Use `Box` if moves are expensive.

## Rely on Lifetime Elision Rules

Add explicit lifetimes only when required. The three elision rules handle most cases:
1. Each input reference gets its own lifetime
2. One input reference -> output gets same lifetime
3. Method with `&self`/`&mut self` -> output gets self's lifetime

## Use `RefCell<T>` for Interior Mutability in Single-Threaded Code

`RefCell<T>` enforces borrowing rules at runtime. Use when you need mutation through an immutable reference but cannot use `&mut`.

## Use `Mutex<T>` for Interior Mutability Across Threads

`Mutex<T>` provides mutual exclusion across threads. Prefer `RwLock<T>` when reads significantly outnumber writes.

## Use `mem::take` / `mem::replace` to Move Out of `&mut` Without Cloning

```rust
use std::mem;

let mut vec = vec![1, 2, 3];
let old = mem::take(&mut vec);  // Replaces with empty Vec
assert!(vec.is_empty());
assert_eq!(old, vec![1, 2, 3]);
```

## Cross-References

- For reducing clone costs: load `memory`
- For `impl AsRef<T>`: load `api-design`
- For slice vs vec anti-patterns: load `anti-patterns`
- For RAII and Drop patterns: load `lifecycle`
- For shared ownership across threads: load `concurrency`
- For lifetime patterns with examples: load `patterns/ownership/common-errors.md`
