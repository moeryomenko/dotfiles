# Functions (F Section) - Rules and Checker Mapping

## F.1 - F.11: Function Design

| Rule | Guideline | Checker |
|------|-----------|---------|
| F.1 | Package meaningful operations as named functions | -- |
| F.2 | Single logical operation per function | `readability-function-size` |
| F.3 | Keep functions short and simple | `readability-function-size` |
| F.4 | `constexpr` for compile-time evaluable | -- |
| F.5 | `inline` for small + time-critical | `readability-redundant-inline-specifier` |
| F.6 | `noexcept` when must not throw | `modernize-use-noexcept` |
| F.7 | `T*`/`T&` over smart pointers for general use | `readability-avoid-const-params-in-decls` |
| F.8 | Prefer pure functions | -- |
| F.9 | Unused parameters unnamed | `misc-unused-parameters` |
| F.10 | Name reusable operations | -- |
| F.11 | Unnamed lambda for one-use simple function object | -- |

## F.15 - F.27: Parameter Passing

| Rule | Guideline | Checker |
|------|-----------|---------|
| F.15 | Simple and conventional passing | -- |
| F.16 | In: value (cheap) or `const&` (expensive) | `modernize-pass-by-value`, `readability-non-const-parameter`, `performance-unnecessary-value-param` |
| F.17 | In-out: `T&` | `readability-non-const-parameter` |
| F.18 | Will-move: `T&&` + `std::move` | `cppcoreguidelines-rvalue-reference-param-not-moved`, `performance-move-const-arg` |
| F.19 | Forward: `T&&` + `std::forward` | `cppcoreguidelines-missing-std-forward`, `bugprone-forwarding-reference-overload`, `bugprone-move-forwarding-reference` |
| F.20 | Out: return value over output param | -- |
| F.21 | Multiple out: return struct | -- |
| F.22 | `T*`/`owner<T*>` for single object | -- |
| F.23 | `not_null<T*>` for non-null | -- |
| F.24 | `span<T>` for sequence | `cppcoreguidelines-pro-bounds-array-to-pointer-decay` |
| F.25 | `zstring` for C-style string | -- |
| F.26 | `unique_ptr<T>` for ownership transfer | -- |
| F.27 | `shared_ptr<T>` for shared ownership | -- |

## F.42 - F.60: Return Types and Lambdas

| Rule | Guideline | Checker |
|------|-----------|---------|
| F.42 | `T*` for position only | -- |
| F.43 | Never return pointer/ref to local | `bugprone-return-const-ref-from-parameter` |
| F.44 | `T&` when copy undesirable, no "no object" | -- |
| F.45 | Don't return `T&&` | -- |
| F.46 | `int` for `main()` | -- |
| F.47 | `T&` from assignment operators | `misc-unconventional-assign-operator` |
| F.48 | Don't `return std::move(local)` | `performance-unnecessary-copy-initialization` |
| F.49 | Don't return `const T` | `readability-const-return-type` |
| F.50 | Lambda when function won't do | -- |
| F.51 | Default args over overloading | -- |
| F.52 | Capture by reference for local lambdas | -- |
| F.53 | Capture by value for non-local lambdas | -- |
| F.54 | No `[=]` when capturing `this`/members | `cppcoreguidelines-misleading-capture-default-by-value` |
| F.55 | No `va_arg` | `cppcoreguidelines-pro-type-vararg`, `modernize-avoid-variadic-functions` |
| F.56 | Avoid unnecessary condition nesting | -- |
| F.60 | `T*` over `T&` when "no arg" valid | -- |
