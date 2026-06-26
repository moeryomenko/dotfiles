# C++ Core Guidelines Master Index

Entry point for C++ Core Guidelines (Stroustrup/Sutter). Routes to domain-specific features based on the task.

## Section Overview

| Section | Topic | Feature |
|---------|-------|---------|
| **P** | Philosophy | -- (inlined here) |
| **I** | Interfaces | `interfaces` |
| **F** | Functions | `functions` |
| **C** | Classes | `classes` |
| **Enum** | Enumerations | `enumerations` |
| **R** | Resource management | `resource-management` |
| **ES** | Expressions/statements | `expressions` |
| **Per** | Performance | `performance` |
| **CP** | Concurrency | `concurrency` |
| **E** | Error handling | `error-handling` |
| **Con** | Constants | `constants` |
| **T** | Templates | `templates` |
| **CPL** | C-style | `modernize` |
| **SF** | Source files | `source-files` |
| **SL** | Standard Library | -- (std lib usage) |

## Philosophy (P section)

Core principles guiding all rules:

1. **Express ideas directly in code** — code should communicate intent
2. **Write in ISO Standard C++** — avoid compiler-specific extensions
3. **Express intent** — comments explain why, not what
4. **Prefer statically type safe programs**
5. **Prefer compile-time checking to run-time checking**
6. **What cannot be checked at compile time should be checkable at runtime**
7. **Catch early**: compile time, then link time, then runtime
8. **Don't leak resources** — use RAII for everything
9. **Don't waste time or space** — pay only for what you use
10. **Prefer immutable data to mutable data** — const by default
11. **Encapsulate messy constructs** rather than spreading them
12. **Use supporting tools** — clang-tidy, sanitizers, etc.
13. **Use libraries whenever possible** — don't reinvent the wheel

### Applying Philosophy

The philosophy sections guide high-level design decisions:

```cpp
// Intent obscured
auto r = some_obj - another_obj;

// Intent explicit
auto distance = compute_distance(some_obj, another_obj);
```

```cpp
// Type-unsafe interface
void process(void* data, int type_tag);

// Strongly typed
template<typename T>
void process(T&& data);
```

```cpp
// Mutable by default — risky
std::string name = "hello";

// Const by default — safe
const std::string name = "hello";
```

## Quick Consultation Decision Tree

Start here to route to the right feature:

```
What are you doing?
  |
  +-- Writing new code: load functions + classes + resource-management
  |
  +-- Reviewing code: load clang-tidy + domain feature
  |
  +-- Modernizing legacy code: load modernize
  |
  +-- Debugging:
  |     +-- Crash analysis (core dump, segfault): load crash-debug
  |     +-- Live debugging (GDB, STL inspection): load debug
  |
  +-- Setting up tooling: load clang-tidy
  |
  +-- Cross-cutting concern: load guidelines (this file) + relevant features
```

## Standard Library Guidance

### Containers

| Container | Use Case | Notes |
|-----------|----------|-------|
| `vector<T>` | Default sequence container | Contiguous storage, cache-friendly |
| `string` | Text data | SSO-optimized, avoid `string_view` for ownership |
| `span<T>` | Non-owning view of sequence | Prefer over `T* + size` |
| `array<T, N>` | Fixed-size array | Stack-allocated, no overhead |
| `map` / `unordered_map` | Associative lookup | Choose based on iteration vs access pattern |
| `optional<T>` | May-or-may-not-have value | Prefer over out-params or sentinel values |
| `variant<Ts...>` | Type-safe union | Prefer over raw unions or void* |

### Algorithm Selection

```cpp
// Linear search (unsorted): find, find_if
// Binary search (sorted): lower_bound, binary_search
// Transform: transform, for_each
// Sort: sort (random-access), stable_sort
// Partition: partition, stable_partition, nth_element
// Min/max: min, max, minmax, clamp
// Numeric: accumulate, inner_product, adjacent_difference
```

## Clang-Tidy Integration

For detailed checker configuration, suppression rules, and CI integration, load `clang-tidy`.

Key check groups by section:

| Section | Check Group | Priority |
|---------|-------------|----------|
| I | `cppcoreguidelines-*` | high |
| F | `cppcoreguidelines-*`, `performance-*` | high |
| C | `cppcoreguidelines-*`, `modernize-*` | high |
| R | `cppcoreguidelines-*`, `bugprone-*` | critical |
| ES | `cppcoreguidelines-*`, `modernize-*` | high |
| CP | `concurrency-*`, `cppcoreguidelines-*` | high |
| E | `bugprone-*`, `modernize-*` | high |
| Per | `performance-*` | medium |

### Profile-Based Check Selection

```yaml
# Minimal profile (safe defaults)
Checks: '-*,bugprone-*,performance-*'

# Standard profile (Core Guidelines compliant)
Checks: '-*,cppcoreguidelines-*,bugprone-*,performance-*,modernize-*'

# Maximum profile (everything but style)
Checks: '-*,cppcoreguidelines-*,bugprone-*,performance-*,modernize-*,
            readability-*,-readability-identifier-length,concurrency-*'
```

## Decision Guide

- **Writing new C++ code**: Load `functions`, `classes`, `resource-management`
- **Reviewing code**: Load `clang-tidy`, then the relevant domain feature
- **Modernizing legacy code**: Load `modernize`
- **Fixing concurrency bugs**: Load `concurrency`
- **Performance tuning**: Load `performance`
- **Error handling design**: Load `error-handling`
- **Template/generic code**: Load `templates`
- **Interface design**: Load `interfaces`
- **Cross-cutting**: Load `guidelines` (this file) for section navigation, then specific features

## Feature Interdependencies

Features reference each other for cross-cutting concerns:

| When Working On | Also Consider Loading |
|-----------------|----------------------|
| functions | interfaces (parameter types), resource-management (ownership params) |
| classes | functions (operator overloads), resource-management (RAII members) |
| templates | functions (perfect forwarding), expressions (SFINAE) |
| error-handling | resource-management (RAII for safety), classes (dtor noexcept) |
| concurrency | error-handling (exception safety in threads), classes (lock members) |
| modernize | clang-tidy (automated migration), expressions (new init syntax) |
| performance | resource-management (allocation patterns), expressions (move semantics) |
| interfaces | functions (parameter passing), source-files (header organization) |

## References

- Full rule/checker mapping: individual feature files list their clang-tidy checks
- C++ Core Guidelines official: https://isocpp.github.io/CppCoreGuidelines/
- For clang-tidy configuration: load the `clang-tidy` feature
