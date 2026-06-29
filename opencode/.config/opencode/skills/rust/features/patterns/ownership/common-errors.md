# Common Ownership Errors & Fixes

## E0382: Use of Moved Value

### Error Pattern

```rust
let s = String::from("hello");
let s2 = s;          // s moved here
println!("{}", s);   // ERROR: value borrowed after move
```

### Fix Options

**Option 1: Clone (if ownership not needed)**
```rust
let s = String::from("hello");
let s2 = s.clone();  // s is cloned
println!("{}", s);   // OK: s still valid
```

**Option 2: Borrow (if modification not needed)**
```rust
let s = String::from("hello");
let s2 = &s;         // borrow, not move
println!("{}", s);   // OK
println!("{}", s2);  // OK
```

**Option 3: Use Rc/Arc (for shared ownership)**
```rust
use std::rc::Rc;
let s = Rc::new(String::from("hello"));
let s2 = Rc::clone(&s);  // shared ownership
println!("{}", s);       // OK
println!("{}", s2);      // OK
```

---

## E0597: Borrowed Value Does Not Live Long Enough

### Error Pattern

```rust
fn get_str() -> &str {
    let s = String::from("hello");
    &s  // ERROR: s dropped here, but reference returned
}
```

### Fix Options

**Option 1: Return owned value**
```rust
fn get_str() -> String {
    String::from("hello")  // return owned value
}
```

**Option 2: Use 'static lifetime**
```rust
fn get_str() -> &'static str {
    "hello"  // string literal has 'static lifetime
}
```

**Option 3: Accept reference parameter**
```rust
fn get_str<'a>(s: &'a str) -> &'a str {
    s  // return reference with same lifetime as input
}
```

---

## E0499: Cannot Borrow as Mutable More Than Once

### Error Pattern

```rust
let mut s = String::from("hello");
let r1 = &mut s;
let r2 = &mut s;  // ERROR: second mutable borrow
println!("{}, {}", r1, r2);
```

### Fix Options

**Option 1: Sequential borrows**
```rust
let mut s = String::from("hello");
{
    let r1 = &mut s;
    r1.push_str(" world");
}  // r1 goes out of scope
let r2 = &mut s;  // OK: r1 no longer exists
```

**Option 2: Use RefCell for interior mutability**
```rust
use std::cell::RefCell;
let s = RefCell::new(String::from("hello"));
let mut r1 = s.borrow_mut();
// drop r1 before borrowing again
drop(r1);
let mut r2 = s.borrow_mut();
```

---

## E0502: Cannot Borrow as Mutable While Immutable Borrow Exists

### Error Pattern

```rust
let mut v = vec![1, 2, 3];
let first = &v[0];      // immutable borrow
v.push(4);              // ERROR: mutable borrow while immutable exists
println!("{}", first);
```

### Fix Options

**Option 1: Copy the value, not the borrow**
```rust
let mut v = vec![1, 2, 3];
let first = v[0];       // copy value, not borrow
v.push(4);              // OK
println!("{}", first);  // OK: using copied value
```

**Option 2: Restructure code**
```rust
let mut v = vec![1, 2, 3];
let first = v[0];       // copy before mutation
v.push(4);
println!("{}", first);
```

---

## E0506: Cannot Assign to `x` Because It Is Borrowed

### Error Pattern

```rust
let mut v = vec![1, 2, 3];
let r = &v;
v = vec![4, 5, 6];     // ERROR: v is borrowed
println!("{:?}", r);
```

### Fix: End the borrow before mutation

```rust
let mut v = vec![1, 2, 3];
{
    let r = &v;
    println!("{:?}", r);
}  // borrow ends
v = vec![4, 5, 6];     // OK: borrow ended
```

---

## E0515: Cannot Return Reference to Local Variable

### Error Pattern

```rust
fn create_string() -> &String {
    let s = String::from("hello");
    &s  // ERROR: cannot return reference to local variable
}
```

### Fix: Return owned value

```rust
fn create_string() -> String {
    String::from("hello")
}
```

---

## Loop Ownership Issues

### Error Pattern

```rust
let strings = vec![String::from("a"), String::from("b")];
for s in strings {
    println!("{}", s);
}
// ERROR: strings moved into loop
println!("{:?}", strings);
```

### Fix Options

**Option 1: Iterate by reference**
```rust
let strings = vec![String::from("a"), String::from("b")];
for s in &strings {
    println!("{}", s);
}
println!("{:?}", strings);  // OK
```

**Option 2: Use `iter()`**
```rust
for s in strings.iter() {
    println!("{}", s);
}
```

---

## Lifetime Patterns

### Basic Lifetime Annotation

```rust
// ERROR: missing lifetime specifier
fn longest(x: &str, y: &str) -> &str;

// FIX: explicit lifetime
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

### Lifetime Elision Rules

1. Each input reference gets its own lifetime
2. If one input lifetime, output uses same lifetime
3. If `&self` or `&mut self`, output gets self's lifetime

### Struct with Lifetime

```rust
struct Excerpt<'a> {
    part: &'a str,
}

impl<'a> Excerpt<'a> {
    fn get_part(&self) -> &str {
        self.part
    }
}
```

### 'static Lifetime

```rust
// String literals are 'static
let s: &'static str = "hello";

// Leak to 'static (rare, intentional)
let leaked: &'static str = Box::leak(
    String::from("hello").into_boxed_str()
);
```

### When to NOT use 'static

```rust
// BAD: requires 'static unnecessarily
fn process(s: &'static str) { ... }

// GOOD: use generic lifetime
fn process(s: &str) { ... }  // lifetime elision
```
