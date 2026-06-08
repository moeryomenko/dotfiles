---
name: cpp-source-files
description: C++ Core Guidelines SF section: Source files. Use when organizing headers, managing includes, configuring namespaces, or setting up clang-tidy for source file rules.
---

# C++ Source Files (SF Section)

Guidelines for file organization, headers, includes, and namespaces.

## File Conventions

| Rule | Guideline |
|------|-----------|
| SF.1 | `.cpp` for code, `.h` for interfaces |
| SF.2 | Headers: no object/non-inline function definitions |
| SF.3 | Use headers for multi-file declarations |
| SF.4 | Include headers before other declarations |
| SF.5 | `.cpp` must include its own header |
| SF.8 | Use `#include` guards for all headers |
| SF.11 | Headers must be self-contained |
| SF.12 | `""` for local, `<>` for system |
| SF.13 | Use portable header identifiers |

## Include Order

```cpp
// 1. Own header first (SF.5)
#include "myclass.h"

// 2. C standard library
#include <cassert>
#include <cstring>

// 3. C++ standard library
#include <memory>
#include <string>
#include <vector>

// 4. Other libraries
#include <boost/...>

// 5. Project headers
#include "other.h"
```

## Namespaces

- **Use namespaces for logical structure** (SF.20)
- **No `using namespace` at global scope in headers** (SF.7)
- **`using namespace` only for transition, foundation libs, or local scope** (SF.6)

```cpp
// BAD: global using in header
// foo.h
using namespace std;

// GOOD: local using in implementation
// foo.cpp
void f() {
    using namespace std;
    vector<int> v;
}

// GOOD: namespace
namespace myproject::network {
    class Socket { /* ... */ };
}
```

## Dependencies

- **Avoid cyclic dependencies** (SF.9)
- **Don't depend on implicit includes** (SF.10)

## Anti-Patterns

```cpp
// BAD: definitions in header
// foo.h
int global_counter;  // object definition
void helper() { }    // non-inline function

// GOOD: declarations in header, definitions in cpp
// foo.h
extern int global_counter;
void helper();

// BAD: missing include guard
// foo.h
#pragma once  // or #ifndef FOO_H

// GOOD: include guard
#ifndef FOO_H
#define FOO_H
// ...
#endif
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `llvm-include-order` | SF.4 |
| `misc-include-cleaner` | SF.3 |
| `misc-header-include-cycle` | SF.9 |
| `misc-anonymous-namespace-in-header` | SF.6-7 |
| `misc-definitions-in-headers` | SF.2 |
| `readability-duplicate-include` | SF.8 |
| `misc-unused-using-decls` | SF.6 |
| `misc-use-anonymous-namespace` | SF.6 |
| `misc-use-internal-linkage` | SF.6 |
| `modernize-concat-nested-namespaces` | SF.20 |
| `bugprone-std-namespace-modification` | SF.20 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
