# C++ Templates (T Section)

Guidelines for template design, concepts, and generic programming.

## Template Purpose

| Rule | Guideline | Example |
|------|-----------|---------|
| T.1 | Raise abstraction level | `sort(Range&)` not `qsort(void*, size_t, size_t, cmp)` |
| T.2 | Express algorithms for many types | Template parameterized on element type |
| T.3 | Express containers and ranges | `vector<T>`, `span<T>` |
| T.4 | Compile-time computation | `constexpr` functions, type traits |

## Concepts (C++20)

| Rule | Guideline | Before | After |
|------|-----------|--------|-------|
| T.10 | Specify concepts for all template args | `template<typename T>` | `template<std::integral T>` |
| T.11 | Use standard concepts when possible | `requires is_integral_v<T>` | `requires std::integral<T>` |
| T.12 | Prefer concept names over `auto` | `auto sort(auto& c)` | `void sort(std::sortable auto& c)` |
| T.41 | Require essential properties only | Over-constrained | Minimal essential requirements |
| T.42 | Use template aliases for brevity | `typename vector<T>::iterator` | `template<typename T> using It = typename vector<T>::iterator` |

```cpp
// BAD: unconstrained template (accepts anything, terrible error messages)
template<typename T>
void sort(T& c);

// GOOD: constrained with concepts (clear requirements, good errors)
template<ranges::sortable_range T>
void sort(T& c);

// BAD: auto parameter without concept
auto find(auto& c, const auto& val);

// GOOD: constrained auto
auto find(ranges::forward_range auto& c, const auto& val);

// BAD: verbose enable_if
template<typename T,
    enable_if_t<is_integral_v<T> && is_signed_v<T>, int> = 0>
T abs(T v);

// GOOD: concept
template<std::signed_integral T>
T abs(T v);
```

### Defining Custom Concepts

```cpp
// Basic concept
template<typename T>
concept Drawable = requires(T obj) {
    { obj.draw() } -> std::same_as<void>;
};

// Compound concept with type constraints
template<typename T>
concept Container = requires(T c) {
    typename T::value_type;
    typename T::iterator;
    { c.begin() } -> std::same_as<typename T::iterator>;
    { c.end() } -> std::same_as<typename T::iterator>;
    { c.size() } -> std::integral;
};

// Using multiple concepts
template<Container Cont, std::copyable T>
    requires std::same_as<typename Cont::value_type, T>
void add_and_process(Cont& container, T value);
```

## Template Design

| Rule | Guideline | Why |
|------|-----------|-----|
| T.47 | Avoid unconstrained templates with common names | Ambiguity, ADL surprises |
| T.60 | Minimize template context dependencies | Less coupling, faster compilation |
| T.61 | Don't over-parameterize members | Makes code harder to read |
| T.62 | Non-dependent members: non-templated base | Reduces instantiation overhead |
| T.68 | Use `{}` not `()` in templates | Avoids most-vexing-parse |
| T.69 | Unqualified calls = customization points | ADL finds user overloads |

```cpp
// T.68: use {} in templates
template<typename T>
void example() {
    // BAD: () is ambiguous — function declaration or construction?
    T x(a, b);  // Could be a function declaration!
    
    // GOOD: {} is always construction
    T x{a, b};  // Always constructs
}

// T.69: customization points via ADL
template<typename T>
void serialize(const T& obj) {
    // BAD: qualified call — no ADL
    std::to_string(obj);
    
    // GOOD: unqualified call — ADL can find user overloads
    using std::to_string;
    to_string(obj);  // ADL + fallback to std
}
```

## Aliases

| Rule | Guideline |
|------|-----------|
| T.42 | Use template aliases to simplify notation |
| T.43 | Prefer `using` over `typedef` |

```cpp
// BAD: typedef with templates
typedef std::vector<int> IntVec;
template<typename T>
typedef std::vector<T> Vec;  // Error: can't template typedef

// GOOD: using alias
using IntVec = std::vector<int>;
template<typename T>
using Vec = std::vector<T>;  // OK: template alias
```

## Specialization

| Rule | Guideline |
|------|-----------|
| T.64 | Specialize class templates for alternate implementations |
| T.65 | Tag dispatch for function alternatives |
| T.144 | Don't specialize function templates (use overloading) |

```cpp
// T.65: Tag dispatch
struct sequential_tag {};
struct parallel_tag {};

template<typename It, typename Cmp>
void sort(It first, It last, Cmp cmp, sequential_tag) {
    // Sequential sort
}

template<typename It, typename Cmp>
void sort(It first, It last, Cmp cmp, parallel_tag) {
    // Parallel sort
}

// User chooses: sort(begin, end, less<>{}, parallel_tag{});
```

## Template Metaprogramming

| Rule | Guideline |
|------|-----------|
| T.120 | Use TMP only when really needed |
| T.121 | Primarily to emulate concepts (pre-C++20) |
| T.123 | Use `constexpr` for compile-time values |
| T.124 | Prefer standard-library TMP |

```cpp
// BAD: manual type traits
template<typename T>
struct is_my_container {
    static constexpr bool value = false;
};

// GOOD: use standard type traits
static_assert(std::is_integral_v<int>);

// BAD: complex TMP for conditional behavior
template<typename T, typename = void>
struct has_size : std::false_type {};
template<typename T>
struct has_size<T, std::void_t<decltype(std::declval<T>().size())>>
    : std::true_type {};

// GOOD: concepts
template<typename T>
concept has_size = requires(T v) { v.size(); };
```

## Anti-Patterns

```cpp
// BAD: unconstrained template with common name
template<typename T>
T add(T a, T b) { return a + b; }  // Accepts unrelated types

// GOOD: constrained
template<std::arithmetic T>
T add(T a, T b) { return a + b; }

// BAD: old-style SFINAE
template<typename T>
enable_if_t<is_container_v<T>, void> process(const T& c);

// GOOD: concepts
template<Container T>
void process(const T& c);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `modernize-use-concepts` | T.10 |
| `modernize-use-constraints` | T.10 |
| `bugprone-incorrect-enable-if` | T.48 |
| `modernize-use-using` | T.43 |
| `modernize-type-traits` | T.124 |
| `modernize-unary-static-assert` | T.150 |
| `misc-static-assert` | T.150 |
| `readability-redundant-qualified-alias` | T.42 |

## Cross-References

- For concepts with functions: load `functions`
- For SFINAE alternatives and modernization: load `modernize`
- For clang-tidy configuration: load `clang-tidy`
