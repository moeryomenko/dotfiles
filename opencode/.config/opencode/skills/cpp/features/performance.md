# C++ Performance (Per Section)

Guidelines for performance-conscious design and optimization.

## Optimization Principles

| Rule | Guideline | Pitfall |
|------|-----------|---------|
| Per.1 | Don't optimize without a reason | Pre-mature optimization |
| Per.2 | Don't optimize prematurely | 90% of time in 10% of code |
| Per.3 | Don't optimize non-critical code | Diminishing returns |
| Per.4 | Don't assume complex = fast | O(n) with cheap ops may beat O(log n) with expensive ones |
| Per.5 | Don't assume low-level = fast | Compiler optimizes idiomatic code better |
| Per.6 | Measure, don't guess | Profiler data beats intuition |

## Design for Optimization

| Rule | Guideline | Example |
|------|-----------|---------|
| Per.10 | Rely on static type system | Concrete types enable devirtualization |
| Per.11 | Move computation to compile time | `constexpr` functions, TMP |
| Per.12 | Eliminate redundant aliases | Avoid unnecessary references |
| Per.13 | Eliminate redundant indirection | Prefer value semantics over pointers |
| Per.14 | Minimize allocations | Reuse buffers, pre-allocate |
| Per.15 | Don't allocate on critical path | Memory allocation has high latency |

```cpp
// Per.10: static type enables inlining
// BAD: virtual dispatch (cannot inline across call)
struct Shape { virtual double area() const = 0; };

// GOOD: concrete type (can inline)
struct Circle {
    double radius;
    double area() const { return radius * radius * 3.14159; }
};

// Per.11: constexpr moves computation to compile time
// BAD: runtime computation
int factorial(int n) {
    int r = 1;
    for (int i = 2; i <= n; ++i) r *= i;
    return r;
}

// GOOD: compile-time when inputs known
constexpr int factorial(int n) {
    int r = 1;
    for (int i = 2; i <= n; ++i) r *= i;
    return r;
}
static_assert(factorial(5) == 120);  // Computed at compile time
```

## Data Layout

| Rule | Guideline | Why |
|------|-----------|-----|
| Per.16 | Use compact data structures | Cache misses cost 100x more than ALU ops |
| Per.17 | Declare most-used member first | Better cache line packing |
| Per.18 | Space is time | Smaller = faster (more data per cache line) |
| Per.19 | Access memory predictably | Sequential access exploits hardware prefetcher |

```cpp
// Per.16-17: layout matters for cache performance

// BAD: hot and cold data interleaved
struct Widget {
    bool is_active;        // Accessed frequently
    std::string name;      // Accessed rarely
    int priority;          // Accessed frequently
    std::string metadata;  // Accessed rarely
};
// Cache line waste: padding between members, cold data evicts hot data

// GOOD: group by access frequency
struct Widget {
    // Hot data (frequently accessed together)
    int priority;
    bool is_active;
    // Padding here (3 bytes)
    
    // Cold data (accessed separately)
    std::string name;
    std::string metadata;
};

// Per.19: sequential access
// BAD: random access (cache misses)
for (int i = 0; i < N; ++i)
    process(lookup_table[permutation[i]]);

// GOOD: sequential access (prefetcher-friendly)
for (int i = 0; i < N; ++i)
    process(data[i]);

// BAD: pointer chasing (linked list)
for (Node* p = head; p; p = p->next)
    process(p->data);

// GOOD: contiguous storage (vector)
for (const auto& elem : vec)
    process(elem);
```

## Common Performance Patterns

### Buffer Reuse

```cpp
// BAD: repeated allocation in loop
std::string result;
for (const auto& item : items) {
    result += process(item);  // String reallocates each time
}

// GOOD: reserve or reuse
std::string result;
result.reserve(estimated_total_size);  // Pre-allocate
for (const auto& item : items) {
    result += process(item);
}
```

### Vector Operations

```cpp
// BAD: repeated push_back without reserve
std::vector<int> v;
for (int i = 0; i < 10000; ++i)
    v.push_back(i);  // Multiple reallocations

// GOOD: reserve first
std::vector<int> v;
v.reserve(10000);
for (int i = 0; i < 10000; ++i)
    v.push_back(i);  // No reallocations

// BAD: emplace/push_back of temporary
v.push_back(Widget(args));
v.emplace_back(Widget(args));  // Temporary + move

// GOOD: emplace with constructor args
v.emplace_back(args);  // Constructs in place — no copy/move
```

### Value Semantics

```cpp
// BAD: pointer indirection (cache misses, allocation overhead)
std::vector<std::unique_ptr<Widget>> widgets;
// Each Widget is heap-allocated, pointers scattered in memory

// GOOD: value semantics (contiguous, cache-friendly)
std::vector<Widget> widgets;
// Widgets are stored inline in the vector's buffer

// When polymorphism is needed, consider:
// - std::variant (if types are known at compile time)
// - Type erasure with small buffer optimization
```

## Anti-Patterns

```cpp
// BAD: unnecessary copy
void process(std::vector<std::string> data);  // Copies entire vector

// GOOD: const reference
void process(const std::vector<std::string>& data);

// BAD: endl flushes stream (expensive)
std::cout << "line" << std::endl;

// GOOD: newline only (buffered write)
std::cout << "line\n";

// BAD: redundant temporary
auto r = a * b;
return r;
// RVO handles this: return a * b;
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `performance-unnecessary-copy-initialization` | Per.12 |
| `performance-unnecessary-value-param` | F.16 |
| `performance-for-range-copy` | Per.12 |
| `performance-inefficient-algorithm` | Per.7 |
| `performance-inefficient-string-concatenation` | Per.7 |
| `performance-inefficient-vector-operation` | Per.7 |
| `performance-move-const-arg` | F.18 |
| `performance-move-constructor-init` | C.66 |
| `performance-no-automatic-move` | C.66 |
| `performance-noexcept-move-constructor` | C.66 |
| `performance-avoid-endl` | Per.19 |
| `performance-trivially-destructible` | Per.14 |
| `performance-implicit-conversion-in-loop` | Per.12 |
| `modernize-shrink-to-fit` | Per.14 |
| `modernize-use-emplace` | Per.14 |
| `readability-redundant-string-init` | Per.12 |

## Cross-References

- For allocation patterns and smart pointer cost: load `resource-management`
- For performance-cost of virtual functions: load `classes`
- For compile-time computation: load `templates`
- For clang-tidy configuration: load `clang-tidy`
