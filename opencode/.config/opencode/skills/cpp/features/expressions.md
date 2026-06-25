# C++ Expressions and Statements (ES Section)

Guidelines for initialization, casts, control flow, arithmetic, and macros.

## Initialization

| Rule | Guideline | Good | Bad |
|------|-----------|------|-----|
| ES.20 | Always initialize | `int x{0};` | `int x;` |
| ES.21 | Don't introduce variables before needed | Declare at first use | Declare at top of function |
| ES.22 | Don't declare until you have a value | `T x{expr};` | `T x; x = expr;` |
| ES.23 | Prefer `{}` initializer | `T x{args};` | `T x(args);` |

```cpp
// BAD: uninitialized variable (UB on read)
int x;
// ... later
x = 42;

// GOOD: initialized at declaration
int x{42};

// BAD: declare early, assign later (risk of using before assignment)
Result r;
// ... 50 lines ...
r = compute();

// GOOD: declare at first use
auto r = compute();

// BAD: () initializer — most-vexing-parse
Widget w();  // Function declaration, not a Widget!

// GOOD: {} initializer — unambiguous
Widget w{};  // Default-constructed Widget
```

## Casts

| Rule | Guideline | Cast | Use Case |
|------|-----------|------|----------|
| ES.48 | Avoid casts | -- | They neuter the type system |
| ES.49 | If needed, use named casts | `static_cast` | Standard type conversions |
| | | `dynamic_cast` | Safe downcast in hierarchies |
| | | `const_cast` | Add/remove const (rare) |
| | | `reinterpret_cast` | Low-level bit patterns |
| ES.50 | Never cast away const | -- | Unless absolutely necessary |

```cpp
// BAD: C-style cast (does whatever it takes)
int x = (int)f;
auto p = (Widget*)base_ptr;  // reinterpret_cast + const_cast combined!

// GOOD: named cast — intent is clear
int x = static_cast<int>(f);            // Numeric conversion
auto p = dynamic_cast<Derived*>(base);   // Polymorphic downcast
auto q = const_cast<char*>(str);         // Remove const (last resort)
auto r = reinterpret_cast<uintptr_t>(ptr);  // Bit pattern reinterpretation
```

## Control Flow

| Prefer | Over | Rule | Rationale |
|--------|------|------|-----------|
| Range-`for` | Index `for` | ES.71 | No index errors, clearer |
| `for` | `while` | ES.72 | Loop var is obvious |
| `while` | `for` | ES.73 | When no loop var exists |
| `switch` | `if` chain | ES.70 | Compiler can optimize |
| -- | `do-while` | ES.75 | Rarely best choice |
| -- | `goto` | ES.76 | Only for nested cleanup |

```cpp
// BAD: index loop (error-prone)
for (size_t i = 0; i < v.size(); ++i) {
    process(v[i]);
}

// GOOD: range-for (clear, safe)
for (const auto& x : v) {
    process(x);
}

// BAD: implicit fallthrough
switch (color) {
    case Red:   cout << "red";
    case Green: cout << "green";  // Falls through to Blue!
    case Blue:  cout << "blue";
}

// GOOD: explicit break or [[fallthrough]]
switch (color) {
    case Red:
        cout << "red";
        break;
    case Green:
        cout << "green";
        [[fallthrough]];  // Intentional fallthrough
    case Blue:
        cout << "blue or green";
        break;
}
```

## Arithmetic

| Rule | Guideline | Example |
|------|-----------|---------|
| ES.100 | Don't mix signed/unsigned | `i < v.size()` — i is signed, size() is unsigned |
| ES.101 | Unsigned for bit manipulation | `mask << shift` — unsigned avoids UB |
| ES.102 | Signed for arithmetic | `a - b` — negative results need signed |
| ES.46 | Avoid narrowing conversions | `int x{3.14};` — narrowing error |
| ES.103 | Don't overflow | Overflow is UB for signed |
| ES.104 | Don't underflow | Underflow is well-defined for unsigned (wrapping) |
| ES.105 | Don't divide by zero | Check divisor |
| ES.106 | Don't assume wraparound | Signed overflow is UB, not wrap |
| ES.107 | Don't use `unsigned` for subscripts | Prefer `gsl::index` |

