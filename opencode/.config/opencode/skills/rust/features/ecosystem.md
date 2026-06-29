# Ecosystem Integration (MEDIUM)

**Triggers**: crate selection, dependency management, feature flags, workspace, FFI, bindgen, PyO3, wasm, napi-rs, Cargo.toml, cargo features, crate recommendation, version conflict, E0433, E0603.

## Core Question

**What is the right crate for this job, and how should it integrate?**

Before adding a dependency:
- Is there a standard library solution?
- What is the maintenance status and community health?
- What is the API stability and version policy?
- Can feature flags reduce the dependency footprint?

---

## Dependency Decision Flowchart

```
Can std solve it?
├─ Yes → Use std, no dependency needed
└─ No → Is there a de facto standard crate?
        ├─ Yes (serde, tokio, clap, reqwest, tracing)
        │   └─ Use it, it is well-vetted
        └─ No → Evaluate candidates:
                ├─ Maintenance: recent commits, issue response
                ├─ Community: active issues/PRs, downloads
                ├─ API stability: semver, breaking changes
                └─ Footprint: dependency count, compile time
```

---

## Crate Selection Criteria

| Criterion | Good Sign | Warning Sign |
|-----------|-----------|--------------|
| Maintenance | Commits within 3 months | Inactive >1 year |
| Community | Active issues, PR reviews | No responses, stale PRs |
| Documentation | Examples, API docs, README | Minimal or missing docs |
| Stability | Semver 1.x, MSRV policy | Frequent breaking at 0.x |
| Dependencies | Minimal, well-known deps | Heavy transitive deps |
| Safety | Uses `#![forbid(unsafe_code)]` | Unsafe without SAFETY comments |

### Recommended Crate Selection

| Need | Recommended | Alternatives |
|------|-------------|--------------|
| Serialization | serde | ron, bincode, msgpack |
| Async runtime | tokio | async-std, smol |
| HTTP server | axum | actix-web, warp, rocket |
| HTTP client | reqwest | ureq, surf |
| CLI parsing | clap | bpaf, argh, structopt |
| Error handling (lib) | thiserror | snafu |
| Error handling (app) | anyhow | eyre |
| Logging/Tracing | tracing | log, slog |
| Database (SQL) | sqlx | diesel, sea-orm |
| Database (NoSQL) | redis | mongodb |
| Date/time | time | chrono, jiff |
| UUID | uuid | — |
| Random | rand | fastrand |
| Regex | regex | — |
| Parallelism | rayon | — |
| Codegen | proc-macro2 + quote + syn | — |

---

## Cargo Features

### Feature Flags for Optional Functionality

```toml
[features]
default = ["std"]
std = []

# Optional serde support
serde = ["dep:serde", "dep:serde_derive"]

# Multiple features composition
full = ["serde", "cli", "observability"]
```

### Conditional Dependencies with `dep:`

Rust 1.60+ supports the `dep:` prefix to create implicit feature flags:

```toml
[dependencies]
serde = { version = "1", optional = true }

[features]
serde = ["dep:serde"]  # Creates a 'serde' feature that enables the dep
```

### Conditional Compilation in Code

```rust
#[cfg(feature = "serde")]
#[derive(Serialize, Deserialize)]
pub struct Config {
    pub host: String,
    pub port: u16,
}

#[cfg(not(feature = "serde"))]
pub struct Config {
    pub host: String,
    pub port: u16,
}
```

### Feature Unification in Workspaces

```toml
[workspace]
members = ["crates/*"]

[workspace.dependencies]
serde = "1"
tokio = { version = "1", features = ["full"] }
```

Cargo unifies features across the workspace — the same crate version across all
members gets the union of all requested features.

---

## Workspace Organization

### Standard Layout

```
my-project/
├── Cargo.toml              # [workspace]
├── crates/
│   ├── core/               # Core types and traits
│   ├── cli/                # CLI binary crate
│   ├── server/             # Server binary crate
│   └── storage/            # Storage abstraction
└── Cargo.lock
```

