# Type-Driven Design (MEDIUM)

**Triggers**: type state, PhantomData, newtype, marker trait, builder pattern, make invalid states unrepresentable, compile-time validation, sealed trait, ZST, typestate, state machine.

## Core Question

**How can the type system prevent invalid states at compile time?**

Before reaching for runtime checks:
- Can the compiler catch this error?
- Can invalid states be made unrepresentable in the type system?
- Can the type encode the constraint instead of documentation?

---

## Design Flowchart

```
Can the type system enforce this constraint?
├─ Yes at compile time → Type-level encoding
│   ├─ Finite states → Type state pattern
│   ├─ Numeric bounds → Bounded newtype
│   ├─ Semantic meaning → Newtype wrapper
│   └─ Trait impl requirement → Marker trait / sealed trait
├─ Yes at construction → Validated newtype
│   └─ Parse, don't validate
└─ Only at runtime → Result<T, E>
    └─ Document invariants clearly
```

---

## Making Invalid States Unrepresentable

### Problem: Stringly-Typed API

```rust
// BAD: email could be any string
fn send_email(to: &str, subject: &str, body: &str) {
    // Must validate at runtime — what if caller doesn't?
}
```

### Solution: Newtype with Validation

```rust
#[derive(Debug, Clone)]
pub struct Email(String);

impl Email {
    pub fn new(s: String) -> Result<Self, InvalidEmail> {
        if s.contains('@') && s.contains('.') {
            Ok(Self(s))
        } else {
            Err(InvalidEmail(s))
        }
    }
}

// Now impossible to pass an invalid email by accident
fn send_email(to: &Email, subject: &str, body: &str) {
    // Guaranteed valid at this point
}

// Caller must validate at construction
fn handle_request(input: &str) -> Result<(), Error> {
    let email = Email::new(input.to_string())?;  // Must handle error
    send_email(&email, "Hello", "Body");
    Ok(())
}
```

### Problem: Optional Validation

```rust
// BAD: what if both are None? What if both are Some?
struct Config {
    host: Option<String>,
    port: Option<u16>,
}
```

### Solution: Semantic Types

```rust
// GOOD: precisely models the domain
struct Unset;
struct Set(String);

struct ServerConfig<HostState, PortState> {
    host: HostState,
    port: PortState,
}

// Only complete config can be used
impl ServerConfig<Set, Set> {
    pub fn connect(&self) -> Result<Connection, Error> {
        Connection::new(&self.host.0, self.port.0)
    }
}
```

---

## Type State Pattern

### State Machine at the Type Level

The type state pattern encodes state transitions in the type system,
making illegal state transitions a compile-time error:

```rust
// States
struct DoorOpen;
struct DoorClosed;
struct DoorLocked;

// State machine
struct Door<State> {
    state: State,
}

// Transitions from Closed
impl Door<DoorClosed> {
    pub fn open(self) -> Door<DoorOpen> {
        Door { state: DoorOpen }
    }

    pub fn lock(self) -> Door<DoorLocked> {
        Door { state: DoorLocked }
    }
}

// Transitions from Open
impl Door<DoorOpen> {
    pub fn close(self) -> Door<DoorClosed> {
        Door { state: DoorClosed }
    }
}

// Transitions from Locked
impl Door<DoorLocked> {
    pub fn unlock(self) -> Door<DoorClosed> {
        Door { state: DoorClosed }
    }
}

// Compile-time guarantees:
// - Can't close a closed door
// - Can't lock an open door
// - Can't open a locked door
fn type_state_example() {
    let door = Door { state: DoorClosed };
    let door = door.open();     // Door<DoorOpen>
    let door = door.close();    // Door<DoorClosed>
    let door = door.lock();     // Door<DoorLocked>
    // door.open();             // COMPILE ERROR: no open() for locked door
}
```

### Type State with Data

