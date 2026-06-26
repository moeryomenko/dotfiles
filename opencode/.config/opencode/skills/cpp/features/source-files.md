# C++ Source Files (SF Section)

Guidelines for file organization, headers, includes, and namespaces.

## File Conventions

| Guideline | Rationale |
|-----------|-----------|
| `.cpp` for code, `.h` for interfaces | Clear separation of declaration/definition |
| Headers: no object or non-inline function definitions | ODR violations if included in multiple TUs |
| Use headers for multi-file declarations | Single point of truth for interfaces |
| Include headers before other declarations | Self-sufficiency validation |
| `.cpp` must include its own header | Compiler verifies header is self-contained |
| No `using namespace` in headers (global scope) | Namespace pollution for all includers |
| Use `#include` guards for all headers | Prevent multiple inclusion |
| Avoid cyclic dependencies | Circular includes, forward decls needed |
| Don't depend on implicit includes | Always include what you use |
| Headers must be self-contained | Including a header must always compile |
| `""` for local, `<>` for system | Compiler search path distinction |
| Use namespaces for logical structure | Avoid name collisions |

## Include Order

```cpp
// widget.cpp

// 1. Own header first (validates header is self-contained)
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

Putting the `.cpp`'s own header first catches missing includes immediately:

```cpp
// widget.h — missing #include <string>
class Widget {
    std::string name_;  // Error: string not defined!
};

// widget.cpp
#include "widget.h"  // Compile error here, not in user code
// This forces the header author to fix the missing include
```

## Header Guards

```cpp
// No include guard (ODR violation risk)
class Widget { /* ... */ };

// #pragma once (simpler, supported everywhere)
#pragma once
class Widget { /* ... */ };

// #ifndef guard (traditional, works with all preprocessors)
#ifndef WIDGET_H
#define WIDGET_H
class Widget { /* ... */ };
#endif
```

## Namespaces

```cpp
// Global using in header (pollutes everyone who includes this)
using namespace std;     // DON'T: every user gets std in scope
using namespace mylib;   // DON'T: namespace collision risk

// Fully qualified or local using
namespace myproject {
    class Foo {
        std::vector<int> data;
    };
}

// using declaration in header still pollutes namespace
using std::string;  // Pollutes the global namespace of includers

// Local using in implementation file
void myproject::Foo::process() {
    using namespace std;  // Local scope only
    vector<int> v;
}

// Namespace aliases in .cpp files
namespace fs = std::filesystem;
```

## Dependencies

```cpp
// Cyclic dependencies
// A.h: #include "B.h" -> class B;
// B.h: #include "A.h" -> class A;

// Fix: use forward declarations to break cycles
// A.h
class B;  // Forward declaration
class A { B* b; };

// B.h
class A;  // Forward declaration
class B { A* a; };

// Don't depend on implicit includes
// Always include what you use
#include <vector>  // For std::vector

// Use include-what-you-use (IWYU) tool to verify
```

## Anti-Patterns

```cpp
// Definitions in header (ODR violations!)
// utils.h
int global_counter;         // Object definition — multiply defined
void helper() { }          // Non-inline function — multiply defined

// Declarations in header, definitions in .cpp
// utils.h
extern int global_counter;
void helper();

// utils.cpp
int global_counter = 0;
void helper() { /* ... */ }

// Missing include guard in header
// widget.h — included twice causes compilation error
```

### Include-What-You-Use Integration

Use IWYU to enforce self-contained headers and minimal includes:

```bash
# Install
brew install include-what-you-use  # macOS
apt install iwyu                     # Debian/Ubuntu

# Run with CMake
cmake -DCMAKE_CXX_INCLUDE_WHAT_YOU_USE=iwyu ..
make 2> iwyu-report.txt

# Apply suggestions
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

| Check | Purpose |
|-------|---------|
| `llvm-include-order` | Enforce include order |
| `misc-include-cleaner` | Remove unused includes |
| `misc-header-include-cycle` | Detect include cycles |
| `misc-definitions-in-headers` | Detect definitions in headers |
| `readability-duplicate-include` | Detect duplicate includes |
| `misc-unused-using-decls` | Detect unused using declarations |
| `misc-use-anonymous-namespace` | Prefer anonymous namespace |
| `modernize-concat-nested-namespaces` | Use nested namespace syntax |
| `bugprone-std-namespace-modification` | Detect std namespace modification |
| `misc-static-initialization-cycle` | Detect static init cycles |

## Cross-References

- For header design and includes with interfaces: load `interfaces`
- For Pimpl pattern: load `resource-management`
- For clang-tidy configuration: load `clang-tidy`
