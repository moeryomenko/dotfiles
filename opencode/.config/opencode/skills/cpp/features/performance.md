# C++ Performance (Per Section)

Guidelines for performance-conscious design and optimization.

## Optimization Principles

| Guideline | Pitfall |
|-----------|---------|
| Don't optimize without a reason | Premature optimization |
| Don't optimize prematurely | 90% of time in 10% of code |
| Don't optimize non-critical code | Diminishing returns |
| Don't assume complex = fast | O(n) with cheap ops may beat O(log n) with expensive ones |
| Don't assume low-level = fast | Compiler optimizes idiomatic code better |
| Measure, don't guess | Profiler data beats intuition |

## Design for Optimization

| Guideline | Example |
|-----------|---------|
| Rely on static type system | Concrete types enable devirtualization |
| Move computation to compile time | `constexpr` functions, TMP |
| Eliminate redundant aliases | Avoid unnecessary references |
| Eliminate redundant indirection | Prefer value semantics over pointers |
| Minimize allocations | Reuse buffers, pre-allocate |
| Don't allocate on critical path | Memory allocation has high latency |

```cpp
// Static type enables inlining
// Virtual dispatch (cannot inline across call)
struct Shape { virtual double area() const = 0; };

// Concrete type (can inline)
struct Circle {
    double radius;
    double area() const { return radius * radius * 3.14159; }
};

// constexpr moves computation to compile time
constexpr int factorial(int n) {
    int r = 1;
    for (int i = 2; i <= n; ++i) r *= i;
    return r;
}
static_assert(factorial(5) == 120);  // Computed at compile time
```

## Data Layout

| Guideline | Why |
|-----------|-----|
| Use compact data structures | Cache misses cost 100x more than ALU ops |
| Declare most-used member first | Better cache line packing |
| Space is time | Smaller = faster (more data per cache line) |
| Access memory predictably | Sequential access exploits hardware prefetcher |

```cpp
// Layout matters for cache performance

// Hot and cold data interleaved — cache line waste
struct Widget {
    bool is_active;        // Accessed frequently
    std::string name;      // Accessed rarely
    int priority;          // Accessed frequently
    std::string metadata;  // Accessed rarely
};

// Group by access frequency
struct Widget {
    // Hot data (frequently accessed together)
    int priority;
    bool is_active;

    // Cold data (accessed separately)
    std::string name;
    std::string metadata;
};

// Sequential access (prefetcher-friendly)
for (int i = 0; i < N; ++i)
    process(data[i]);

// Random access (cache misses)
for (int i = 0; i < N; ++i)
    process(lookup_table[permutation[i]]);

// Pointer chasing (linked list — cache-inefficient)
for (Node* p = head; p; p = p->next)
    process(p->data);

// Contiguous storage (vector — cache-friendly)
for (const auto& elem : vec)
    process(elem);
```

## Common Performance Patterns

### Buffer Reuse

```cpp
// Repeated allocation in loop
std::string result;
for (const auto& item : items) {
    result += process(item);  // String reallocates each time
}

// Reserve or reuse
std::string result;
result.reserve(estimated_total_size);  // Pre-allocate
for (const auto& item : items) {
    result += process(item);
}
```

### Vector Operations

```cpp
// Repeated push_back without reserve (multiple reallocations)
std::vector<int> v;
for (int i = 0; i < 10000; ++i)
    v.push_back(i);

// Reserve first (no reallocations)
std::vector<int> v;
v.reserve(10000);
for (int i = 0; i < 10000; ++i)
    v.push_back(i);

// emplace with constructor args (constructs in place)
v.emplace_back(args);

// Avoid: temporary + move
v.push_back(Widget(args));
v.emplace_back(Widget(args));  // Temporary + move
```

### Value Semantics

```cpp
// Pointer indirection (cache misses, allocation overhead)
std::vector<std::unique_ptr<Widget>> widgets;

// Value semantics (contiguous, cache-friendly)
std::vector<Widget> widgets;

// When polymorphism is needed, consider:
// - std::variant (if types are known at compile time)
// - Type erasure with small buffer optimization
```

## Anti-Patterns

```cpp
// Unnecessary copy
void process(std::vector<std::string> data);  // Copies entire vector

// Const reference
void process(const std::vector<std::string>& data);

// endl flushes stream (expensive)
std::cout << "line" << std::endl;

// Newline only (buffered write)
std::cout << "line\n";

// Redundant temporary
auto r = a * b;
return r;  // RVO handles this: return a * b;
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `performance-unnecessary-copy-initialization` | Detect unnecessary copies |
| `performance-unnecessary-value-param` | Detect unnecessary value params |
| `performance-for-range-copy` | Detect unnecessary range-for copies |
| `performance-inefficient-algorithm` | Detect inefficient algorithms |
| `performance-inefficient-string-concatenation` | Detect repeated string concat |
| `performance-inefficient-vector-operation` | Detect inefficient vector ops |
| `performance-move-const-arg` | Detect move on const |
| `performance-move-constructor-init` | Detect suboptimal move init |
| `performance-noexcept-move-constructor` | Ensure noexcept on moves |
| `performance-avoid-endl` | Replace endl with \n |
| `performance-trivially-destructible` | Detect non-trivial dtor on small types |
| `performance-implicit-conversion-in-loop` | Detect implicit conversions in loops |
| `modernize-shrink-to-fit` | Use shrink_to_fit |
| `modernize-use-emplace` | Replace push_back with emplace_back |
| `readability-redundant-string-init` | Detect redundant string init |

## Cross-References

- For allocation patterns and smart pointer cost: load `resource-management`
- For performance-cost of virtual functions: load `classes`
- For compile-time computation: load `templates`
- For clang-tidy configuration: load `clang-tidy`
