# Type Safety (MEDIUM)

## Wrap IDs in Newtypes

```rust
struct UserId(u64);
struct OrderId(u64);
```

## Use Newtypes to Enforce Validation at Construction

```rust
#[derive(Debug, Clone)]
pub struct Email(String);

impl Email {
    pub fn new(s: String) -> Result<Self, InvalidEmail> {
        if s.contains('@') && s.contains('.') {
            Ok(Self(s))
        } else {
            Err(InvalidEmail)
        }
    }
}
```

## Use Enums for Mutually Exclusive States

```rust
enum ConnectionState {
    Disconnected,
    Connecting,
    Connected { session_id: u64 },
    Error(String),
}
```

## Use `Option<T>` for Values That Might Not Exist

Never use sentinel values (-1, null pointer, empty string) to represent absence.

## Use `Result<T, E>` for Operations That Can Fail

Prefer it over panicking or ad-hoc error signaling.

## Use `PhantomData` to Express Type Relationships Without Runtime Cost

```rust
struct ForeignKey<T> {
    id: u64,
    _marker: PhantomData<T>,
}
```

## Use `!` (Never Type) for Functions That Never Return

```rust
fn exit_process() -> ! {
    std::process::exit(0);
}
```

## Add Trait Bounds Only Where Needed

Prefer `where` clauses for readability with multiple bounds.

## Avoid Stringly-Typed APIs

Use enums, newtypes, or validated types instead of raw `String`:

```rust
// Bad
fn set_color(color: &str) { /* color might be any string */ }

// Good
enum Color { Red, Green, Blue }
fn set_color(color: Color) { /* compiler guarantees valid color */ }
```

## Use `#[repr(transparent)]` for Newtypes in FFI Contexts

```rust
#[repr(transparent)]
struct Wrapper(InnerType);
```

## Implement `Deref`/`DerefMut` Only for Smart-Pointer Types

Not for general newtype wrappers — use explicit methods instead.

## Use `Display` for User-Facing Output and `Debug` for Diagnostics

Never swap them.

## Implement `LowerHex`, `UpperHex`, `Octal`, and `Binary` for Numeric Newtypes

## Cross-References

- For API design patterns: load `api-design`
- For conversions: load `conversions`
- For type-level state machines: load `type-driven`
- For domain modeling with types: load `domain-modeling`
- For sealed trait patterns: load `type-driven`
