# C++ Templates (T Section)

Guidelines for template design, concepts, and generic programming.

## Template Purpose

| Guideline | Example |
|-----------|---------|
| Raise abstraction level | `sort(Range&)` not `qsort(void*, size_t, size_t, cmp)` |
| Express algorithms for many types | Template parameterized on element type |
| Express containers and ranges | `vector<T>`, `span<T>` |
| Compile-time computation | `constexpr` functions, type traits |

## Concepts (C++20)

| Guideline | Before | After |
|-----------|--------|-------|
| Specify concepts for all template args | `template<typename T>` | `template<std::integral T>` |
| Use standard concepts when possible | `requires is_integral_v<T>` | `requires std::integral<T>` |
| Prefer concept names over `auto` | `auto sort(auto& c)` | `void sort(std::sortable auto& c)` |
| Require essential properties only | Over-constrained | Minimal essential requirements |
| Use template aliases for brevity | `typename vector<T>::iterator` | `template<typename T> using It = ...` |

```cpp
// Unconstrained template (accepts anything, terrible error messages)
template<typename T>
void sort(T& c);

// Constrained with concepts (clear requirements, good errors)
template<ranges::sortable_range T>
void sort(T& c);

// Auto parameter without concept
auto find(auto& c, const auto& val);

// Constrained auto
auto find(ranges::forward_range auto& c, const auto& val);

// Verbose enable_if
template<typename T,
    enable_if_t<is_integral_v<T> && is_signed_v<T>, int> = 0>
T abs(T v);

// Concept
template<std::signed_integral T>
T abs(T v);
```

### Defining Custom Concepts

```cpp
template<typename T>
concept Drawable = requires(T obj) {
    { obj.draw() } -> std::same_as<void>;
};

template<typename T>
concept Container = requires(T c) {
    typename T::value_type;
    typename T::iterator;
    { c.begin() } -> std::same_as<typename T::iterator>;
    { c.end() } -> std::same_as<typename T::iterator>;
    { c.size() } -> std::integral;
};

template<Container Cont, std::copyable T>
    requires std::same_as<typename Cont::value_type, T>
void add_and_process(Cont& container, T value);
```

## Template Design

| Guideline | Why |
|-----------|-----|
| Avoid unconstrained templates with common names | Ambiguity, ADL surprises |
| Minimize template context dependencies | Less coupling, faster compilation |
| Don't over-parameterize members | Makes code harder to read |
| Non-dependent members: non-templated base | Reduces instantiation overhead |
| Use `{}` not `()` in templates | Avoids most-vexing-parse |
| Unqualified calls = customization points | ADL finds user overloads |

```cpp
// Use {} in templates
template<typename T>
void example() {
    T x(a, b);     // Could be a function declaration!
    T x{a, b};     // Always constructs
}

// Customization points via ADL
template<typename T>
void serialize(const T& obj) {
    using std::to_string;
    to_string(obj);  // ADL + fallback to std
}
```

## Aliases

| Guideline | Why |
|-----------|-----|
| Use template aliases to simplify notation | Reduces verbosity |
| Prefer `using` over `typedef` | Works with templates, clearer syntax |

```cpp
using IntVec = std::vector<int>;
template<typename T>
using Vec = std::vector<T>;  // Template alias works
```

## Specialization

| Guideline | Strategy |
|-----------|----------|
| Specialize class templates for alternate implementations | Platform-specific code |
| Tag dispatch for function alternatives | Compile-time algorithm selection |
| Don't specialize function templates | Use overloading instead |

```cpp
// Tag dispatch
struct sequential_tag {};
struct parallel_tag {};

template<typename It, typename Cmp>
void sort(It first, It last, Cmp cmp, sequential_tag) { /* seq */ }

template<typename It, typename Cmp>
void sort(It first, It last, Cmp cmp, parallel_tag) { /* par */ }
```

## Template Metaprogramming

| Guideline | Why |
|-----------|-----|
| Use TMP only when really needed | Compile-time cost, complexity |
| Prefer `constexpr` for compile-time values | Simpler, more readable |
| Prefer standard-library TMP | Well-tested, idiomatic |
| Use concepts instead of SFINAE (C++20) | Clearer errors, faster compile |

```cpp
// Complex TMP for conditional behavior
template<typename T, typename = void>
struct has_size : std::false_type {};
template<typename T>
struct has_size<T, std::void_t<decltype(std::declval<T>().size())>>
    : std::true_type {};

// Concepts (simpler)
template<typename T>
concept has_size = requires(T v) { v.size(); };
```

## Anti-Patterns

```cpp
// Unconstrained template with common name
template<typename T>
T add(T a, T b) { return a + b; }  // Accepts unrelated types

// Constrained
template<std::arithmetic T>
T add(T a, T b) { return a + b; }

// Old-style SFINAE
template<typename T>
enable_if_t<is_container_v<T>, void> process(const T& c);

// Concepts
template<Container T>
void process(const T& c);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `modernize-use-concepts` | Replace SFINAE with concepts |
| `modernize-use-constraints` | Replace enable_if with requires |
| `bugprone-incorrect-enable-if` | Detect broken enable_if |
| `modernize-use-using` | Replace typedef with using |
| `modernize-type-traits` | Replace old type traits |
| `modernize-unary-static-assert` | Use single-arg static_assert |
| `misc-static-assert` | Replace runtime assert with static_assert |
| `readability-redundant-qualified-alias` | Detect redundant qualifiers |

## Cross-References

- For concepts with functions: load `functions`
- For SFINAE alternatives and modernization: load `modernize`
- For clang-tidy configuration: load `clang-tidy`
