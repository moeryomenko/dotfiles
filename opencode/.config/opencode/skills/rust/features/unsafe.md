# Unsafe Code

Use unsafe only when a safe design cannot meet the requirement. Before writing it, state the safety invariant, identify who establishes and preserves it, and prefer a small safe wrapper that validates inputs at its boundary.

## Scope and documentation

Keep unsafe operations as narrow as practical and keep surrounding logic safe. A `// SAFETY:` explanation is valuable review documentation and can be enforced by a project policy such as `clippy::undocumented_unsafe_blocks`; it is not itself a language requirement.

An `unsafe fn` documents obligations placed on its caller with a `# Safety` section. In Rust 2024, `unsafe_op_in_unsafe_fn` requires unsafe operations inside an `unsafe fn` to remain in explicit `unsafe {}` blocks; it does not require a particular comment format.

```rust
/// # Safety
/// `ptr` must be valid for one properly aligned `u8` read.
pub unsafe fn read_byte(ptr: *const u8) -> u8 {
    // SAFETY: this is the caller's documented precondition.
    unsafe { *ptr }
}
```

## Initialization and raw memory

Use `MaybeUninit<T>` to control initialization, and call `assume_init` only after the entire claimed `T` is initialized. Pointer types must match the object being written.

```rust
use std::mem::MaybeUninit;

let mut bytes = MaybeUninit::<[u8; 4]>::uninit();
let ptr = bytes.as_mut_ptr().cast::<u8>();
for (index, byte) in [1_u8, 2, 3, 4].into_iter().enumerate() {
    // SAFETY: `index < 4`, and each byte slot is written exactly once.
    unsafe { ptr.add(index).write(byte) };
}
// SAFETY: all four elements of the array have been initialized.
let bytes = unsafe { bytes.assume_init() };
assert_eq!(bytes, [1, 2, 3, 4]);
```

Avoid deprecated/unreliable initialization shortcuts. Zero bytes are not a valid value for every Rust type.

## Auto traits, FFI, and tools

Do not manually implement `Send` or `Sync` merely because fields look compatible. Prove the full aliasing, ownership, thread-affinity, and synchronization contract, including operations exposed by the type. Prefer compiler-derived auto traits.

Rust 2024 requires `unsafe extern` blocks. ABI, layout, ownership, nullability, callbacks, and unwinding rules are part of every FFI contract; use `repr(C)` only where the counterpart ABI/layout requires it. Unsafe attributes such as `#[unsafe(no_mangle)]` have collision and linker-contract obligations.

Run Miri as an additional supported test target when it can exercise the relevant unsafe paths. It finds classes of undefined behavior but does not prove a design sound. Use sanitizers, fuzzing, platform tests, and review where they fit the project.

## Load next

- FFI/dependency integration: `ecosystem.md`
- Type/lifetime invariants: `type-safety.md`, `type-driven.md`
- Resource destruction: `lifecycle.md`
- Lint policy: `linting.md`