```cpp
// BAD: signed/unsigned comparison
for (int i = 0; i < v.size(); ++i) { }  // Warning: signed vs unsigned

// GOOD: use size_t (or range-for)
for (size_t i = 0; i < v.size(); ++i) { }

// BAD: narrowing conversion
double pi = 3.14159;
int x = pi;      // Implicit narrowing — loss of precision

// GOOD: explicit conversion
int x = static_cast<int>(pi);  // Intent is clear

// BAD: unsigned for size (causes wrapping bugs)
for (size_t i = n; i >= 0; --i) { }  // Infinite loop: wraps at 0

// GOOD: signed for reverse iteration
for (int i = static_cast<int>(n) - 1; i >= 0; --i) { }
```

## Pointers and Null

| Rule | Guideline |
|------|-----------|
| ES.47 | Use `nullptr`, not `0` or `NULL` |
| ES.65 | Don't dereference invalid pointers |
| ES.27 | Prefer `std::array` over C-arrays |

```cpp
// BAD: NULL or 0
if (ptr != NULL) {}
int* p = 0;

// GOOD: nullptr
if (ptr != nullptr) {}
int* p = nullptr;
```

## Macros

| Rule | Guideline |
|------|-----------|
| ES.30 | Don't use macros for text manipulation |
| ES.31 | Don't use macros for constants or functions |
| ES.32 | If you must: ALL_CAPS, unique names |
| ES.33 | If you must: unique names |
| ES.34 | Don't define variadic macros |

```cpp
// BAD: macro for constant
#define MAX_SIZE 1024

// GOOD: constexpr
constexpr int MaxSize = 1024;

// BAD: macro for function
#define MIN(a, b) ((a) < (b) ? (a) : (b))
// Problems: double evaluation, no type safety

// GOOD: constexpr function
template<typename T>
constexpr auto min(T a, T b) { return a < b ? a : b; }
```

## Anti-Patterns

```cpp
// BAD: C-style cast
double d = 3.14;
int x = (int)d;

// GOOD: named cast
int x = static_cast<int>(d);

// BAD: NULL
if (p == NULL) return;

// GOOD: nullptr
if (p == nullptr) return;

// BAD: index loop
for (int i = 0; i < v.size(); ++i) { use(v[i]); }

// GOOD: range-for
for (const auto& x : v) { use(x); }

// BAD: uninitialized variable
int x;
// 50 lines later
use(x);  // UB: x uninitialized

// GOOD: initialized variable
int x{compute_default()};
use(x);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-init-variables` | ES.20 |
| `cppcoreguidelines-avoid-goto` | ES.76 |
| `cppcoreguidelines-avoid-do-while` | ES.75 |
| `cppcoreguidelines-pro-type-cstyle-cast` | ES.48-49 |
| `cppcoreguidelines-pro-type-const-cast` | ES.50 |
| `cppcoreguidelines-pro-type-reinterpret-cast` | ES.48 |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | ES.42 |
| `cppcoreguidelines-pro-bounds-constant-array-index` | ES.55 |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | I.13 |
| `cppcoreguidelines-pro-type-vararg` | ES.34 |
| `cppcoreguidelines-macro-usage` | ES.30-33 |
| `modernize-use-nullptr` | ES.47 |
| `modernize-loop-convert` | ES.71-72 |
| `modernize-avoid-c-style-cast` | ES.48-49 |
| `modernize-use-auto` | ES.11 |
| `modernize-use-structured-binding` | ES.11 |
| `bugprone-narrowing-conversions` | ES.46 |
| `bugprone-signed-bitwise` | ES.101 |
| `bugprone-reserved-identifier` | ES.9 |
| `readability-implicit-signed-conversion` | ES.100 |

## Cross-References

- For function-level control flow: load `functions`
- For template-related expressions (SFINAE): load `templates`
- For clang-tidy configuration: load `clang-tidy`
