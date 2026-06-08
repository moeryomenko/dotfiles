---
name: cpp-enumerations
description: C++ Core Guidelines Enum section: Enumerations. Use when defining enumerations, choosing between enum and enum class, or configuring clang-tidy for enum rules.
---

# C++ Enumerations (Enum Section)

Guidelines for enumeration design and usage.

## Rules

| Rule | Guideline |
|------|-----------|
| Enum.1 | Prefer enumerations over macros |
| Enum.2 | Use enums for related named constants |
| Enum.3 | Prefer `enum class` over plain `enum` |
| Enum.4 | Define operations on enums for safe use |
| Enum.5 | Don't use `ALL_CAPS` for enumerators |
| Enum.6 | Avoid unnamed enumerations |
| Enum.7 | Specify underlying type only when necessary |
| Enum.8 | Specify enumerator values only when necessary |

## Enum Class (Preferred)

```cpp
// BAD: plain enum (pollutes scope, implicit int conversion)
enum Color { Red, Green, Blue };
int x = Red;  // implicit conversion

// GOOD: enum class (scoped, no implicit conversion)
enum class Color { Red, Green, Blue };
auto c = Color::Red;
// int x = c;  // error: no implicit conversion
```

## Enum Operations

Define operations for safe and simple use (Enum.4):

```cpp
enum class Color { Red, Green, Blue };

ostream& operator<<(ostream& os, Color c) {
    switch (c) {
    case Color::Red:   return os << "Red";
    case Color::Green: return os << "Green";
    case Color::Blue:  return os << "Blue";
    }
}
```

## Anti-Patterns

```cpp
// BAD: macros for constants
#define MAX_SIZE 1024
#define COLOR_RED 0
#define COLOR_GREEN 1

// GOOD: enum class
enum class Color { Red, Green, Blue };
constexpr int MaxSize = 1024;

// BAD: ALL_CAPS enumerators
enum class Status { SUCCESS, FAILURE };

// GOOD: CamelCase enumerators
enum class Status { Success, Failure };
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-use-enum-class` | Enum.3 |
| `modernize-macro-to-enum` | Enum.1 |
| `readability-enum-initial-value` | Enum.8 |
