# Project Structure (LOW)

## Keep `main.rs` Minimal

Logic should live in `lib.rs` with `main.rs` as a thin entry point:

```rust
// src/main.rs
fn main() {
    if let Err(e) = my_crate::run() {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}

// src/lib.rs
pub fn run() -> Result<(), Error> { /* ... */ }
```

## Organize Modules by Feature

Not by technical layer:

```
src/
  auth/
    mod.rs
    login.rs
    permissions.rs
  api/
    mod.rs
    routes.rs
    middleware.rs
  models.rs
  lib.rs
```

## Keep Small Projects Flat

For small projects (under ~10 modules), a flat structure is simpler:

```
src/
  auth.rs
  api.rs
  models.rs
  lib.rs
```

## Use `mod.rs` for Multi-File Modules

```
src/
  parser/
    mod.rs
    lexer.rs
    ast.rs
```

## Use `pub(crate)` for Internal APIs

```rust
pub(crate) fn internal_helper() { /* ... */ }
```

## Use `pub(super)` for Parent-Only Visibility

```rust
mod inner {
    pub(super) fn helper() { /* only usable by parent module */ }
}
```

## Use `pub use` for Clean Public API

Re-export to hide internal module hierarchy:

```rust
// src/lib.rs
mod internal;
pub use internal::PublicType;
```

## Create a Prelude Module for Common Imports

```rust
// src/prelude.rs
pub use crate::types::{UserId, OrderId};
pub use crate::traits::{Serialize, Deserialize};
```

## Put Multiple Binaries in `src/bin/`

```
src/
  bin/
    server.rs
    client.rs
    tool.rs
  lib.rs
```

## Use Workspaces for Large Projects

```
my-project/
  Cargo.toml        # [workspace]
  crates/
    core/
    cli/
    web/
```

## Use Workspace Dependency Inheritance

```toml
# workspace Cargo.toml
[workspace.dependencies]
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }

# crate Cargo.toml
[dependencies]
serde.workspace = true
tokio.workspace = true
```

## Design Cargo Features to Be Strictly Additive

Features should only add functionality, never remove it. Follow the `dep:` syntax for optional dependencies:

```toml
[features]
serde = ["dep:serde", "dep:serde_derive"]
```

## Declare MSRV in `Cargo.toml`

```toml
[package]
rust-version = "1.75"  # Minimum supported Rust version
```

Test it in CI.

## Keep `build.rs` Minimal

Deterministic, idempotent, and minimal. Prefer code generation in build scripts over runtime initialization.

## Cross-References

- For workspace lint setup: load `linting`
- For visibility with tests: load `testing`
