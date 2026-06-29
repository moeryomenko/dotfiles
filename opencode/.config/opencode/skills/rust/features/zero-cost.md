# Zero-Cost Abstraction (HIGH)

**Triggers**: generics, trait objects, static dispatch, dynamic dispatch, impl Trait, dyn Trait, monomorphization, E0277, E0308, E0599, E0038, object safety, trait bound.

## Core Question

**Do we need compile-time or runtime polymorphism?**

Before choosing between generics and trait objects:
- Is the concrete type known at call site?
- Is a heterogeneous collection needed (e.g., `Vec<Box<dyn Trait>>`)?
- What is the performance priority — speed or binary size?

---

## Dispatch Decision Flowchart

```
Is the concrete type known at compile time?
├─ Yes → Can it be expressed with generics?
│        ├─ Yes → Static dispatch (generics / impl Trait)
│        │        └── Zero runtime cost, monomorphization
│        └─ No  → Is the type truly dynamic?
│                 ├─ Yes → Dynamic dispatch (dyn Trait)
│                 │        └── Virtual call overhead, vtable
│                 └─ No  → Enum dispatch (match)
│                          └── Zero overhead, exhaustive
└─ No → Dynamic dispatch (dyn Trait)
```

---

## Static Dispatch (Generics)

### Generics with Trait Bounds

```rust
trait Processor {
    fn process(&self, input: &str) -> String;
}

// Static dispatch: monomorphized for each concrete T
fn run_processor<T: Processor>(processor: T, input: &str) -> String {
    processor.process(input)  // Direct call, no vtable
}

// Equivalent with impl Trait syntax
fn run_processor(processor: impl Processor, input: &str) -> String {
    processor.process(input)
}
```

### When to Use Static Dispatch

- Hot paths where every nanosecond matters
- Small number of known types
- Caller selects the type at compile time
- You want LLVM to inline across the call

### Trade-offs

| Advantage | Disadvantage |
|-----------|--------------|
| Zero runtime overhead | Larger binary (code bloat from monomorphization) |
| LLVM can inline | Slower compilation |
| No vtable lookup | More generic parameters can pollute APIs |
| Better optimization | Cannot hold heterogeneous types in a collection |

---

## Dynamic Dispatch (Trait Objects)

### dyn Trait Syntax

```rust
// Dynamic dispatch: vtable lookup at runtime
fn run_processor(processor: &dyn Processor, input: &str) -> String {
    processor.process(input)  // Virtual call via vtable
}

// Boxed trait object (owned)
fn store_processor(processor: Box<dyn Processor>) {
    // processor stored in Box<dyn Processor>
}
```

### When to Use Dynamic Dispatch

- Heterogeneous collections (`Vec<Box<dyn Trait>>`)
- Plugin architectures
- API boundaries where the concrete type is unknown
- Reducing binary size by sharing code paths

### Object Safety Rules

A trait is object-safe if all methods meet these requirements:

1. No `Self: Sized` requirement on the trait
2. No generic type parameters on methods
3. No associated consts with type references
4. No `Self` in return position (except where `Self: Sized`)
5. First parameter must be a receiver (`self`, `&self`, `&mut self`, `Box<self>`)

```rust
trait ObjectSafe {
    fn do_thing(&self);                    // OK
    fn returns_self() -> Self;             // NOT object-safe
    fn generic<T>(&self, val: T);          // NOT object-safe
}
```

---

## Enum Dispatch (Sum Type Pattern)

When the set of variants is known and closed, enum dispatch is zero-cost:

```rust
enum OutputFormat {
    Json,
    Yaml,
    Toml,
}

trait Formatter {
    fn format(&self, data: &Data) -> String;
}

impl Formatter for OutputFormat {
    fn format(&self, data: &Data) -> String {
        match self {
            Self::Json => serialize_json(data),
            Self::Yaml => serialize_yaml(data),
            Self::Toml => serialize_toml(data),
        }
    }
}

// Zero-cost: the match is resolved at compile time
fn process(data: &Data, format: OutputFormat) -> String {
    format.format(data)
}
```

### Enum Dispatch vs Trait Objects

```rust
// Enum dispatch: closed set, zero overhead
enum Command {
    Move { x: i32, y: i32 },
    Jump { height: f64 },
    Quit,
}

fn execute(commands: Vec<Command>) {
    for cmd in commands {
        match cmd {
            Command::Move { x, y } => move_to(x, y),
            Command::Jump { height } => jump(height),
            Command::Quit => return,
        }
    }
}

// Trait objects: open set, vtable overhead
trait CommandHandler {
    fn execute(&self);
}

fn execute(commands: Vec<Box<dyn CommandHandler>>) {
    for cmd in commands {
        cmd.execute();  // vtable call
    }
}
```

**Choose enum dispatch when:**
- The set of variants is finite and known at compile time
- You want exhaustive matching (compiler ensures all cases handled)
- Zero overhead is important

**Choose trait objects when:**
- External consumers need to add new implementations
- You need runtime loading or dynamic discovery
- The set of implementations is open

---

## impl Trait in Return Position

```rust
// Return an opaque type that implements Iterator
fn create_iter(start: u32, end: u32) -> impl Iterator<Item = u32> {
    (start..end).filter(|n| n % 2 == 0)
}

// Return different types conditionally (requires Box)
fn create_iter(start: u32, end: u32) -> Box<dyn Iterator<Item = u32>> {
    if start > 100 {
        Box::new(start..end)
    } else {
        Box::new((start..end).rev())
    }
}
```

**Rules:**
- `impl Trait` in return position: concrete but hidden type, single type per function
- `dyn Trait` in return position: runtime dispatch, can return different types

---

## Performance Characteristics

| Pattern | Dispatch Cost | Code Size | Inlining | Flexibility |
|---------|---------------|-----------|----------|-------------|
| Generics (static) | Zero | Largest per-use | Full | Low (compile-time) |
| `impl Trait` (static) | Zero | Per callsite | Full | Medium (opaque) |
| `&dyn Trait` (dynamic) | 1 pointer + 1 vtable load | Shared | None across calls | High (open set) |
| `Box<dyn Trait>` (dynamic) | 1 heap + vtable | Shared | None | High with ownership |
| Enum dispatch | Zero | Fixed per enum | Full | Low (closed set) |

---

## Common Mistakes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| `Box<dyn Trait>` for known single type | Unnecessary heap + vtable | Use generics or impl Trait |
| Generic overflow (too many params) | Poor readability | Group into trait or struct |
| Not object-safe trait | Can't use as trait object | Remove non-object-safe methods |
| `impl Trait` in return for multiple types | Won't compile | Use `Box<dyn Trait>` |
| Generics on hot path when types vary | No benefit, slower compile | Use dynamic dispatch or enum |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| blanket `Box<dyn Trait>` for everything | Heap + vtable for no benefit | Generics, then impl Trait, then dyn |
| Massive enums instead of traits | Hard to extend, violates OCP | Trait objects for open sets |
| Unneeded trait bounds (T: Clone + Debug + Display) | Limits callers | Only bounds that are needed |
| Overuse of `#[inline]` on generics | Code bloat, no benefit | Let LLVM decide inlining |

---

## Cross-References

- For trait design: load `traits`
- For closures and dispatch: load `closures`
- For API design with impl Trait: load `api-design`
- For type safety: load `type-safety`
