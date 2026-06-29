# Unsafe Code (CRITICAL)

**Triggers**: unsafe, raw pointer, FFI, extern, transmute, *mut, *const, union, #[repr(C)], libc, std::ffi, MaybeUninit, NonNull, SAFETY comment, soundness, undefined behavior, UB, safe wrapper, bindgen, CString, CStr, Send, Sync.

## Write `// SAFETY:` Comment Above Every `unsafe` Block

Every `unsafe` block requires a `// SAFETY:` comment explaining why this specific operation upholds the required invariants. Enable `clippy::undocumented_unsafe_blocks` to catch omissions.

```rust
// SAFETY: we just checked slice has at least 11 elements
unsafe { *slice.as_ptr().add(10) }
```

## Write `# Safety` Section in Every `unsafe fn`

The `# Safety` doc section describes the *caller's* obligations (preconditions that must hold for the call to be sound). The inline `// SAFETY:` comment targets *auditors* of the implementation.

```rust
/// # Safety
/// - `ptr` must be valid for reads for at least `offset + 1` bytes.
/// - `ptr` must not be null and must be properly aligned.
pub unsafe fn read_at(ptr: *const u8, offset: usize) -> u8 {
    // SAFETY: caller guarantees ptr is valid for offset + 1 bytes
    unsafe { *ptr.add(offset) }
}
```

In the 2024 edition, `unsafe_op_in_unsafe_fn` lint requires `// SAFETY:` comments even inside `unsafe fn` bodies.

## Keep `unsafe` Blocks as Small as Possible

Mark only the operation that requires unsafety, not the surrounding safe code:

```rust
// Bad: entire function body in unsafe
unsafe {
    let slice = std::slice::from_raw_parts(ptr, len);
    let val = slice[0];
    println!("{}", val);
}

// Good: only the unsafe operation
let slice = unsafe { std::slice::from_raw_parts(ptr, len) };
let val = slice[0];  // Safe
println!("{}", val);  // Safe
```

## Run `cargo miri test` in CI

Every crate containing `unsafe` code should run Miri in CI to detect undefined behavior.

## Use `MaybeUninit<T>` for Uninitialized Memory

Never use `mem::uninitialized()` or `mem::zeroed()` for types with validity invariants.

```rust
use std::mem::MaybeUninit;

let mut data = MaybeUninit::<[u8; 1024]>::uninit();
// SAFETY: we initialize the first element
data.as_mut_ptr().write(42);
```

## In Rust 2024, Wrap `extern` Blocks in `unsafe extern { }`

```rust
unsafe extern "C" {
    safe fn malloc(size: usize) -> *mut u8;  // safe to call
    unsafe fn free(ptr: *mut u8);            // unsafe to call
}
```

## Document Invariants When Manually Implementing `Send` or `Sync`

Prefer letting the compiler derive them automatically:

```rust
// SAFETY: MyType contains only Send-compatible fields
unsafe impl Send for MyType {}
```

## Use `#[unsafe(no_mangle)]` in Rust 2024

Not the bare attribute form:

```rust
#[unsafe(no_mangle)]
pub extern "C" fn my_function() {}
```

## Cross-References

- For SAFETY comments: load `documentation`
- For lint enforcement: load `linting`
- For types used with unsafe: load `type-safety`
- For FFI interop and bindgen: load `ecosystem`
- For PhantomData and variance: load `type-driven`
