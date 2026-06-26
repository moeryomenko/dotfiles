# C++ Expressions and Statements (ES Section)

Guidelines for initialization, casts, control flow, arithmetic, and macros.

## Initialization

| Guideline | Good | Bad |
|-----------|------|-----|
| Always initialize | `int x{0};` | `int x;` |
| Don't introduce variables before needed | Declare at first use | Declare at top of function |
| Don't declare until you have a value | `T x{expr};` | `T x; x = expr;` |
| Prefer `{}` initializer | `T x{args};` | `T x(args);` |

```cpp
// Uninitialized variable (UB on read)
int x;
// ... later
x = 42;

// Initialized at declaration
int x{42};

// Declare early, assign later (risk of using before assignment)
Result r;
// ... 50 lines ...
r = compute();

// Declare at first use
auto r = compute();

// Most-vexing-parse
Widget w();  // Function declaration, not a Widget!

// {} initializer — unambiguous
Widget w{};  // Default-constructed Widget
```

## Casts

| Guideline | Cast | Use Case |
|-----------|------|----------|
| Avoid casts | -- | They neuter the type system |
| If needed, use named casts | `static_cast` | Standard type conversions |
| | `dynamic_cast` | Safe downcast in hierarchies |
| | `const_cast` | Add/remove const (rare) |
| | `reinterpret_cast` | Low-level bit patterns |
| Never cast away const | -- | Unless absolutely necessary |

```cpp
// C-style cast (does whatever it takes)
int x = (int)f;
auto p = (Widget*)base_ptr;  // reinterpret_cast + const_cast combined!

// Named cast — intent is clear
int x = static_cast<int>(f);              // Numeric conversion
auto p = dynamic_cast<Derived*>(base);     // Polymorphic downcast
auto q = const_cast<char*>(str);           // Remove const (last resort)
auto r = reinterpret_cast<uintptr_t>(ptr); // Bit pattern reinterpretation
```

## Control Flow

| Prefer | Over | Rationale |
|--------|------|-----------|
| Range-`for` | Index `for` | No index errors, clearer |
| `for` | `while` | Loop var is obvious |
| `while` | `for` | When no loop var exists |
| `switch` | `if` chain | Compiler can optimize |
| -- | `do-while` | Rarely best choice |
| -- | `goto` | Only for nested cleanup |

```cpp
// Index loop (error-prone)
for (size_t i = 0; i < v.size(); ++i) {
    process(v[i]);
}

// Range-for (clear, safe)
for (const auto& x : v) {
    process(x);
}

// Implicit fallthrough
switch (color) {
    case Red:   cout << "red";
    case Green: cout << "green";  // Falls through to Blue!
    case Blue:  cout << "blue";
}

// Explicit break or [[fallthrough]]
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

| Guideline | Example |
|-----------|---------|
| Don't mix signed/unsigned | `i < v.size()` — i is signed, size() is unsigned |
| Unsigned for bit manipulation | `mask << shift` — unsigned avoids UB |
| Signed for arithmetic | `a - b` — negative results need signed |
| Avoid narrowing conversions | `int x{3.14};` — narrowing error |
| Don't overflow | Overflow is UB for signed |
| Don't underflow | Underflow is well-defined for unsigned (wrapping) |
| Don't assume wraparound | Signed overflow is UB, not wrap |
| Don't use `unsigned` for subscripts | Prefer `gsl::index` |

```cpp
// Narrowing conversion
double pi = 3.14159;
int x = pi;      // Implicit narrowing — loss of precision

// Explicit conversion
int x = static_cast<int>(pi);

// Unsigned for reverse iteration (wraps at 0 — infinite loop)
for (size_t i = n; i >= 0; --i) { }

// Signed for reverse iteration
for (int i = static_cast<int>(n) - 1; i >= 0; --i) { }
```

## Pointers and Null

| Guideline | Why |
|-----------|-----|
| Use `nullptr`, not `0` or `NULL` | Type safety, no ambiguity |
| Don't dereference invalid pointers | Classic UB source |
| Prefer `std::array` over C-arrays | Bounds-safe, standard interface |

```cpp
if (ptr != nullptr) {}
int* p = nullptr;
```

## Macros

| Guideline | Why |
|-----------|-----|
| Don't use macros for text manipulation | Unhygienic, global scope |
| Don't use macros for constants or functions | Use constexpr instead |
| If you must: ALL_CAPS, unique names | Avoid collisions |
| Don't define variadic macros | Type-unsafe |

```cpp
// Macro for constant — no type safety
#define MAX_SIZE 1024

// constexpr
constexpr int MaxSize = 1024;

// Macro for function — double evaluation risk
#define MIN(a, b) ((a) < (b) ? (a) : (b))

// constexpr function — type-safe, single evaluation
template<typename T>
constexpr auto min(T a, T b) { return a < b ? a : b; }
```

## Anti-Patterns

```cpp
// C-style cast
double d = 3.14;
int x = (int)d;

// Named cast
int x = static_cast<int>(d);

// NULL
if (p == NULL) return;

// nullptr
if (p == nullptr) return;

// Index loop
for (int i = 0; i < v.size(); ++i) { use(v[i]); }

// Range-for
for (const auto& x : v) { use(x); }

// Uninitialized variable
int x;
// 50 lines later
use(x);  // UB: x uninitialized

// Initialized variable
int x{compute_default()};
use(x);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-init-variables` | Detect uninitialized vars |
| `cppcoreguidelines-avoid-goto` | Detect goto usage |
| `cppcoreguidelines-avoid-do-while` | Detect do-while |
| `cppcoreguidelines-pro-type-cstyle-cast` | Detect C-style casts |
| `cppcoreguidelines-pro-type-const-cast` | Detect const casts |
| `cppcoreguidelines-pro-type-reinterpret-cast` | Detect reinterpret casts |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | Detect pointer arithmetic |
| `cppcoreguidelines-pro-bounds-constant-array-index` | Detect non-const array index |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | Detect array decay |
| `cppcoreguidelines-pro-type-vararg` | Detect varargs |
| `cppcoreguidelines-macro-usage` | Detect problematic macros |
| `modernize-use-nullptr` | Replace NULL/0 with nullptr |
| `modernize-loop-convert` | Convert index loops to range-for |
| `modernize-avoid-c-style-cast` | Replace C-style casts |
| `modernize-use-auto` | Use auto for type deduction |
| `bugprone-narrowing-conversions` | Detect narrowing conversions |
| `bugprone-signed-bitwise` | Detect signed bitwise ops |
| `readability-implicit-signed-conversion` | Detect implicit signed conversion |

## Cross-References

- For function-level control flow: load `functions`
- For template-related expressions (SFINAE): load `templates`
- For clang-tidy configuration: load `clang-tidy`