```rust
// States
struct Pending;
struct Validated;
struct Submitted;

struct Transaction<State> {
    id: TransactionId,
    amount: Money,
    from: Account,
    to: Account,
    state: State,
}

impl Transaction<Pending> {
    pub fn new(amount: Money, from: Account, to: Account) -> Self {
        Self { id: TransactionId::new(), amount, from, to, state: Pending }
    }

    pub fn validate(self) -> Result<Transaction<Validated>, ValidationError> {
        // Perform validation logic
        Ok(Transaction { state: Validated, ..self })
    }
}

impl Transaction<Validated> {
    pub fn submit(self) -> Transaction<Submitted> {
        Transaction { state: Submitted, ..self }
    }
}

impl Transaction<Submitted> {
    pub fn id(&self) -> &TransactionId { &self.id }
    pub fn amount(&self) -> Money { self.amount }
}

// Usage: the compiler enforces the state machine
fn process_payment(tx: Transaction<Pending>) -> Result<TransactionId, Error> {
    let tx = tx.validate()?;    // Pending -> Validated
    let tx = tx.submit();       // Validated -> Submitted
    Ok(*tx.id())
}
```

---

## PhantomData for Type-Level Relationships

### Expressing Ownership at the Type Level

```rust
use std::marker::PhantomData;

struct ForeignKey<T> {
    id: u64,
    _marker: PhantomData<T>,  // T is used at the type level only
}

impl<T> ForeignKey<T> {
    fn new(id: u64) -> Self {
        Self { id, _marker: PhantomData }
    }
}
```

### PhantomData for Variance

```rust
use std::marker::{PhantomData, PhantomPinned};

struct MyType<T> {
    data: *const T,
    _marker: PhantomData<T>,           // Covariant
}

struct InvariantType<T> {
    data: *mut T,
    _marker: PhantomData<fn(T) -> T>,  // Invariant
}

struct SelfReferential {
    data: Vec<u8>,
    ptr: *const u8,                    // Points into `data`
    _pinned: PhantomPinned,            // Not Unpin
}
```

### PhantomData for Type Safety in Generic Resources

```rust
struct FileDescriptor {
    fd: c_int,
}

struct Socket<'a> {
    fd: FileDescriptor,
    _lifetime: PhantomData<&'a ()>,  // Socket can't outlive its context
}

struct TypedChannel<T> {
    raw: RawChannel,
    _type: PhantomData<T>,
}

impl<T> TypedChannel<T> {
    fn send(&self, msg: T) {
        // Type-safe wrapper around untyped send
        self.raw.send(&msg);
    }
}
```

---

## Sealed Traits

### Preventing External Implementation

```rust
/// Public trait that cannot be implemented outside this crate.
pub trait Sealed {}

/// Private module containing the sealed trait
mod private {
    pub trait Sealed {}

    // Internal implementations
    impl Sealed for MyType {}
}

// External crate CANNOT implement Sealed for their types
```

### Practical Sealed Trait Pattern

```rust
// Public trait visible to external consumers
pub trait IntoQuery: private::Sealed {
    fn into_query(self) -> String;
}

// Private module — consumers cannot name this trait
mod private {
    pub trait Sealed {}
}

// Implement for your types
impl private::Sealed for String {}
impl IntoQuery for String {
    fn into_query(self) -> String { self }
}

impl private::Sealed for &str {}
impl IntoQuery for &str {
    fn into_query(self) -> String { self.to_string() }
}
```

---

## Common Mistakes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| Primitive obsession | No type safety, validation duplicated | Newtype with validation |
| Boolean parameters | Unclear meaning at call site | Enum or newtype |
| Runtime checks for static invariants | Panics or errors at runtime | Type state pattern |
| `PhantomData<T>` with wrong variance | Unsound with raw pointers | Use correct variance marker |
| Not sealing traits in public API | Users can implement unsafely | Seal with private supertrait |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Every parameter as `String` | No compile-time safety | Newtype per concept |
| Bool for state | Invalid states possible | Enum or type state |
| `unwrap()` for validated types | Panics if validation missed | Return Result from constructor |
| `PhantomData<fn() -> T>` without understanding | Incorrect variance | Understand variance rules |
| Public fields that should be private | Invariants violated | Private fields, constructor validation |

---

## Cross-References

- For newtype patterns: load `type-safety`
- For API design with builders: load `api-design`
- For conversions between types: load `conversions`
- For error handling at boundaries: load `error-handling`
