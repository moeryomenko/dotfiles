# C++ Core Guidelines Master Index

Entry point for C++ Core Guidelines (Stroustrup/Sutter). Routes to domain-specific features based on the task.

## Section Overview

| Section | Topic | Rules | Feature |
|---------|-------|-------|---------|
| **P** | Philosophy | 13 | -- (inlined here) |
| **I** | Interfaces | 16 | `interfaces` |
| **F** | Functions | 43 | `functions` |
| **C** | Classes | 100+ | `classes` |
| **Enum** | Enumerations | 8 | `enumerations` |
| **R** | Resource management | 21 | `resource-management` |
| **ES** | Expressions/statements | 58 | `expressions` |
| **Per** | Performance | 20 | `performance` |
| **CP** | Concurrency | 38 | `concurrency` |
| **E** | Error handling | 21 | `error-handling` |
| **Con** | Constants | 5 | `constants` |
| **T** | Templates | 53 | `templates` |
| **CPL** | C-style | 3 | `modernize` |
| **SF** | Source files | 14 | `source-files` |
| **SL** | Standard Library | -- | (std lib usage) |

## Philosophy (P section)

Core principles guiding all rules:

1. **P.1** Express ideas directly in code — code should communicate intent
2. **P.2** Write in ISO Standard C++ — avoid compiler-specific extensions
3. **P.3** Express intent — comments explain why, not what
4. **P.4** Ideally, a program should be statically type safe
5. **P.5** Prefer compile-time checking to run-time checking
6. **P.6** What cannot be checked at compile time should be checkable at runtime
7. **P.7** Catch early: compile time, then link time, then runtime
8. **P.8** Don't leak any resources — use RAII for everything
9. **P.9** Don't waste time or space — pay only for what you use
10. **P.10** Prefer immutable data to mutable data — const by default
11. **P.11** Encapsulate messy constructs rather than spreading them
12. **P.12** Use supporting tools as appropriate — clang-tidy, sanitizers, etc.
13. **P.13** Use libraries whenever possible — don't reinvent the wheel

### Applying Philosophy

The philosophy sections guide high-level design decisions:

```cpp
// P.1 violation: intent obscured
auto r = some_obj - another_obj;
// What does subtraction mean? Is it a difference? Removal? Distance?

// P.1 compliant: intent explicit
auto distance = compute_distance(some_obj, another_obj);
```

```cpp
// P.4 violation: type-unsafe interface
void process(void* data, int type_tag);  // Caller must get type_tag right

// P.4 compliant: strongly typed
template<typename T>
void process(T&& data);  // Compiler ensures type correctness
```

```cpp
// P.10 violation: mutable by default
std::string name = "hello";
// 50 lines later: name modified by mistake

// P.10 compliant: const by default
const std::string name = "hello";
// Compiler error if someone tries to modify
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
  +-- Need specific guideline section:
  |     Match section letter above, load the corresponding feature
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
