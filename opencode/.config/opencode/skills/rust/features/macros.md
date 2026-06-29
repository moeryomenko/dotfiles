# Macros (MEDIUM)

## Reach for a Macro Only When a Function or Generic Cannot Express It

Prefer functions and generics first. Use macros for: code repetition that generics cannot handle, domain-specific syntax, or compile-time code generation.

## Rely on `macro_rules!` Hygiene

Use `$crate` for paths to your crate's items:

```rust
macro_rules! my_macro {
    ($val:expr) => {
        $crate::my_function($val)  // Not ::my_function
    };
}
```

## Capture with Precise Fragment Specifiers

| Specifier | What It Captures |
|-----------|-----------------|
| `:expr` | Expressions |
| `:stmt` | Statements |
| `:ty` | Types |
| `:ident` | Identifiers |
| `:pat` | Patterns |
| `:path` | Paths |
| `:tt` | Token tree (most flexible, least safe) |

Prefer specific specifiers over raw `:tt` where possible.

## Export Declarative Macros with `#[macro_export]`

```rust
#[macro_export]
macro_rules! my_macro {
    // ...
}
```

## Hide Macro-Generated Helper Items

```rust
#[doc(hidden)]
pub mod __private {
    pub fn helper() { /* ... */ }
}
```

## Put Procedural Macros in a Dedicated Crate

```toml
# Cargo.toml
[lib]
proc-macro = true
```

Re-export from the facade crate:

```rust
// In the main crate
pub use my_macro_derive::MyDerive;
```

## Build Procedural Macros with `syn`, `quote`, and `proc-macro2`

```rust
#[proc_macro_derive(MyDerive)]
pub fn my_derive(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let expanded = quote! {
        impl MyTrait for #input {
            // ...
        }
    };
    expanded.into()
}
```

## Report Proc-Macro Errors as Spanned Compile Errors

```rust
#[proc_macro]
pub fn my_macro(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as MyInput);
    
    if !input.is_valid() {
        return syn::Error::new(input.span(), "invalid input")
            .to_compile_error()
            .into();
    }
    
    // ...
}
```

Never panic in procedural macros — it produces inscrutable compiler output.

## Cross-References

- For function vs macro: load `performance`
- For anti-patterns: load `anti-patterns`
