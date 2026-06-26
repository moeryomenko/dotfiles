# C++ Constants and Immutability (Con Section)

Guidelines for `const` correctness and compile-time computation.

## Rules

| Guideline | Example |
|-----------|---------|
| By default, make objects immutable | `const string name` not `string name` |
| By default, make member functions `const` | `int get() const` not `int get()` |
| By default, pass pointers/references to `const` | `const Widget&` not `Widget&` |
| Use `const` for values that don't change | After construction, prefer const members |
| Use `constexpr` for compile-time values | Known at compile time = `constexpr` |

## Const Correctness

```cpp
// Prefer const by default
std::string name;        // Mutable default
const std::string name;  // Immutable

void update() const;  // Member function doesn't modify state

// const& for parameters — write intent clearly
void print(std::string& s);          // Non-const implies modification
void print(const std::string& s);    // Read-only — accepts temporaries too
```

### Member Function Const Correctness

```cpp
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
const int* p;        // Pointer to const int (p can change, *p can't)
int const* p;        // Same: pointer to const int
int* const p = &x;   // Const pointer to int (p can't change, *p can)
const int* const p = &x;  // Const pointer to const int

// Non-const getter exposes internals
class Person {
    std::string name_;
public:
    std::string& name() { return name_; }  // Exposes internals
};

// Const getter + explicit mutation
class Person {
    std::string name_;
public:
    const std::string& name() const { return name_; }
    void set_name(std::string n) { name_ = std::move(n); }
};
```

## Constexpr

```cpp
// Runtime constant (could be modified)
int buffer_size = 1024;

// Compile-time constant
constexpr int BufferSize = 1024;
constexpr std::string_view Greeting = "Hello";

// Runtime function for simple computation
int square(int x) { return x * x; }

// constexpr function — evaluated at compile time when possible
constexpr int square(int x) { return x * x; }
constexpr int cx = square(5);  // Compile-time: cx == 25

// consteval: MUST evaluate at compile time
consteval int compile_time_square(int x) {
    return x * x;
}

// constexpr variables are implicitly const
constexpr int max_value = 100;  // const + constinit

// Declaring constexpr without compile-time evaluable init
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
// Dynamic initialization with static storage (order undefined)
std::vector<int> global_data = {1, 2, 3};  // Static init order fiasco risk

// constinit ensures compile-time initialization
constinit std::vector<int> global_data{1, 2, 3};

// constinit with mutable global state
class Logger { public: void log(std::string_view msg); };
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

constexpr auto make_circle() {
    Circle c{5.0};
    const Shape& s = c;
    return s.area();  // Virtual dispatch at compile time
}
static_assert(make_circle() > 0);
```

### Constexpr vs Constinit

```cpp
// constexpr: must be known at compile time, automatically const
constexpr int a = 42;  // OK, immutable

// constinit: initialized at compile time but can be modified
constinit int b = 42;  // OK
b = 43;  // OK: not const

// constinit ensures no dynamic initialization order issues
constinit std::atomic<int> counter{0};  // Safe: no static init order fiasco
```

## Anti-Patterns

```cpp
// Const in wrong position
const std::string* p;
p = &other;  // OK (non-const pointer to const string)
// But p can point to different objects — const on the wrong thing

// Good: member const for invariant
class Config {
    const int max_connections_;  // Invariant: never changes
    int current_connections_;    // Mutable state
public:
    Config(int max) : max_connections_(max) {}
    bool add_connection() {
        if (current_connections_ >= max_connections_) return false;
        ++current_connections_;
        return true;
    }
};

// Non-const reference param when function doesn't modify
void process(std::string& data);  // Caller expects data might change

// const reference when read-only
void process(const std::string& data);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `misc-const-correctness` | Add missing const |
| `readability-make-member-function-const` | Detect non-const functions that should be const |
| `readability-const-return-type` | Detect const return types |
| `misc-misplaced-const` | Detect misplaced const |

## Cross-References

- For const return types: load `functions`
- For const interfaces: load `interfaces`
- For constexpr in templates: load `templates`
- For clang-tidy configuration: load `clang-tidy`
