# Type Safety

Choose representations that make important mistakes difficult, while keeping APIs proportional to the domain. Newtypes, enums, `Option`, and `Result` are tools—not mandatory wrappers around every primitive.

## Model the distinction

Use a newtype when two values share a representation but must not be interchangeable, or when construction validates an invariant:

```rust
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
}
```

Use `Option<T>` for a meaningful absence and `Result<T, E>` for an operation that can fail. Sentinel values can be valid wire-format or performance choices when they are documented and safely converted at the boundary.

## API implications

Keep invariant-bearing fields private and provide constructors/accessors that maintain the contract. Derive traits only when their semantics are correct: equality, ordering, hashing, copying, and serialization can each be public commitments.

Use `#[repr(transparent)]` for a one-field wrapper only when FFI, ABI, or representation compatibility requires it. Do not expose an internal representation accidentally through `Deref`; ordinary newtypes usually need explicit accessors or conversion methods. `Display` and `Debug` serve different audiences, but a type may intentionally implement either, both, or neither according to its interface.

`PhantomData` is for compiler-visible relationships; see `type-driven.md` before using it for lifetime, ownership, or variance reasoning.

## Load next

- Type state and sealed traits: `type-driven.md`
- Conversions at boundaries: `conversions.md`
- Public contracts: `api-design.md`
- Domain values: `domain-modeling.md`
