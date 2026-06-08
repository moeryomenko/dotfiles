---
name: cpp-expressions
description: C++ Core Guidelines ES section: Expressions and statements. Use when writing initializations, casts, loops, switches, arithmetic, or configuring clang-tidy for expression-level rules.
---

# C++ Expressions and Statements (ES Section)

Guidelines for initialization, casts, control flow, arithmetic, and macros.

## Initialization

- **Always initialize** (ES.20): `int x{0};` not `int x;`
- **Prefer `{}` initializer** (ES.23): `T x{args};` not `T x(args);`
- **Don't introduce variables early** (ES.21-22)
- **Prefer `auto` to avoid repetition** (ES.11)

## Casts

- **Avoid casts** (ES.48) -- they neuter the type system
- **If needed, use named casts** (ES.49):
  - `static_cast` -- compile-time checked conversions
  - `dynamic_cast` -- safe downcast in hierarchies
  - `const_cast` -- rarely, to add/remove `const`
  - `reinterpret_cast` -- only for low-level bit patterns
- **Never cast away `const`** (ES.50) unless absolutely necessary

## Control Flow

| Prefer | Over | Rule |
|--------|------|------|
| range-`for` | `for` | ES.71 |
| `for` | `while` (obvious loop var) | ES.72 |
| `while` | `for` (no loop var) | ES.73 |
| `switch` | `if` (choice) | ES.70 |
| -- | `do-while` | ES.75 |
| -- | `goto` | ES.76 |

- **Declare loop vars in initializer** (ES.74)
- **Minimize `break`/`continue`** (ES.77)
- **No implicit fallthrough in `switch`** (ES.78)
- **`default` for common cases only** (ES.79)

## Arithmetic

- **Don't mix signed/unsigned** (ES.100)
- **Unsigned for bit manipulation** (ES.101)
- **Signed for arithmetic** (ES.102)
- **Avoid narrowing conversions** (ES.46)
- **Don't overflow/underflow** (ES.103-104)
- **Don't divide by zero** (ES.105)
- **Don't use `unsigned` for subscripts** (ES.107) -- prefer `gsl::index`

## Pointers and Null

- **Use `nullptr`** not `0` or `NULL` (ES.47)
- **Don't dereference invalid pointers** (ES.65)
- **Prefer `std::array` over C-arrays** (ES.27)

## Macros

- **Don't use macros for text manipulation** (ES.30)
- **Don't use macros for constants/functions** (ES.31)
- **If you must: ALL_CAPS, unique names** (ES.32-33)
- **Don't define variadic functions** (ES.34)

## Anti-Patterns

```cpp
// BAD: C-style cast
int x = (int)f;

// GOOD: named cast
int x = static_cast<int>(f);

// BAD: NULL
if (p != NULL) {}

// GOOD: nullptr
if (p != nullptr) {}

// BAD: index loop
for (int i = 0; i < v.size(); ++i) { use(v[i]); }

// GOOD: range-for
for (const auto& x : v) { use(x); }

// BAD: uninitialized
int x;
// ... later
x = 42;

// GOOD: initialized
int x{42};
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-init-variables` | ES.20 |
| `cppcoreguidelines-avoid-goto` | ES.76 |
| `cppcoreguidelines-avoid-do-while` | ES.75 |
| `cppcoreguidelines-pro-type-cstyle-cast` | ES.48-49 |
| `cppcoreguidelines-pro-type-const-cast` | ES.50 |
| `cppcoreguidelines-pro-type-reinterpret-cast` | ES.48 |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | ES.42 |
| `cppcoreguidelines-pro-bounds-constant-array-index` | ES.55 |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | I.13 |
| `cppcoreguidelines-pro-type-vararg` | ES.34 |
| `cppcoreguidelines-macro-usage` | ES.30-33 |
| `modernize-use-nullptr` | ES.47 |
| `modernize-loop-convert` | ES.71-72 |
| `modernize-avoid-c-style-cast` | ES.48-49 |
| `modernize-use-auto` | ES.11 |
| `modernize-use-structured-binding` | ES.11 |
| `modernize-use-designated-initializers` | ES.23 |
| `modernize-avoid-variadic-functions` | ES.34 |
| `bugprone-narrowing-conversions` | ES.46 |
| `bugprone-signed-bitwise` | ES.101 |
| `bugprone-reserved-identifier` | ES.9 |
| `modernize-use-integer-sign-comparison` | ES.100 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
