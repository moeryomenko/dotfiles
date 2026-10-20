# Common Ownership Errors

Read the diagnostic as an API design question: who owns the value, how long must it live, and who may mutate it? Compiler error codes identify a symptom; they are not a menu of universal fixes.

## Moved values

Moving a non-`Copy` value transfers ownership. Borrow if the callee only needs access, return/retain ownership when the callee needs it, and clone only when independent ownership is actually required.

```rust
fn print_name(name: &str) {
    println!("{name}");
}

let name = String::from("Ada");
print_name(&name);
println!("{name}");
```

Use `Rc` for shared single-threaded ownership and `Arc` where shared ownership crosses the relevant thread/task boundary. Neither makes contained mutation automatically safe.

## Borrow conflicts

A mutable borrow excludes other accesses that overlap it. Shorten the borrow, split disjoint fields, copy out a small `Copy` value when that is the right semantic value, or redesign the operation.

```rust
let mut values = vec![1, 2, 3];
let first = values[0];
values.push(4);
assert_eq!(first, 1);
```

`RefCell` moves borrow checking to runtime and can panic on conflicting borrows. Use it for a real single-threaded interior-mutability need, not as a default escape hatch.

## Lifetimes and returned references

A returned reference needs a referent that outlives the caller. Return an owned value for newly created data; tie an output reference to an input only when it genuinely borrows that input.

```rust
fn first_word(input: &str) -> &str {
    input.split_whitespace().next().unwrap_or("")
}

fn greeting() -> String {
    String::from("hello")
}
```

`'static` is correct for data that genuinely lives for the program, such as string literals, or for deliberately leaked allocations with an explicit retention policy. It is not a generic solution to a borrow-checker error or task-spawn bound.

## Iteration

`for value in collection` consumes `collection`; `for value in &collection` borrows; `for value in &mut collection` mutably borrows. Select the form from whether the collection/value must remain usable and whether elements need mutation.

## Load next

- Ownership models: `../../ownership.md`
- Resource lifetime/completion: `../../lifecycle.md`
- Task ownership and `'static`: `../../async.md`
