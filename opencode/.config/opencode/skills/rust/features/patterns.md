# Pattern Matching

Use a pattern form that makes the control flow and ownership intent clear. Check the crate MSRV before using recently stabilized syntax such as `let` chains.

## Extraction and tests

Use `let ... else` when the non-match is an early return or diverging path:

```rust
fn parse_port(value: Option<u16>) -> Result<u16, &'static str> {
    let Some(port) = value else {
        return Err("missing port");
    };
    Ok(port)
}
```

Use `matches!` when only a boolean is needed. Match a reference when the owned value is needed afterwards:

```rust
if matches!(&status, Status::Active | Status::Pending) {
    process(&status);
}
```

`if let` is useful for one relevant shape. Let chains can combine bindings and guards on toolchains that support them; nested `if let` is the portable alternative.

## Exhaustiveness and public APIs

Exhaustive matching catches additions for enums the crate owns. A public `#[non_exhaustive]` enum requires external callers to include a wildcard arm, so handle known variants and choose an intentional fallback:

```rust
match response {
    Response::Ok => handle_ok(),
    Response::Retryable => retry(),
    _ => handle_unknown_response(),
}
```

Use `@` bindings when both a structure and the matched value are needed. Avoid destructuring merely for style when direct access is clearer.

## Load next

- Result/Option boundaries: `error-handling.md`
- Ownership of matched data: `ownership.md`
- Iteration cost: `performance.md`
