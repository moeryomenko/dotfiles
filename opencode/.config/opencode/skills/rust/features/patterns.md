# Pattern Matching (MEDIUM)

## Use `let ... else` for Early-Return Pattern Extraction

```rust
let Some(value) = optional_value else {
    return Err("missing value");
};
```

## Use `matches!()` for Boolean Pattern Tests

```rust
if matches!(status, Status::Active | Status::Pending) {
    process();
}

// Instead of:
if let Status::Active | Status::Pending = status {
    process();
}
```

## Use `if let` Chains to Combine Pattern Bindings and Conditions

```rust
if let Some(user) = users.get(id)
    && user.is_active()
    && let Some(role) = user.role()
{
    grant_access(role);
}
```

## Match Owned Enums Exhaustively

Avoid catch-all `_` that hides new variants:

```rust
match status {
    Status::Active => handle_active(),
    Status::Inactive => handle_inactive(),
    Status::Pending => handle_pending(),
    // No `_ =>` — so adding a new variant causes a compile error
}
```

## Use `@` Bindings to Capture While Matching

```rust
if let Some(user @ User { name: "admin", .. }) = maybe_user {
    println!("Admin logged in: {:?}", user);
}
```

## Cross-References

- For early return patterns: load `error-handling`
- For destructuring in loops: load `performance`
