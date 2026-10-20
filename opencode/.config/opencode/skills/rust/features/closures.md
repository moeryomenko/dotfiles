# Closures

Choose a closure bound from how the callback uses captured state and how the caller needs to invoke or store it. Capture mode and dispatch are API decisions, not default performance settings.

## Bounds and captures

`Fn` can be called through a shared reference, `FnMut` may mutate its environment, and `FnOnce` may consume it. Accept the least restrictive bound that expresses the required calls.

```rust
fn run_twice<F: FnMut()>(mut action: F) {
    action();
    action();
}

let mut count = 0;
run_twice(|| count += 1);
assert_eq!(count, 2);
```

Use `move` when the closure must own what it captures, such as a detached thread or task. It moves the captured values selected by the closure; clone first only when independent ownership is actually required.

```rust
let data = vec![1, 2, 3];
let worker_data = data.clone();
let handle = std::thread::spawn(move || worker_data.len());
assert_eq!(data.len(), 3);
assert_eq!(handle.join().unwrap(), 3);
```

Edition 2021 disjoint capture can reduce what a closure captures, but public behavior should not depend on inferred capture details. Make ownership explicit when it affects an API or a borrow conflict.

## Returning and accepting callbacks

Return `impl Fn...` when one concrete closure type is sufficient. Use a generic parameter for static dispatch when that fits the API; use `&dyn Fn...` or an owned trait object when callbacks must be selected at runtime, stored heterogeneously, or code-size tradeoffs favor it.

```rust
fn make_adder(base: i32) -> impl Fn(i32) -> i32 {
    move |value| base + value
}

assert_eq!(make_adder(2)(3), 5);
```

For async closures, account for the future's captures, lifetime, `Send`, and storage requirements rather than assuming an ordinary `Fn` bound is enough.

## Load next

- Trait dispatch: `traits.md`
- Async task ownership: `async.md`
- Borrowing and shared state: `ownership.md`