### Workspace Root

```toml
[workspace]
resolver = "2"
members = ["crates/*"]
edition = "2024"

[workspace.package]
version = "0.1.0"
edition = "2024"
license = "MIT"

[workspace.dependencies]
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
thiserror = "2"
```

### Internal Crate Dependencies

```toml
# crates/cli/Cargo.toml
[dependencies]
core = { path = "../core" }
serde = { workspace = true }
```

---

## FFI and Language Interop

### Language Interop Quick Reference

| Integration | Tool/Crate | Pattern |
|-------------|------------|---------|
| C -> Rust | `bindgen` | Auto-generate Rust FFI bindings from C headers |
| Rust -> C | `cbindgen` | Auto-generate C headers from Rust lib |
| Python <-> Rust | `pyo3` | Native Python extensions in Rust |
| Node.js <-> Rust | `napi-rs` | Native Node.js addons |
| WebAssembly | `wasm-bindgen`, `wasm-pack` | Compile to WASM for browser/server |

### FFI Safety Rules

```rust
// SAFETY: C API requires valid pointer, non-null
unsafe extern "C" {
    safe fn malloc(size: usize) -> *mut u8;
    unsafe fn free(ptr: *mut u8);
}

// Safe wrapper over unsafe FFI
pub struct Buffer {
    ptr: *mut u8,
    len: usize,
}

impl Buffer {
    pub fn new(size: usize) -> Option<Self> {
        // SAFETY: malloc returns null on failure, valid ptr otherwise
        let ptr = unsafe { malloc(size) };
        if ptr.is_null() {
            None
        } else {
            Some(Self { ptr, len: size })
        }
    }
}

impl Drop for Buffer {
    fn drop(&mut self) {
        // SAFETY: ptr was allocated by malloc, owned by us
        unsafe { free(self.ptr) };
    }
}
```

### FFI with `bindgen`

```rust
// Generated by bindgen from C header
extern "C" {
    pub fn ssl_new(ctx: *mut ssl_ctx) -> *mut ssl;
    pub fn ssl_connect(ssl: *mut ssl) -> c_int;
    pub fn ssl_free(ssl: *mut ssl);
}

// Safe wrapper
pub struct SslConnection {
    inner: *mut ssl,
}

impl SslConnection {
    pub fn new(ctx: &mut SslContext) -> Option<Self> {
        // SAFETY: ssl_new returns null on failure
        let inner = unsafe { ssl_new(ctx.as_mut_ptr()) };
        if inner.is_null() { None } else { Some(Self { inner }) }
    }

    pub fn connect(&mut self) -> Result<(), Error> {
        // SAFETY: inner is valid, initialized in new()
        let ret = unsafe { ssl_connect(self.inner) };
        if ret == 0 { Ok(()) } else { Err(Error::Handshake) }
    }
}
```

---

## Common Mistakes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| `extern crate` (2018+) | Unnecessary, legacy | Use `use` directly |
| `#[macro_use]` | Global pollution | Use explicit `use` |
| Wildcard version `*` | Unpredictable updates | Pin to semver range |
| Too many dependencies | Supply chain risk, compile time | Evaluate necessity |
| No `dep:` prefix for optional deps | Feature name collision | Use `dep:` syntax |
| Ignoring MSRV | Breaks users on older Rust | Document MSRV in Cargo.toml |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Vendoring everything | Maintenance burden, security updates | Trust crates.io with Cargo.lock |
| Unpinned GitHub deps `{ git = "..." }` | Unstable, untracked | Pin to revision |
| Re-implementing well-known crates | Wasted effort, bugs | Use established crate |
| No `resolver = "2"` in workspace | Feature unification issues | Explicitly set resolver |

---

## Cross-References

- For error handling in libs vs apps: load `error-handling`
- For unsafe FFI patterns: load `unsafe`
- For workspace structure: load `project-structure`
- For serialization: load `serde`
