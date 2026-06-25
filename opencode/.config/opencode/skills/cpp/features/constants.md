# C++ Constants and Immutability (Con Section)

Guidelines for `const` correctness and compile-time computation.

## Rules

| Rule | Guideline | Example |
|------|-----------|---------|
| Con.1 | By default, make objects immutable | `const string name` not `string name` |
| Con.2 | By default, make member functions `const` | `int get() const` not `int get()` |
| Con.3 | By default, pass pointers/references to `const` | `const Widget&` not `Widget&` |
| Con.4 | Use `const` for values that don't change | After construction, prefer const members |
| Con.5 | Use `constexpr` for compile-time values | Known at compile time = `constexpr` |

## Const Correctness

```cpp
// Con.1: prefer const by default
// BAD: mutable default
std::string name;
void update();

// GOOD: const by default, relax only when needed
const std::string name;
void update() const;  // Member function doesn't modify state

// Con.3: prefer const& for parameters
// BAD: non-const parameter (implies modification, may prevent moves)
void print(std::string& s);  // Caller can't pass temporaries

// GOOD: const reference (read-only, accepts both lvalues and rvalues)
void print(const std::string& s);
```

### Member Function Const Correctness

```cpp
class Widget {
    mutable std::mutex cache_mutex_;
    mutable std::optional<ExpensiveData> cached_;
public:
    // Con.2: getter should be const
    ExpensiveData compute() const {
        // BAD: this modifies state but is not const
        if (!cached_) {
            cached_ = do_compute();  // Error: can't modify in const
        }
        return *cached_;
    }
};

// Solution: mutable for caching (logical const vs bitwise const)
class Widget {
    mutable std::mutex cache_mutex_;
    mutable std::optional<ExpensiveData> cached_;
public:
    ExpensiveData compute() const {
        std::lock_guard lk{cache_mutex_};
        if (!cached_) {
            cached_ = do_compute();  // OK: mutable member
        }
        return *cached_;
    }
};
```

### Const in the Right Place

```cpp
// BAD: wrong const position
const int* p;        // Pointer to const int (p can change, *p can't)
int const* p;        // Same: pointer to const int

// GOOD: const pointer
int* const p = &x;   // Const pointer to int (p can't change, *p can)
const int* const p = &x;  // Const pointer to const int

// BAD: non-const getter (force caller to modify through public interface)
class Person {
    std::string name_;
public:
    std::string& name() { return name_; }  // Exposes internals
};

// GOOD: const getter + explicit mutation
class Person {
    std::string name_;
public:
    const std::string& name() const { return name_; }
    void set_name(std::string n) { name_ = std::move(n); }
};
```

## Constexpr

```cpp
// Con.5: constexpr for compile-time values
// BAD: runtime constant
int buffer_size = 1024;  // Could be modified

// GOOD: compile-time constant
constexpr int BufferSize = 1024;
// Or for strings:
constexpr std::string_view Greeting = "Hello";

// BAD: runtime function for simple computation
int square(int x) { return x * x; }
int x = square(5);  // Computed at runtime

// GOOD: constexpr function — evaluation at compile time when possible
constexpr int square(int x) { return x * x; }
int x = square(5);           // Runtime (if x is runtime)
constexpr int cx = square(5);  // Compile-time: cx == 25

// consteval: constexpr that MUST evaluate at compile time
consteval int compile_time_square(int x) {
    return x * x;
}
int y = compile_time_square(5);   // OK
// int z = compile_time_square(runtime_val);  // Error
```

### Constexpr Functions vs Inline

```cpp
// constexpr implies inline for functions
constexpr int square(int x) { return x * x; }
// Equivalent to: inline constexpr int square(int x) { return x * x; }

// constexpr variables are implicitly const and must be initialized
constexpr int max_value = 100;  // const + constinit

// BAD: declaring constexpr without compile-time evaluable init
constexpr int runtime_val = get_value();  // Error if not constexpr
```

### When to Use Each

| Keyword | Storage | Evaluation | Mutability | Use Case |
|---------|---------|------------|------------|----------|
| `const` | Static or dynamic | Runtime | Immutable | API contracts, read-only references |
| `constexpr` | Static | Compile-time (if inputs are const) | Immutable | Compile-time constants, array sizes |
| `consteval` | Static | Always compile-time | Immutable | Must-run-at-compile-time validation |
| `constinit` | Static | Compile-time init | Mutable | Global objects (safe init ordering) |

### Constinit for Global Safety

```cpp
// BAD: dynamic initialization with static storage
// Order of initialization across translation units is undefined
std::vector<int> global_data = {1, 2, 3};  // Static init order fiasco risk

// GOOD: constinit ensures compile-time initialization
constinit std::vector<int> global_data{1, 2, 3};
// Compiler error if initializer is not a constant expression

// constinit with mutable global state
class Logger {
public:
    void log(std::string_view msg);
};
constinit Logger global_logger;  // Never uninitialized

// constinit requires TRIVIAL destructor
constinit int counter = 0;  // OK: int has trivial destructor
// constinit std::string name = "hello";  // Error: non-trivial destructor
```

### Constexpr Virtual Functions (C++20)

```cpp
struct Shape {
    constexpr virtual double area() const = 0;
    constexpr virtual ~Shape() = default;
};

struct Circle : Shape {
    double radius;
    constexpr Circle(double r) : radius(r) {}
    constexpr double area() const override {
        return radius * radius * 3.141592653589793;
    }
};

// Create and use at compile time
constexpr auto make_circle() {
    Circle c{5.0};
    const Shape& s = c;
    return s.area();  // Virtual dispatch at compile time
}
static_assert(make_circle() > 0);  // All evaluated at compile time
```

### Constexpr vs Constinit

```cpp
// constexpr: must be known at compile time, automatically const
constexpr int a = 42;  // OK

// constinit: initialized at compile time but can be modified
constinit int b = 42;  // OK
// b = 43;  // OK: not const

// constinit ensures no dynamic initialization order issues
constinit std::atomic<int> counter{0};  // Safe: no static init order fiasco
```

## Anti-Patterns

```cpp
// BAD: const in wrong position
const std::string* p;
// p is a non-const pointer to a const string
p = &other;  // OK
// p->clear();  // Error (good)
// But p can point to different objects — the const is on the wrong thing

// GOOD: const where it matters
class Config {
    const int max_connections_;  // Invariant: never changes after construction
    int current_connections_;    // Mutable state
public:
    Config(int max) : max_connections_(max) {}
    
    bool add_connection() {
        if (current_connections_ >= max_connections_) return false;
        ++current_connections_;
        return true;
    }
};

// BAD: non-const reference parameter when function doesn't modify
void process(std::string& data);  // Caller expects data might change

// GOOD: const reference when read-only
void process(const std::string& data);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `misc-const-correctness` | Con.1-3 |
| `readability-make-member-function-const` | Con.2 |
| `readability-const-return-type` | F.49 |
| `misc-misplaced-const` | Con.1 |

## Cross-References

- For const return types: load `functions`
- For const interfaces: load `interfaces`
- For constexpr in templates: load `templates`
- For clang-tidy configuration: load `clang-tidy`
