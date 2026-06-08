---
name: cpp-core-guidelines
description: Master navigation for C++ Core Guidelines by Bjarne Stroustrup and Herb Sutter. Use when writing, reviewing, or modernizing C++ code to follow Core Guidelines rules across functions, classes, resource management, concurrency, templates, and more.
---

# C++ Core Guidelines Master

Entry point for C++ Core Guidelines. Route to domain-specific skills based on the task.

## Guideline Sections

| Section | Rules | Skill | Covers |
|---------|-------|-------|--------|
| **P** Philosophy | 13 | -- | High-level principles |
| **I** Interfaces | 16 | `cpp-interfaces` | Explicit interfaces, pre/postconditions, `not_null`, `span` |
| **F** Functions | 43 | `cpp-functions` | Parameter passing, return types, lambdas, `noexcept` |
| **C** Classes | 100+ | `cpp-classes` | Regular types, constructors, destructors, virtual, inheritance |
| **Enum** Enumerations | 8 | `cpp-enumerations` | `enum class`, strong typing |
| **R** Resource management | 21 | `cpp-resource-management` | RAII, smart pointers, ownership |
| **ES** Expressions | 58 | `cpp-expressions` | Initialization, casts, loops, arithmetic, macros |
| **Per** Performance | 20 | `cpp-performance` | Optimization principles, memory layout |
| **CP** Concurrency | 38 | `cpp-concurrency` | Threads, mutexes, atomics, coroutines |
| **E** Error handling | 21 | `cpp-error-handling` | Exceptions, `noexcept`, RAII safety |
| **Con** Constants | 5 | `cpp-constants` | `const` correctness, `constexpr` |
| **T** Templates | 53 | `cpp-templates` | Concepts, TMP, generic design |
| **CPL** C-style | 3 | `cpp-modernize` | Prefer C++ over C |
| **SF** Source files | 14 | `cpp-source-files` | Headers, includes, namespaces |
| **SL** Standard Library | -- | -- | Standard library usage |

## Quick Decision Guide

- **Writing new C++ code**: Load `cpp-functions`, `cpp-classes`, `cpp-resource-management`
- **Reviewing code**: Load `cpp-clang-tidy` for checker configuration, then domain skill
- **Modernizing legacy code**: Load `cpp-modernize`
- **Fixing concurrency bugs**: Load `cpp-concurrency`
- **Performance tuning**: Load `cpp-performance`
- **Error handling design**: Load `cpp-error-handling`
- **Template/generic code**: Load `cpp-templates`

## Philosophy (P section)

Core principles guiding all rules:

1. **P.1** Express ideas directly in code
2. **P.2** Write in ISO Standard C++
3. **P.3** Express intent
4. **P.4** Ideally, a program should be statically type safe
5. **P.5** Prefer compile-time checking to run-time checking
6. **P.8** Don't leak any resources
7. **P.9** Don't waste time or space
8. **P.10** Prefer immutable data to mutable data
9. **P.12** Use supporting tools as appropriate

## Clang-Tidy Integration

For checker configuration and mapping, load `cpp-clang-tidy`.

Key check groups: `cppcoreguidelines-*`, `bugprone-*`, `modernize-*`, `performance-*`, `readability-*`.
