# Naming

Follow the Rust API Guidelines and the repository's established vocabulary. Names should reveal the domain meaning, ownership, and cost where that distinction helps callers.

| Item | Usual spelling |
|---|---|
| Types, traits, enum variants | `UpperCamelCase` |
| Functions, methods, variables, modules | `snake_case` |
| Constants and statics | `SCREAMING_SNAKE_CASE` |
| Lifetimes | short contextual names such as `'a`, `'de`, or `'src` |

Use acronym casing as words: `HttpServer`, `parse_json`, and `user_id` rather than all-capital acronyms. Preserve externally specified protocol names only at their boundary, then translate into idiomatic Rust names.

## Conversion and query names

- `as_*` conventionally borrows or views data cheaply, such as `as_str`.
- `to_*` conventionally creates a value and may allocate or compute, such as `to_string`.
- `into_*` consumes `self`, such as `into_inner`.
- Name boolean queries `is_*`, `has_*`, `can_*`, or a clear predicate.
- Prefer `name()` over `get_name()` unless it distinguishes an operation from a field-like accessor in the local API.

Use `iter`, `iter_mut`, and `into_iter` only when their item ownership follows the conventional meanings. Do not force a naming pattern that obscures a domain operation.

## Load next

- Public contracts and compatibility: `api-design.md`
- Newtypes and domain distinctions: `type-safety.md`
