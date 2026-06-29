# Anti-patterns (REFERENCE)

## Don't Use `.unwrap()` in Production Code

Use `?`, `.ok_or()`, pattern matching, or `.unwrap_or()` instead. Reserve `.unwrap()` for tests and truly impossible cases.

```rust
// Bad
let content = fs::read_to_string("config.toml").unwrap();

// Good
let content = fs::read_to_string("config.toml")?;
```

## Don't Use `expect` for Recoverable Errors

`expect()` is for invariants/bugs, not user-facing errors.

## Don't Clone When Borrowing Works

```rust
// Bad: unnecessary clone
fn process(data: &String) {
    let copy = data.clone();
    println!("{}", copy);
}

// Good: just borrow
fn process(data: &str) {
    println!("{}", data);
}
```

## Don't Hold Locks Across Await Points

Holding a `Mutex` or `RwLock` across `.await` can cause deadlocks.

## Don't Accept `&String` When `&str` Works

Same pattern for `&Vec<T>` vs `&[T]`.

## Don't Use Indexing When Iterators Work

```rust
// Bad
for i in 0..items.len() {
    process(items[i]);  // Bounds check each iteration
}

// Good
for item in items {
    process(item);
}
```

## Don't Panic on Expected or Recoverable Errors

Return `Result` and let the caller decide.

## Don't Silently Ignore Errors

```rust
// Bad
let _ = do_something();  // Error silently discarded

// Good
if let Err(e) = do_something() {
    warn!("operation failed: {}", e);
}

// Even better
do_something()?;
```

## Don't Over-Abstract with Excessive Generics

Stay concrete until patterns prove they're needed. Prefer simple, direct code.

## Don't Optimize Before Profiling

Measure first, then optimize the actual bottlenecks.

## Don't Use `Box<dyn Trait>` When `impl Trait` Works

```rust
// Bad
fn process() -> Box<dyn Fn(i32) -> i32> { Box::new(|x| x + 1) }

// Good
fn process() -> impl Fn(i32) -> i32 { |x| x + 1 }
```

## Don't Use `format!()` in Hot Paths

`format!()` allocates. Prefer writing to a pre-allocated buffer.

## Don't Collect Intermediate Iterators

Chain iterator adapters and collect only at the end.

## Don't Use Strings Where Enums or Newtypes Provide Type Safety

```rust
// Bad
fn set_role(role: &str) { /* role could be anything */ }

// Good
enum Role { Admin, User, Guest }
fn set_role(role: Role) { /* compiler guarantees valid role */ }
```

## Cross-References

- For each anti-pattern, load the corresponding positive guidance feature
- For stringly-typed APIs: load `type-driven`
- For premature optimization: load `zero-cost`
- For error swallowing: load `domain-error`
