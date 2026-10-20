# Ecosystem Integration

Add a dependency only after checking whether the standard library or an existing project dependency fits. Evaluate maintenance, license, MSRV, feature surface, transitive footprint, security posture, API compatibility, operational behavior, and ownership of future updates—not popularity alone.

## Cargo dependencies and features

Use explicit version requirements and features needed by the crate. Optional dependencies create an implicit feature of the same name unless referenced with `dep:`; `dep:` suppresses that implicit feature so a public feature can have a deliberate name or combine dependencies.

```toml
[dependencies]
serde = { version = "1", optional = true, features = ["derive"] }

[features]
serialization = ["dep:serde"]
```

Features are generally additive, but feature design also needs compatibility, default-feature, target, and semver analysis. Cargo's feature resolution can unify feature requests within a resolved graph; test supported feature combinations instead of assuming an isolated package's selection is the only one present.

## Foreign-function interfaces

Define an FFI boundary from the foreign API's ABI, ownership, nullability, initialization, panic, threading, allocator, and error conventions. Rust 2024 extern blocks are `unsafe extern`; individual items can be declared `safe` only when Rust callers can uphold their preconditions without `unsafe`.

```rust
unsafe extern "C" {
    unsafe fn foreign_buffer_free(ptr: *mut u8);
}

struct Buffer {
    ptr: std::ptr::NonNull<u8>,
}

impl Drop for Buffer {
    fn drop(&mut self) {
        // SAFETY: `ptr` is uniquely owned and originated from the paired foreign allocator.
        unsafe { foreign_buffer_free(self.ptr.as_ptr()) };
    }
}
```

A wrapper is safe only if its constructor and methods enforce all foreign preconditions. Consider zero-length allocation, ownership transfer, allocator pairing, panics across the boundary, and `Send`/`Sync` separately. Generate bindings with tools such as `bindgen` only from reviewed headers and retain an update/review process.

`#![forbid(unsafe_code)]` constrains code in the crate where it is active; it does not prove transitive dependencies or FFI are safe.

## Load next

- FFI soundness: `unsafe.md`
- Feature and workspace policy: `project-structure.md`
- Serialization contracts: `serde.md`
