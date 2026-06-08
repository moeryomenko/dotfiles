# Modernization - Rules and Checker Mapping

## modernize-* Checks (Complete)

| Check | Fix | C++ Version | Description |
|-------|-----|-------------|-------------|
| `modernize-avoid-bind` | Yes | C++11 | Replace `std::bind` with lambda |
| `modernize-avoid-c-arrays` | No | C++11 | Use `std::array` or `vector` |
| `modernize-avoid-c-style-cast` | Yes | C++11 | Use named casts |
| `modernize-avoid-setjmp-longjmp` | No | C++11 | Use exceptions |
| `modernize-avoid-variadic-functions` | No | C++11 | Use variadic templates |
| `modernize-concat-nested-namespaces` | Yes | C++17 | `namespace a::b::c {}` |
| `modernize-deprecated-headers` | Yes | C++11 | Use modern headers |
| `modernize-deprecated-ios-base-aliases` | Yes | C++11 | Use `std::ios_base::` members |
| `modernize-loop-convert` | Yes | C++11 | Convert to range-for |
| `modernize-macro-to-enum` | Yes | C++11 | Replace macro with enum |
| `modernize-make-shared` | Yes | C++11 | Use `make_shared` |
| `modernize-make-unique` | Yes | C++14 | Use `make_unique` |
| `modernize-pass-by-value` | Yes | C++11 | Pass by value when beneficial |
| `modernize-raw-string-literal` | Yes | C++11 | Use R"()" for strings |
| `modernize-redundant-void-arg` | Yes | C++11 | Remove void from `f()` |
| `modernize-replace-auto-ptr` | Yes | C++11 | Use `unique_ptr` |
| `modernize-replace-disallow-copy-and-assign-macro` | Yes | C++11 | Use `= delete` |
| `modernize-replace-random-shuffle` | Yes | C++11 | Use `std::shuffle` |
| `modernize-return-braced-init-list` | Yes | C++11 | Return `{}` |
| `modernize-shrink-to-fit` | Yes | C++11 | Use `vector::shrink_to_fit` |
| `modernize-type-traits` | Yes | C++11 | Use standard type traits |
| `modernize-unary-static-assert` | Yes | C++11 | `static_assert(cond)` |
| `modernize-use-auto` | Yes | C++11 | Use `auto` |
| `modernize-use-bool-literals` | Yes | C++11 | `true`/`false` not `1`/`0` |
| `modernize-use-concepts` | Yes | C++20 | Use concepts |
| `modernize-use-constraints` | Yes | C++20 | Use concept constraints |
| `modernize-use-default-member-init` | Yes | C++11 | In-class initializers |
| `modernize-use-designated-initializers` | Yes | C++20 | Designated init |
| `modernize-use-emplace` | Yes | C++11 | Use `emplace` |
| `modernize-use-equals-default` | Yes | C++11 | Use `= default` |
| `modernize-use-equals-delete` | Yes | C++11 | Use `= delete` |
| `modernize-use-integer-sign-comparison` | Yes | C++20 | `std::sign_comparison` |
| `modernize-use-nodiscard` | Yes | C++17 | `[[nodiscard]]` |
| `modernize-use-noexcept` | Yes | C++11 | Use `noexcept` |
| `modernize-use-nullptr` | Yes | C++11 | Use `nullptr` |
| `modernize-use-override` | Yes | C++11 | Use `override` |
| `modernize-use-ranges` | Yes | C++20 | Use ranges |
| `modernize-use-scoped-lock` | Yes | C++17 | Use `scoped_lock` |
| `modernize-use-starts-ends-with` | Yes | C++20 | `starts_with`/`ends_with` |
| `modernize-use-std-bit` | Yes | C++20 | `std::bit_*` functions |
| `modernize-use-std-format` | Yes | C++20 | `std::format` |
| `modernize-use-std-numbers` | Yes | C++20 | `std::numbers::pi` etc. |
| `modernize-use-std-print` | Yes | C++23 | `std::print` |
| `modernize-use-string-view` | Yes | C++17 | Use `string_view` |
| `modernize-use-structured-binding` | Yes | C++17 | Structured bindings |
| `modernize-use-trailing-return-type` | Yes | C++14 | Trailing return type |
| `modernize-use-transparent-functors` | Yes | C++14 | Transparent functors |
| `modernize-use-uncaught-exceptions` | Yes | C++17 | `uncaught_exceptions()` |
| `modernize-use-using` | Yes | C++11 | `using` over `typedef` |

## Recommended Modernization Order

1. **C++11 basics**: `nullptr`, `override`, `=default`, `=delete`, `auto_ptr` -> `unique_ptr`
2. **Smart pointers**: `make_unique`, `make_shared`
3. **Loops**: range-for, algorithms
4. **Casts**: named casts
5. **Macros**: enum class, constexpr
6. **C++14/17**: `string_view`, structured bindings, `scoped_lock`
7. **C++20**: concepts, ranges, `std::format`
