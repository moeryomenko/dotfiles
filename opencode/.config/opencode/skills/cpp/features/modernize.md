# C++ Modernization

Patterns for upgrading legacy C++98/03 code to C++11/14/17/20, replacing C-style patterns, and running clang-tidy modernize checks.

## C++11 Essentials

| Legacy | Modern | Clang-Tidy Check | Safety |
|--------|--------|------------------|--------|
| `NULL` / `0` | `nullptr` | `modernize-use-nullptr` | Safe |
| `auto_ptr` | `unique_ptr` | `modernize-replace-auto-ptr` | Check ownership |
| `new T()` | `make_unique<T>()` | `modernize-make-unique` | Safe |
| `shared_ptr<T>(new T())` | `make_shared<T>()` | `modernize-make-shared` | Safe (exception-safe) |
| C-style cast | `static_cast` etc. | `modernize-avoid-c-style-cast` | Manual review |
| `typedef` | `using` | `modernize-use-using` | Safe |
| `#define CONST 1` | `enum class` / `constexpr` | `modernize-macro-to-enum` | Safe |
| `throw()` | `noexcept` | `modernize-use-noexcept` | Check logic |

### Make_Shared Exception Safety

```cpp
// Leak if other allocation throws
shared_ptr<Widget> sp(new Widget(compute_a(), compute_b()));
// If compute_b() throws after new Widget, the Widget leaks

// make_shared is atomic
auto sp = make_shared<Widget>(compute_a(), compute_b());
```

## C++14/17

| Legacy | Modern | Clang-Tidy Check | Safety |
|--------|--------|------------------|--------|
| `std::bind` + placeholders | lambda | `modernize-avoid-bind` | Safe |
| `random_shuffle` | `shuffle` + engine | `modernize-replace-random-shuffle` | Safe |
| DISALLOW_COPY_AND_ASSIGN | `= delete` | `modernize-use-equals-delete` | Safe |
| manual default | `= default` | `modernize-use-equals-default` | Safe |
| `lock_guard` on one mutex | `scoped_lock` for multiple | `modernize-use-scoped-lock` | Safe |
| `typedef` | `using` | `modernize-use-using` | Safe |
| `std::result_of` | `std::invoke_result` | `modernize-type-traits` | Safe |

### Scoped Lock Example

```cpp
// Separate lock_guard calls (deadlock risk)
void transfer(Account& a, Account& b, int amount) {
    lock_guard<mutex> lk1(a.mtx);
    lock_guard<mutex> lk2(b.mtx);
}

// scoped_lock uses deadlock-avoidance algorithm
void transfer(Account& a, Account& b, int amount) {
    scoped_lock lk(a.mtx, b.mtx);
}
```

## C++20

| Legacy | Modern | Clang-Tidy Check | Safety |
|--------|--------|------------------|--------|
| `enable_if` SFINAE | concepts | `modernize-use-concepts` | Manual |
| `auto` without type | constrained concepts | `modernize-use-constraints` | Manual |
| C arrays | `std::array` | `modernize-avoid-c-arrays` | Safe |
| `setjmp`/`longjmp` | exceptions | `modernize-avoid-setjmp-longjmp` | Manual |

### Concepts vs SFINAE

```cpp
// SFINAE-based constraint (hard to read, slow to compile)
template<typename T,
    enable_if_t<is_integral_v<T> && is_signed_v<T>, int> = 0>
T abs(T v) { return v < 0 ? -v : v; }

// Concept-based constraint (clear, fast compilation)
template<std::signed_integral T>
T abs(T v) { return v < 0 ? -v : v; }
```

## Loop Modernization

```cpp
// Index loop (error-prone, verbose)
for (int i = 0; i < static_cast<int>(v.size()); ++i) {
    use(v[i]);
}

// Range-for (clear, no index bugs)
for (const auto& x : v) {
    use(x);
}

// Algorithm (functional style)
for_each(begin(v), end(v), [](const auto& x) { use(x); });

// Manual find
auto it = v.begin();
for (; it != v.end(); ++it) {
    if (*it == target) break;
}
if (it != v.end()) process(it);

// Standard algorithm
auto it = find(begin(v), end(v), target);
if (it != end(v)) process(it);
```

## Function Modernization

```cpp
// C-style cast, no type safety
int x = (int)f;
const char* msg = (const char*)buffer;

// Named cast, compiler-verified
int x = static_cast<int>(f);
const char* msg = static_cast<const char*>(buffer);
```

## Override and Final

```cpp
// No override specifier (silent bug if base changes)
class Derived : Base {
    void foo() { }  // Might not override — no compiler error
};

// Explicit override (compiler verifies)
class Derived : Base {
    void foo() override { }  // Compiler error if base doesn't have virtual foo()
};
```

## Workflow

1. **Run clang-tidy --fix** with `modernize-*` checks to automate 80% of migrations
2. **Review auto-fixes** — most are safe, but some need manual validation:
   - `modernize-use-auto`: can make code less readable
   - `modernize-use-trailing-return-type`: style preference
   - `modernize-use-concepts`: requires C++20, check project standard
3. **Compile and run tests** after each batch of fixes
4. **Iterate** on remaining issues — some need deeper refactoring

## Prefer C++ to C (CPL Section)

| Guideline | Action |
|-----------|--------|
| Prefer C++ to C | Use C++ standard library, not C stdlib |
| If C needed, use common subset compiled as C++ | extern "C" for linkage, C++ semantics internally |
| If C interfaces needed, use C++ in calling code | Wrap C APIs in C++ RAII classes |

### C to C++ Migration Patterns

```cpp
// C pattern
#define BUFFER_SIZE 1024
struct Buffer {
    char* data;
    size_t size;
};
struct Buffer* buffer_alloc(size_t size);
void buffer_free(struct Buffer* buf);

// C++ equivalent
constexpr size_t BUFFER_SIZE = 1024;
class Buffer {
    std::vector<char> data_;
public:
    explicit Buffer(size_t size) : data_(size) {}
    // RAII: destructor handles cleanup automatically
};
```

## References

- Clang-tidy modernize checks: `clang-tidy --list-checks | grep modernize`
- For checker configuration and suppression: load `clang-tidy`
- For performance implications of modernization: load `performance`
