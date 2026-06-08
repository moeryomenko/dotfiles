---
name: cpp-performance
description: C++ Core Guidelines Per section: Performance. Use when optimizing C++ code, designing for performance, analyzing memory layout, or configuring clang-tidy for performance checks.
---

# C++ Performance (Per Section)

Guidelines for performance-conscious design and optimization.

## Optimization Principles

- **Don't optimize without reason** (Per.1)
- **Don't optimize prematurely** (Per.2)
- **Don't optimize non-critical code** (Per.3)
- **Don't assume complex = fast** (Per.4)
- **Don't assume low-level = fast** (Per.5)
- **Measure, don't guess** (Per.6)

## Design for Optimization (Per.7)

- **Rely on static type system** (Per.10): types enable optimization
- **Move computation to compile time** (Per.11): `constexpr`, TMP
- **Eliminate redundant aliases** (Per.12): avoid unnecessary references
- **Eliminate redundant indirection** (Per.13): prefer value semantics
- **Minimize allocations** (Per.14): reuse, pre-allocate
- **Don't allocate on critical path** (Per.15)

## Data Layout

- **Use compact data structures** (Per.16)
- **Declare most-used member first** (Per.17): improves cache locality
- **Space is time** (Per.18): smaller = faster (cache)
- **Access memory predictably** (Per.19): sequential access

## Anti-Patterns

```cpp
// BAD: unnecessary copy
void f(vector<string> v);  // copies entire vector

// GOOD: const reference
void f(const vector<string>& v);

// BAD: endl flushes stream
cout << "line" << endl;

// GOOD: newline only
cout << "line\n";

// BAD: repeated allocation in loop
for (auto& x : items) {
    string s;
    s += process(x);
}

// GOOD: reserve or reuse
string s;
s.reserve(estimated_size);
for (auto& x : items) {
    s += process(x);
}

// BAD: pointer indirection
vector<unique_ptr<Widget>> v;

// GOOD: value semantics
vector<Widget> v;
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
| `performance-noexcept-swap` | C.85 |
| `performance-avoid-endl` | Per.19 |
| `performance-prefer-single-char-overloads` | Per.7 |
| `performance-string-view-conversions` | Per.7 |
| `performance-trivially-destructible` | Per.14 |
| `performance-type-promotion-in-math-fn` | ES.46 |
| `performance-use-std-move` | C.64 |
| `performance-enum-size` | Per.16 |
| `performance-implicit-conversion-in-loop` | Per.12 |
| `modernize-shrink-to-fit` | Per.14 |
| `modernize-use-emplace` | Per.14 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
