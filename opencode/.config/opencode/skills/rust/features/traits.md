# Traits and Generics

Design a trait around the behavior consumers need, then make extension, dispatch, ownership, and compatibility explicit. Keep bounds minimal and avoid publishing a trait merely to abstract one implementation.

## Associated types and parameters

Use an associated type when an implementation has one natural relationship for the trait; use a type parameter when the same implementing type should support multiple relationships.

```rust
trait Decode {
    type Output;
    fn decode(&self) -> Self::Output;
}

trait Convert<T> {
    fn convert(value: T) -> Self;
}
```

The orphan rule permits an implementation only when the trait or the implementing type is local. A newtype can establish a local API boundary, but does not automatically make the conversion desirable.

## Dyn compatibility

Only use `dyn Trait` when runtime polymorphism or heterogeneous storage is required. A dyn-compatible trait cannot have associated constants, generic methods, or non-receiver associated functions available through the object. Methods using `Self` outside the receiver/allowed forms generally require `where Self: Sized` if they should coexist with trait objects.

```rust
trait Renderer {
    fn render(&self) -> String;
    fn named(name: &str) -> Self
    where
        Self: Sized;
}
```

`named` remains usable on concrete implementors but not through `dyn Renderer`. Native `async fn` in traits is stable, but such traits are not dyn-compatible without an adapter/design that erases the future type.

## Implementations and defaults

A blanket implementation is generic over a family of types, such as `impl<T: Display> Label for T`; an implementation for `Wrapper<T>` is a generic implementation, but only a blanket impl when it applies to an open family through its bounds. Default methods should be derivable from a small required core and should not surprise implementors with hidden cost or side effects.

## Load next

- Static/dynamic dispatch tradeoffs: `zero-cost.md`
- Public trait compatibility: `api-design.md`
- Async trait constraints: `async.md`
