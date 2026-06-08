---
name: cpp-templates
description: C++ Core Guidelines T section: Templates and generic programming. Use when designing templates, concepts, template metaprogramming, SFINAE, or generic algorithms.
---

# C++ Templates (T Section)

Guidelines for template design, concepts, and generic programming.

## Template Purpose

- **Raise abstraction level** (T.1): express ideas at higher level
- **Express algorithms for many types** (T.2)
- **Express containers and ranges** (T.3)
- **Syntax tree manipulation** (T.4)

## Concepts (C++20)

- **Specify concepts for all template args** (T.10)
- **Use standard concepts when possible** (T.11)
- **Prefer concept names over `auto`** (T.12)
- **Require essential properties only** (T.41)

```cpp
// BAD: unconstrained
template<typename T>
void sort(T& c);

// GOOD: constrained with concepts
template<ranges::sortable_range T>
void sort(T& c);

// GOOD: standard concept
template<std::sortable T>
void sort(T& c);
```

## Template Design

- **Avoid unconstrained templates with common names** (T.47)
- **Minimize context dependencies** (T.60)
- **Don't over-parameterize members** (T.61, SCARY pattern)
- **Non-dependent members: non-templated base** (T.62)
- **Use `{}` not `()` in templates** (T.68) to avoid ambiguity
- **Unqualified calls = customization points** (T.69)

## Aliases

- **Prefer `using` over `typedef`** (T.43)
- **Use aliases to simplify notation** (T.42)

## Specialization

- **Specialize class templates for alt implementations** (T.64)
- **Tag dispatch for function alternatives** (T.65)
- **Don't specialize function templates** (T.144)

## TMP

- **Use TMP only when really needed** (T.120)
- **Primarily to emulate concepts** (T.121)
- **Use `constexpr` for compile-time values** (T.123)
- **Prefer standard-library TMP** (T.124)

## Anti-Patterns

```cpp
// BAD: unconstrained template
template<typename T>
T add(T a, T b) { return a + b; }

// GOOD: constrained
template<std::semiring T>
T add(T a, T b) { return a + b; }

// BAD: typedef
typedef std::vector<int> IntVec;

// GOOD: using
using IntVec = std::vector<int>;

// BAD: () in template
T x(a, b); // ambiguous: declaration or construction?

// GOOD: {} in template
T x{a, b}; // always construction
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `modernize-use-concepts` | T.10 |
| `modernize-use-constraints` | T.10 |
| `bugprone-incorrect-enable-if` | T.48 |
| `modernize-use-using` | T.43 |
| `modernize-type-traits` | T.124 |
| `modernize-unary-static-assert` | T.150 |
| `misc-static-assert` | T.150 |
| `readability-redundant-qualified-alias` | T.42 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
