# Trait & Generics Design (MEDIUM)

## Use Associated Types When Each Impl Has Exactly One Output Type

Use generic parameters when a type can implement the trait for many input types:

```rust
// Associated type: each impl has one fixed output
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}

// Generic: many possible outputs per impl
trait From<T> {
    fn from(value: T) -> Self;
}
```

## Use Blanket Impls for Widespread Behavior

```rust
impl<T: Debug> Debug for MyWrapper<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        self.inner.fmt(f)
    }
}
```

## Respect the Orphan Rule

Wrap a foreign type in a newtype to implement a foreign trait on it.

## Define Traits in Terms of a Few Required Methods Plus Defaulted Ones

```rust
trait Animal {
    fn make_sound(&self) -> String;  // Required
    
    fn speak(&self) {                // Default based on required
        println!("{}", self.make_sound());
    }
}
```

## Choose Static Dispatch vs Dynamic Dispatch Deliberately

| Approach | Use Case |
|----------|----------|
| Generics / `impl Trait` (static) | Hot paths, monomorphization OK, known types |
| `dyn Trait` (dynamic) | Reduced code size, heterogeneous collections, plugin architectures |

## Keep Traits Object-Safe When You Need `dyn Trait`

Object-safe traits: no `Self: Sized`, no generic methods, no associated `const` with type references.

## Cross-References

- For type system features: load `type-safety`
- For closure patterns: load `closures`
- For static vs dynamic dispatch: load `zero-cost`
- For object safety rules: load `zero-cost`
