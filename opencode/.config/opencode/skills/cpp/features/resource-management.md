# C++ Resource Management (R Section)

Resource management through RAII and smart pointers.

## Core Principle

**Manage resources automatically using RAII** (R.1). Every resource acquisition must be immediately wrapped in a handle object whose destructor releases the resource. This applies to memory, file handles, sockets, mutex locks, database connections, and any other resource.

```cpp
// BAD: manual resource management (leak on exception)
void process_file(const char* path) {
    FILE* f = fopen(path, "r");
    // ... might throw, f never closed
    fclose(f);
}

// GOOD: RAII wrapper
void process_file(const std::string& path) {
    std::ifstream f(path);
    // ... if this throws, ~ifstream() runs automatically
}
// f is closed when it goes out of scope
```

## Ownership Rules

| Type | Ownership | Rule | When to Use |
|------|-----------|------|-------------|
| `T*` | Non-owning (observer) | R.3 | Pointing to something that outlives you |
| `T&` | Non-owning (observer) | R.4 | Like T*, but never null |
| `unique_ptr<T>` | Exclusive ownership | R.20, R.21 | One owner, deterministic destruction |
| `shared_ptr<T>` | Shared ownership | R.20 | Multiple owners, reference-counted |
| `weak_ptr<T>` | Non-owning, breaks cycles | R.24 | Observing shared_ptr without ownership |

## Smart Pointer Selection

### Decision Flow

```
Do you need to share ownership?
  ├── Yes → use shared_ptr
  │   └── Does shared_ptr create a cycle?
  │       └── Yes → use weak_ptr to break it
  └── No → use unique_ptr (default choice)
```

### Construction

```cpp
// BAD: naked new
auto p = new Widget();
delete p;

// GOOD: make_unique
auto p = std::make_unique<Widget>();     // R.23

// BAD: naked new with shared_ptr (double allocation, leak-unsafe)
auto sp = std::shared_ptr<Widget>(new Widget());

// GOOD: make_shared (single allocation, exception-safe)
auto sp = std::make_shared<Widget>();    // R.22
```

### Why make_shared is exception-safe

```cpp
// BAD: shared_ptr(new T()) — leak risk
f(std::shared_ptr<Widget>(new Widget), compute_something());
// If compute_something() throws after new Widget, Widget leaks
// (allocation order: new Widget, compute_something(), shared_ptr ctor)

// GOOD: make_shared — atomic allocation and construction
f(std::make_shared<Widget>(), compute_something());
// No leak: Widget is constructed inside shared_ptr
```

## Parameter Semantics

| Parameter Type | Meaning | Rule |
|---------------|---------|------|
| `unique_ptr<Widget>` | Function takes ownership | R.32 |
| `unique_ptr<Widget>&` | Function may reseat | R.33 |
| `shared_ptr<Widget>` | Function shares ownership | R.34 |
| `shared_ptr<Widget>&` | Function may reseat | R.35 |
| `const shared_ptr<Widget>&` | Function may retain reference | R.36 |
| `Widget*` / `Widget&` | No ownership, general use | R.2, F.7 |

### Guidance for Parameter Selection

```cpp
// BAD: passing unique_ptr when no ownership transfer
void render(std::unique_ptr<Widget> w);  // Implies ownership transfer

// GOOD: pass by reference when just observing
void render(const Widget& w);

// BAD: passing shared_ptr when callee never stores it
void process(std::shared_ptr<Widget> sp);  // Reference-counting overhead

// GOOD: pass by reference when just borrowing
void process(const Widget& w);
```

## Move Semantics

```cpp
// BAD: copying when source won't be needed
void add_name(std::string name);
add_name(make_name());  // Copy of temporary

// GOOD: move from temporary
void add_name(std::string name);
add_name(make_name());  // Move (temporary is moved into parameter)

// BAD: using std::move on const
const std::string label = "error";
void set_log(std::string s);
set_log(std::move(label));  // const: copy, not move!

// BAD: std::move on local return (prevents RVO)
std::string make() {
    std::string s = "hello";
    return s;  // RVO applies (don't use std::move here)
}
```

## Anti-Patterns

```cpp
// BAD: raw new/delete
void f() {
    int* p = new int[100];
    // ... risk of leak
    delete[] p;
}

// GOOD: RAII container
void f() {
    std::vector<int> v(100);
    // Automatic cleanup on scope exit
}

// BAD: malloc/free in C++
void* p = malloc(100);
free(p);

// GOOD: smart pointer or container
auto p = std::make_unique<std::byte[]>(100);

// BAD: shared_ptr to array (wrong deleter)
std::shared_ptr<int> sp(new int[10]);  // Calls delete, not delete[]

// GOOD: unique_ptr handles arrays correctly
std::unique_ptr<int[]> up(new int[10]);

// BEST: use container
std::vector<int> v(10);

// BAD: manual lifecycle with raw pointers
class Container {
    Widget* w_;
public:
    Container() : w_(new Widget()) {}
    ~Container() { delete w_; }  // What about copy/move?
};

// GOOD: unique_ptr member
class Container {
    std::unique_ptr<Widget> w_;
public:
    // Rule of Zero: default copy is deleted, move works
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

| Check | Rule |
|-------|------|
| `cppcoreguidelines-owning-memory` | R.20, R.3 |
| `cppcoreguidelines-no-malloc` | R.10 |
| `modernize-make-unique` | R.23 |
| `modernize-make-shared` | R.22 |
| `modernize-replace-auto-ptr` | R.20 |
| `bugprone-unused-raii` | R.1 |
| `bugprone-unused-local-non-trivial-variable` | R.1 |
| `bugprone-shared-ptr-array-mismatch` | R.20 |
| `bugprone-unique-ptr-array-mismatch` | R.20 |
| `bugprone-multiple-new-in-one-expression` | R.13 |
| `readability-redundant-smartptr-get` | R.20 |
| `misc-uniqueptr-reset-release` | R.20 |

## Cross-References

- For error safety and RAII guarantees: load `error-handling`
- For class design and special members: load `classes`
- For parameter passing with smart pointers: load `functions`
- For clang-tidy configuration: load `clang-tidy`
