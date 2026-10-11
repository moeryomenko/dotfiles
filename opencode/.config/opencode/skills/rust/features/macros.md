# Macros

Use a macro when syntax or compile-time generation provides value a function, generic, trait, or build step cannot provide clearly. Macros become public API when exported, so preserve diagnostics, hygiene, and expansion compatibility.

## Declarative macros

Use the narrowest fragment specifier that expresses the grammar and `$crate` for references to items in the defining crate.

```rust
#[macro_export]
macro_rules! ensure_nonempty {
    ($value:expr) => {
        if $value.is_empty() {
            return Err($crate::Error::Empty);
        }
    };
}
```

`#[macro_export]` exports at crate root; it is not needed for internal macros. Hidden helper modules can support expansions, but `#[doc(hidden)]` does not make them private or stable-free.

## Procedural macros

Proc macros need a `proc-macro` crate. Parse input, preserve identifiers and generics, and report user mistakes as `syn::Error` rather than panicking. A derive must implement for the parsed input identifier—not for the whole parsed syntax tree.

```rust
#[proc_macro_derive(MyDerive)]
pub fn my_derive(input: proc_macro::TokenStream) -> proc_macro::TokenStream {
    let input = syn::parse_macro_input!(input as syn::DeriveInput);
    let name = &input.ident;
    let (impl_generics, ty_generics, where_clause) = input.generics.split_for_impl();

    quote::quote! {
        impl #impl_generics MyTrait for #name #ty_generics #where_clause {}
    }
    .into()
}
```

Use `trybuild` or focused compile-fail tests for macro diagnostics and expansion edge cases. Keep generated APIs minimal; expansion spans and error messages are part of the developer experience.

## Load next

- API compatibility: `api-design.md`
- Build and dependency policy: `project-structure.md`
