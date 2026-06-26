# C++ Resource Management (R Section)

Resource management through RAII and smart pointers.

## Core Principle

**Manage resources automatically using RAII.** Every resource acquisition must be immediately wrapped in a handle object whose destructor releases the resource. This applies to memory, file handles, sockets, mutex locks, database connections, and any other resource.

```cpp
// Manual resource management (leak on exception)
void process_file(const char* path) {
    FILE* f = fopen(path, "r");
    // ... might throw, f never closed
    fclose(f);
}

// RAII wrapper
void process_file(const std::string& path) {
    std::ifstream f(path);
    // ... if this throws, ~ifstream() runs automatically
}
```

## Ownership Rules

| Type | Ownership | When to Use |
|------|-----------|-------------|
| `T*` | Non-owning (observer) | Pointing to something that outlives you |
| `T&` | Non-owning (observer) | Like T*, but never null |
| `unique_ptr<T>` | Exclusive ownership | One owner, deterministic destruction |
| `shared_ptr<T>` | Shared ownership | Multiple owners, reference-counted |
| `weak_ptr<T>` | Non-owning, breaks cycles | Observing shared_ptr without ownership |

## Smart Pointer Selection

### Decision Flow

```
Do you need to share ownership?
  +-- Yes -> use shared_ptr
  |   +-- Does shared_ptr create a cycle?
  |       +-- Yes -> use weak_ptr to break it
  +-- No -> use unique_ptr (default choice)
```

### Construction

```cpp
// Naked new
auto p = new Widget();
delete p;

// make_unique
auto p = std::make_unique<Widget>();

// Naked new with shared_ptr (double allocation, leak-unsafe)
auto sp = std::shared_ptr<Widget>(new Widget());

// make_shared (single allocation, exception-safe)
auto sp = std::make_shared<Widget>();
```

### Why make_shared is exception-safe

```cpp
// shared_ptr(new T()) — leak risk
f(std::shared_ptr<Widget>(new Widget), compute_something());
// If compute_something() throws after new Widget, Widget leaks

// make_shared — atomic allocation and construction
f(std::make_shared<Widget>(), compute_something());
```

## Parameter Semantics

| Parameter Type | Meaning |
|---------------|---------|
| `unique_ptr<Widget>` | Function takes ownership |
| `unique_ptr<Widget>&` | Function may reseat |
| `shared_ptr<Widget>` | Function shares ownership |
| `shared_ptr<Widget>&` | Function may reseat |
| `const shared_ptr<Widget>&` | Function may retain reference |
| `Widget*` / `Widget&` | No ownership, general use |

### Guidance for Parameter Selection

```cpp
// Passing unique_ptr when no ownership transfer
void render(std::unique_ptr<Widget> w);  // Implies ownership transfer

// Pass by reference when just observing
void render(const Widget& w);

// Passing shared_ptr when callee never stores it
void process(std::shared_ptr<Widget> sp);  // Reference-counting overhead

// Pass by reference when just borrowing
void process(const Widget& w);
```

## Move Semantics

```cpp
// Copying when source won't be needed
void add_name(std::string name);
add_name(make_name());  // Copy of temporary

// Move from temporary (automatic for temporaries)
void add_name(std::string name);
add_name(make_name());  // Move (temporary is moved into parameter)

// Using std::move on const (copy, not move!)
const std::string label = "error";
void set_log(std::string s);
set_log(std::move(label));  // const: copy, not move!

// std::move on local return (prevents RVO)
std::string make() {
    std::string s = "hello";
    return s;  // RVO applies (don't use std::move here)
}
```

## Anti-Patterns

```cpp
// Raw new/delete
void f() {
    int* p = new int[100];
    // ... risk of leak
    delete[] p;
}

// RAII container
void f() {
    std::vector<int> v(100);
    // Automatic cleanup on scope exit
}

// malloc/free in C++
void* p = malloc(100);
free(p);

// Smart pointer or container
auto p = std::make_unique<std::byte[]>(100);

// shared_ptr to array (wrong deleter — calls delete, not delete[])
std::shared_ptr<int> sp(new int[10]);

// unique_ptr handles arrays correctly
std::unique_ptr<int[]> up(new int[10]);

// Best: use container
std::vector<int> v(10);

// Manual lifecycle with raw pointers (what about copy/move?)
class Container {
    Widget* w_;
public:
    Container() : w_(new Widget()) {}
    ~Container() { delete w_; }
};

// unique_ptr member — Rule of Zero works
class Container {
    std::unique_ptr<Widget> w_;
public:
    // Default copy is deleted, move works
};
```

## Resource Management Patterns

### Pointer to Implementation (Pimpl)

```cpp
// widget.h
class Widget {
    std::unique_ptr<class Impl> pimpl_;
public:
    Widget();
    ~Widget();  // Must be defined in .cpp where Impl is complete
    Widget(Widget&&) noexcept = default;
    Widget& operator=(Widget&&) noexcept = default;
};

// widget.cpp
struct Widget::Impl {
    std::string name;
    int value;
};
Widget::Widget() : pimpl_(std::make_unique<Impl>()) {}
Widget::~Widget() = default;  // Impl is complete here
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-owning-memory` | Detect owning raw pointers |
| `cppcoreguidelines-no-malloc` | Detect malloc/free usage |
| `modernize-make-unique` | Replace new with make_unique |
| `modernize-make-shared` | Replace new with make_shared |
| `modernize-replace-auto-ptr` | Replace auto_ptr with unique_ptr |
| `bugprone-unused-raii` | Detect unused RAII objects |
| `bugprone-unused-local-non-trivial-variable` | Detect unused non-trivial vars |
| `bugprone-shared-ptr-array-mismatch` | Detect shared_ptr to array |
| `bugprone-unique-ptr-array-mismatch` | Detect unique_ptr to array |
| `bugprone-multiple-new-in-one-expression` | Detect leak-unsafe new expressions |
| `readability-redundant-smartptr-get` | Detect redundant .get() calls |
| `misc-uniqueptr-reset-release` | Detect potential leaks in reset/release |

## Cross-References

- For error safety and RAII guarantees: load `error-handling`
- For class design and special members: load `classes`
- For parameter passing with smart pointers: load `functions`
- For clang-tidy configuration: load `clang-tidy`
