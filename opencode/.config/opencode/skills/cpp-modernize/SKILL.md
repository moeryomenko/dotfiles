---
name: cpp-modernize
description: C++ modernization patterns. Use when upgrading legacy C++98/03 code to C++11/14/17/20, replacing C-style patterns, or running clang-tidy modernize checks.
---

# C++ Modernization

Patterns for upgrading legacy code to modern C++.

## C++11 Essentials

| Legacy | Modern | Check |
|--------|--------|-------|
| `NULL` / `0` | `nullptr` | `modernize-use-nullptr` |
| `auto_ptr` | `unique_ptr` | `modernize-replace-auto-ptr` |
| `new T()` | `make_unique<T>()` | `modernize-make-unique` |
| `shared_ptr<T>(new T())` | `make_shared<T>()` | `modernize-make-shared` |
| C-style cast | `static_cast`, etc. | `modernize-avoid-c-style-cast` |
| `typedef` | `using` | `modernize-use-using` |
| `#define CONST 1` | `enum class` | `modernize-macro-to-enum` |

## C++14/17

| Legacy | Modern | Check |
|--------|--------|-------|
| `std::bind` + `placeholder` | lambda | `modernize-avoid-bind` |
| `random_shuffle` | `shuffle` + engine | `modernize-replace-random-shuffle` |
| DISALLOW_COPY_AND_ASSIGN | `= delete` | `modernize-use-equals-delete` |
| manual default | `= default` | `modernize-use-equals-default` |

## C++20

| Legacy | Modern | Check |
|--------|--------|-------|
| `enable_if` SFINAE | concepts | `modernize-use-concepts` |
| `auto` without type | constrained concepts | `modernize-use-constraints` |
| C arrays | `std::array` | `modernize-avoid-c-arrays` |
| `setjmp`/`longjmp` | exceptions | `modernize-avoid-setjmp-longjmp` |

## Loop Modernization

```cpp
// BAD: index loop
for (int i = 0; i < v.size(); ++i) {
    use(v[i]);
}

// GOOD: range-for
for (const auto& x : v) {
    use(x);
}

// GOOD: algorithm
for_each(begin(v), end(v), [](const auto& x) { use(x); });
```

## Function Modernization

```cpp
// BAD: C-style cast
int x = (int)f;

// GOOD: named cast
int x = static_cast<int>(f);

// BAD: varargs
void log(const char* fmt, ...);

// GOOD: variadic templates
template<typename... Args>
void log(format_string<Args...> fmt, Args&&... args);
```

## Override and Final

```cpp
// BAD: no override specifier
class Derived : Base {
    void foo() { }  // might not override
};

// GOOD: explicit override
class Derived : Base {
    void foo() override { }  // compiler verifies
};
```

## Key Clang-Tidy Checks (modernize-*)

Enable all `modernize-*` checks for comprehensive modernization:

```yaml
Checks: '-*,modernize-*'
```

Common exclusions (taste-dependent):
- `modernize-use-auto` -- explicit types can be clearer
- `modernize-use-trailing-return-type` -- not always needed
- `modernize-use-concepts` -- requires C++20

## Workflow

1. Run `clang-tidy --fix` with `modernize-*` checks
2. Review auto-fixes (most are safe)
3. Compile and run tests
4. Iterate on remaining issues

## CPL: Prefer C++ to C

| Rule | Guideline |
|------|-----------|
| CPL.1 | Prefer C++ to C |
| CPL.2 | If C is needed, use common subset, compile as C++ |
| CPL.3 | If C interfaces, use C++ in calling code |
