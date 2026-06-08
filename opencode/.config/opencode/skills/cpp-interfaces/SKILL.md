---
name: cpp-interfaces
description: C++ Core Guidelines I section: Interfaces. Use when designing interfaces, expressing pre/postconditions, using not_null/span, or ensuring ABI stability.
---

# C++ Interfaces (I Section)

Guidelines for interface design and contracts.

## Interface Principles

| Rule | Guideline |
|------|-----------|
| I.1 | Make interfaces explicit |
| I.4 | Make interfaces precisely and strongly typed |
| I.23 | Keep function argument count low |
| I.24 | Avoid adjacent swappable parameters |
| I.25 | Prefer empty abstract classes as interfaces |
| I.26 | Use C-style subset for cross-compiler ABI |
| I.27 | Consider Pimpl for stable library ABI |

## Preconditions and Postconditions

```cpp
// BAD: implicit precondition
int sqrt(int x);  // what if x < 0?

// GOOD: explicit precondition (using GSL)
int sqrt(int x) {
    Expects(x >= 0);
    // ...
}

// GOOD: explicit postcondition
int sqrt(int x) {
    Ensures(result >= 0);
    // ...
}
```

## Pointer Semantics

| Type | Meaning | Rule |
|------|---------|------|
| `not_null<T*>` | Pointer that must not be null | I.12 |
| `span<T>` | Sequence (replaces `T*, size`) | I.13, F.24 |
| `T*` | Position only, no ownership | I.11, F.42 |

## Anti-Patterns

```cpp
// BAD: raw pointer for sequence
void process(int* data, int size);

// GOOD: span
void process(span<int> data);

// BAD: implicit null allowed
void set_name(char* name);  // can pass null

// GOOD: not_null
void set_name(not_null<char*> name);

// BAD: too many params
void create_user(string name, string email, int age, string addr, string phone);

// GOOD: struct
struct UserParams { string name, email, addr, phone; int age; };
void create_user(UserParams p);

// BAD: singleton
class Logger { static Logger& instance(); };

// GOOD: dependency injection
class Logger { /* ... */ };
void init(Logger& log);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-avoid-non-const-global-variables` | I.2, R.6 |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | I.13 |
| `cppcoreguidelines-interfaces-global-init` | I.22 |
| `bugprone-easily-swappable-parameters` | I.24 |
| `bugprone-throwing-static-initialization` | I.22 |
| `misc-static-initialization-cycle` | I.22 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
