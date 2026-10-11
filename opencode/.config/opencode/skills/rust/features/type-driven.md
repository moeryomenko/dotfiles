# Type-Driven Design

Use types to encode stable, local invariants when the resulting API is clearer than runtime validation. Keep runtime validation for facts that depend on input, I/O, authorization, or changing system state.

## Newtypes and validated construction

A newtype distinguishes concepts that share a representation. Keep fields private when construction must establish an invariant, and expose conversions deliberately.

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn parse(value: String) -> Result<Self, InvalidEmail> {
        if value.contains('@') {
            Ok(Self(value))
        } else {
            Err(InvalidEmail)
        }
    }
}

#[derive(Debug)]
pub struct InvalidEmail;
```

This simple check is illustrative; production validation must match the domain's actual grammar and policy.

## Type state

Type state is useful when callers must complete a finite, linear protocol before an operation is available. Changing a generic state parameter creates a distinct type, so consume, destructure, and reconstruct rather than using struct update syntax across states.

```rust
struct Pending;
struct Validated;

struct Transaction<State> {
    id: u64,
    amount: i64,
    state: State,
}

impl Transaction<Pending> {
    fn validate(self) -> Result<Transaction<Validated>, ValidationError> {
        validate_amount(self.amount)?;
        let Self { id, amount, state: _ } = self;
        Ok(Transaction { id, amount, state: Validated })
    }
}

#[derive(Debug)]
struct ValidationError;
fn validate_amount(_: i64) -> Result<(), ValidationError> { Ok(()) }
```

Avoid type state where a simple enum, a builder, or one runtime check makes the state transition clearer.

## `PhantomData`

`PhantomData` expresses type, ownership, variance, drop-check, and auto-trait relationships to the compiler. It does not create a borrow or keep a context alive by itself. Tie a lifetime to a real borrow during construction when that is the required contract:

```rust
use std::marker::PhantomData;

struct Context;
struct Handle<'ctx> {
    raw: u32,
    _context: PhantomData<&'ctx Context>,
}

impl<'ctx> Handle<'ctx> {
    fn new(_: &'ctx Context, raw: u32) -> Self {
        Self { raw, _context: PhantomData }
    }
}
```

For raw-pointer wrappers and variance-sensitive APIs, seek a specific soundness argument rather than selecting a marker from a table.

## Sealed traits

To prevent external implementations, make the private trait an actual supertrait of the public one:

```rust
mod private {
    pub trait Sealed {}
}

pub trait IntoQuery: private::Sealed {
    fn into_query(self) -> String;
}

impl private::Sealed for String {}
impl IntoQuery for String {
    fn into_query(self) -> String { self }
}
```

Sealing restricts extension and should be a deliberate compatibility choice, not a default.

## Load next

- Basic newtypes and representation: `type-safety.md`
- Public API compatibility: `api-design.md`
- Trait-object limits: `traits.md`
- Lifetime/unsafe invariants: `unsafe.md`
