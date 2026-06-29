# Closures (MEDIUM)

## Require the Least Restrictive `Fn` Trait

```rust
// FnOnce - can be called once
fn run_once<F: FnOnce()>(f: F) { f() }

// FnMut - can mutate captured state
fn run_mut<F: FnMut()>(mut f: F) { f(); f() }

// Fn - can be called multiple times without mutation
fn run<F: Fn() -> i32>(f: F) -> i32 { f() + f() }
```

## Return Closures as `impl Fn`/`FnMut`/`FnOnce`

Not `Box<dyn Fn>`:

```rust
fn make_adder(x: i32) -> impl Fn(i32) -> i32 {
    move |y| x + y
}
```

## Use `move` for Closures That Outlive the Current Scope

```rust
let data = vec![1, 2, 3];
thread::spawn(move || {  // move takes ownership
    process(data);
});
```

Clone before `move` to keep the original:

```rust
let data_clone = data.clone();
thread::spawn(move || { process(data_clone); });
// data is still available here
```

## Accept `impl Fn` (Generic) for Hot Callbacks

Use `&dyn Fn`/`Box<dyn Fn>` to cut code size or when storing callbacks:

```rust
// Generic - monomorphized, faster
fn with_callback<F: Fn(i32)>(f: F) { /* ... */ }

// Dynamic dispatch - reduces code size
fn with_dyn_callback(f: &dyn Fn(i32)) { /* ... */ }
```

## Capture Only What You Use

Edition 2021 disjoint closure captures capture only the fields used:

```rust
struct Person { name: String, age: u32 }

let person = Person { name: "Alice".into(), age: 30 };

// Only captures name, not age
let closure = || println!("{}", person.name);
```

## Cross-References

- For trait dispatch choices: load `traits`
- For async closures: load `async`
