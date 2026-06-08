---
name: cpp-functions
description: C++ Core Guidelines F section: Functions. Use when designing function interfaces, parameter passing conventions, return types, lambdas, or configuring clang-tidy for function-related rules.
---

# C++ Functions (F Section)

Guidelines for function design, parameter passing, return conventions, and lambdas.

## Parameter Passing Conventions

| Intent | Convention | Rule |
|--------|-----------|------|
| In (cheap copy) | `T` (by value) | F.16 |
| In (expensive) | `const T&` | F.16 |
| In-out | `T&` | F.17 |
| Will-move-from | `T&&` + `std::move` | F.18 |
| Forward | `T&&` + `std::forward` | F.19 |
| Out | return value, not output param | F.20 |
| Multiple out | return struct | F.21 |
| Position (no ownership) | `T*` | F.22, F.42 |
| Non-null | `not_null<T*>` | F.23 |
| Sequence | `span<T>` | F.24 |
| Transfer ownership | `unique_ptr<T>` | F.26 |
| Shared ownership | `shared_ptr<T>` | F.27 |

## Return Type Rules

- **Never return local by pointer/reference**: F.43
- **Don't return `T&&`**: F.45
- **Don't `return std::move(local)`**: F.48 (RVO handles it)
- **Don't return `const T`**: F.49 (prevents move of caller's result)
- **Assignment operators return `T&`**: F.47

## Lambda Rules

- **One-use simple**: unnamed lambda (F.11)
- **Local use**: capture by reference (F.52)
- **Non-local use**: capture by value (F.53)
- **Never `[=]` when capturing `this`**: F.54

## Function Properties

- **Must not throw**: declare `noexcept` (F.6)
- **Compile-time evaluable**: `constexpr` (F.4)
- **Small + time-critical**: `inline` (F.5)
- **Unused params**: leave unnamed (F.9)
- **Prefer default args over overloading**: F.51

## Anti-Patterns

```cpp
// BAD: varargs
void log(const char* fmt, ...);

// GOOD: variadic templates or overloads
template<typename... Args>
void log(format_string<Args...> fmt, Args&&... args);

// BAD: raw pointer for sequence
void process(int* data, int size);

// GOOD: span
void process(span<int> data);

// BAD: return std::move of local
string name() { return std::move(s); }

// GOOD: RVO
string name() { return s; }
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-rvalue-reference-param-not-moved` | F.18 |
| `cppcoreguidelines-misleading-capture-default-by-value` | F.54 |
| `cppcoreguidelines-missing-std-forward` | F.19 |
| `cppcoreguidelines-pro-type-vararg` | F.55 |
| `modernize-use-noexcept` | F.6 |
| `modernize-pass-by-value` | F.16 |
| `misc-unused-parameters` | F.9 |
| `readability-non-const-parameter` | F.16 |
| `readability-const-return-type` | F.49 |
| `performance-unnecessary-value-param` | F.16 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
