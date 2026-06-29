# API Design (HIGH)

**Triggers**: public API, builder, newtype, typestate, sealed trait, extension trait, Into, AsRef, must_use, non_exhaustive, From, IntoIterator, API design, library interface, trait design, ergonomic API.

## Use Builder Pattern for Complex Construction

When a type has many optional parameters, the Builder pattern provides a clear, flexible API.

```rust
#[derive(Default)]
#[must_use = "builders do nothing unless you call build()"]
pub struct ClientBuilder { /* ... */ }

impl ClientBuilder {
    pub fn new() -> Self { Self::default() }
    pub fn base_url(mut self, url: impl Into<String>) -> Self { /* ... */ }
    pub fn timeout(mut self, timeout: Duration) -> Self { /* ... */ }
    pub fn build(self) -> Result<Client, BuilderError> { /* ... */ }
}
```

## Mark Builder Methods with `#[must_use]`

Prevents silent drops where the user forgets to call `.build()`.

## Use Newtypes to Prevent Mixing Semantically Different Values

```rust
struct UserId(u64);
struct OrderId(u64);
// Compiler prevents accidentally passing UserId where OrderId is expected
```

## Use Typestate Pattern to Encode State Machine Invariants

Compile-time enforcement of protocol states:

```rust
struct DoorOpen;
struct DoorClosed;
struct Door<State>(State);

impl Door<DoorClosed> {
    fn open(self) -> Door<DoorOpen> { Door(DoorOpen) }
}
impl Door<DoorOpen> {
    fn close(self) -> Door<DoorClosed> { Door(DoorClosed) }
}
```

## Use Sealed Traits to Prevent External Implementations

```rust
pub trait Sealed: private::Sealed {}
mod private {
    pub trait Sealed {}
    impl Sealed for MyType {}
}
```

## Use Extension Traits to Add Methods to External Types

```rust
pub trait StringExt: AsRef<str> {
    fn truncate(&self, max: usize) -> &str { /* ... */ }
}
impl<T: AsRef<str>> StringExt for T {}
```

## Parse into Validated Types at Boundaries

Parse input as early as possible, converting to validated types:

```rust
fn process_user(input: &str) -> Result<UserId, ParseError> {
    let id: u64 = input.parse()?;
    UserId::new(id)  // Validates at construction
}
```

## Accept `impl Into<T>` for Flexible APIs

```rust
pub fn add_name(mut self, name: impl Into<String>) -> Self {
    self.name = Some(name.into());
    self
}
```

## Use `AsRef<T>` When You Only Need to Borrow the Inner Data

```rust
fn process(path: impl AsRef<Path>) {
    let path = path.as_ref();
}
```

## Mark Types and Functions with `#[must_use]` When Appropriate

When ignoring results is likely a bug — applies to Result, builders, and error-returning functions.

## Use `#[non_exhaustive]` on Public Enums and Structs

For forward compatibility — prevents downstream match exhaustiveness and struct literal construction.

## Implement `From<T>`, Not `Into<U>`

`From` gives you `Into` for free.

## Implement `Default` for Types with Sensible Default Values

## Implement Standard Traits for Public Types

Include `Debug`, `Clone`, `PartialEq`, `Eq`, `Hash` where appropriate.

## Make Serde a Feature Flag

```toml
[features]
serde = ["dep:serde", "dep:serde_derive"]
```

```rust
#[cfg_attr(feature = "serde", derive(Serialize, Deserialize))]
pub struct MyType { /* ... */ }
```

## Implement `FromIterator`, `Extend`, and `IntoIterator` for Collection Types

## Overload Operators Only When Semantics Are Natural

## Cross-References

- For type patterns: load `type-safety`
- For conversion traits: load `conversions`
- For serde details: load `serde`
