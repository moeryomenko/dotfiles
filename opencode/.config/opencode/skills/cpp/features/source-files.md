# C++ Source Files (SF Section)

Guidelines for file organization, headers, includes, and namespaces.

## File Conventions

| Rule | Guideline | Rationale |
|------|-----------|-----------|
| SF.1 | `.cpp` for code, `.h` for interfaces | Clear separation of declaration/definition |
| SF.2 | Headers: no object or non-inline function definitions | ODR violations if included in multiple TUs |
| SF.3 | Use headers for multi-file declarations | Single point of truth for interfaces |
| SF.4 | Include headers before other declarations | Self-sufficiency validation |
| SF.5 | `.cpp` must include its own header | Compiler verifies header is self-contained |
| SF.6 | No `using namespace` in headers (global scope) | Namespace pollution for all includers |
| SF.7 | No global `using namespace` in header files | SF.6 with stronger emphasis |
| SF.8 | Use `#include` guards for all headers | Prevent multiple inclusion |
| SF.9 | Avoid cyclic dependencies | Circular includes, forward decls needed |
| SF.10 | Don't depend on implicit includes | Always include what you use |
| SF.11 | Headers must be self-contained | Including a header must always compile |
| SF.12 | `""` for local, `<>` for system | Compiler search path distinction |
| SF.13 | Use portable header identifiers | No absolute paths, consistent casing |
| SF.20 | Use namespaces for logical structure | Avoid name collisions |

## Include Order

```cpp
// widget.cpp

// 1. Own header first (SF.5: validates header is self-contained)
#include "widget.h"

// 2. C standard library headers (C++ wrappers)
#include <cassert>
#include <cstring>
#include <cstdint>

// 3. C++ standard library headers
#include <memory>
#include <string>
#include <vector>

// 4. Third-party library headers
#include <boost/algorithm/string.hpp>
#include <fmt/format.h>

// 5. Project headers
#include "core/types.h"
#include "network/connection.h"
#include "utils/logger.h"
```

### Include Your Own Header First

```cpp
// The reason SF.5 matters: it forces header self-sufficiency
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

// Missing: #include <string>
class Widget {
    std::string name_;  // Error: string not defined!
};

#endif

// widget.cpp
#include "widget.h"  // Compile error here, not in user code
// This forces the header author to fix the missing include
```

## Header Guards

```cpp
// BAD: no include guard (ODR violation risk)
// widget.h
class Widget { /* ... */ };

// GOOD: #pragma once (simpler, supported everywhere)
#pragma once
class Widget { /* ... */ };

// GOOD: #ifndef guard (traditional, works with all preprocessors)
#ifndef WIDGET_H
#define WIDGET_H
class Widget { /* ... */ };
#endif
```

## Namespaces

```cpp
// BAD: global using in header (pollutes everyone who includes this)
// foo.h
using namespace std;     // DON'T: every user of foo.h gets std in scope
using namespace mylib;   // DON'T: namespace collision risk

// GOOD: fully qualified or local using
// foo.h
namespace myproject {
    class Foo {
        std::vector<int> data;
    };
}

// BAD: using namespace in namespace scope of header
namespace myproject {
    using namespace std;  // Still pollutes myproject namespace
}

// BAD: using declaration in header
// foo.h
using std::string;  // Pollutes the global namespace of includers

// GOOD: local using in implementation file
// foo.cpp
void myproject::Foo::process() {
    using namespace std;  // Local scope only
    vector<int> v;
    // ...
}

// Good practice: namespace aliases
namespace fs = std::filesystem;  // In .cpp files, not headers
```

## Dependencies

```cpp
// SF.9: avoid cyclic dependencies
// BAD: A.h includes B.h, B.h includes A.h
// A.h
#include "B.h"
class A { B* b; };

// B.h
#include "A.h"
class B { A* a; };

// GOOD: use forward declarations to break cycles
// A.h
class B;  // Forward declaration
class A { B* b; };

// B.h
class A;  // Forward declaration
class B { A* a; };

// SF.10: don't depend on implicit includes
// BAD: using std::vector without including <vector>
// (works if another header happens to include it first — fragile)

// GOOD: always include what you use
#include <vector>

// Use include-what-you-use (IWYU) tool to verify
```

## Anti-Patterns

```cpp
// BAD: definitions in header (ODR violations!)
// utils.h
int global_counter;         // Object definition — multiply defined
void helper() { }          // Non-inline function — multiply defined

// GOOD: declarations in header, definitions in .cpp
// utils.h
extern int global_counter;
void helper();

// utils.cpp
int global_counter = 0;
void helper() { /* ... */ }

// BAD: missing include guard
// widget.h
#pragma once  // OK but only for compilers that support it

// Good practice: combination
// widget.h
#ifndef WIDGET_H
#define WIDGET_H
#pragma once  // Optimization for compilers that support it
// ...
#endif
```

### Include-What-You-Use Integration

Use IWYU to enforce SF.10 and SF.11 automatically:

```bash
# Install
brew install include-what-you-use  # macOS
apt install iwyu                     # Debian/Ubuntu

# Run with CMake
cmake -DCMAKE_CXX_INCLUDE_WHAT_YOU_USE=iwyu ..
make 2> iwyu-report.txt

# Apply suggestions (some are automatic)
iwyu_tool.py -p build -- clang++ -c widget.cpp 2> iwyu-fixes.txt
fix_includes.py < iwyu-fixes.txt
```

Common IWYU patterns:
- Replace transitive includes with direct includes
- Add forward declarations to replace includes where possible
- Remove unused includes (speeds up compilation)

### Module System (C++20)

C++20 modules provide an alternative to the header/source convention:

```cpp
// widget.cppm — module interface
export module widget;

import <string>;
import <vector>;

export class Widget {
    std::string name_;
    std::vector<int> data_;
public:
    Widget(std::string name);
    void process();
};

// widget_impl.cpp — module implementation
module widget;

Widget::Widget(std::string name) : name_(std::move(name)) {}
void Widget::process() { /* ... */ }
```

Modules offer:
- No header guards needed
- No ODR issues from multiple includes
- Faster compilation (no transitive include overhead)
- Explicit export control over API surface

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `llvm-include-order` | SF.4 |
| `misc-include-cleaner` | SF.3 |
| `misc-header-include-cycle` | SF.9 |
| `misc-definitions-in-headers` | SF.2 |
| `readability-duplicate-include` | SF.8 |
| `misc-unused-using-decls` | SF.6 |
| `misc-use-anonymous-namespace` | SF.6/20 |
| `modernize-concat-nested-namespaces` | SF.20 |
| `bugprone-std-namespace-modification` | SF.20 |
| `misc-static-initialization-cycle` | I.22 |

## Cross-References

- For header design and includes with interfaces: load `interfaces`
- For Pimpl pattern: load `resource-management`
- For clang-tidy configuration: load `clang-tidy`
