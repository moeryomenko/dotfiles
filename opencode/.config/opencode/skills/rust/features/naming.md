# Naming Conventions (MEDIUM)

## Casing Conventions

| Item | Convention |
|------|-----------|
| Types, traits, enum names | `UpperCamelCase` |
| Enum variants | `UpperCamelCase` |
| Functions, methods, variables, modules | `snake_case` |
| Constants and statics | `SCREAMING_SNAKE_CASE` |
| Lifetime names | `'a`, `'b`, `'de`, `'src` (short, conventional) |
| Type parameters | Single uppercase: `T`, `E`, `K`, `V` |

## Prefix Conventions

| Prefix | Meaning |
|--------|---------|
| `as_` | Free reference conversion: `as_str()` |
| `to_` | Expensive conversion (allocates/computes): `to_string()` |
| `into_` | Ownership-consuming conversion: `into_inner()` |
| (none) | Simple getter: `name()` not `get_name()` |
| `is_`, `has_`, `can_`, `should_` | Boolean-returning methods |

## Iterator Method Naming

```rust
fn iter(&self) -> Iter<'_, T>       // &T references
fn iter_mut(&mut self) -> IterMut<'_, T>  // &mut T references
fn into_iter(self) -> IntoIter<T>  // owned T values
```

Name iterator types after their source method: `Iter`, `IterMut`, `IntoIter`.

## Acronyms as Words

Treat acronyms as words in identifiers: `HttpServer` (not `HTTPServer`), `parseJson` (not `parseJSON`).

## Crate Names

Don't suffix crate names with `-rs` or `-rust`. The crate is already in Rust.

## Cross-References

- For API design conventions: load `api-design`
