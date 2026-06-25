# C++ Interfaces (I Section)

Guidelines for interface design, contracts, and type safety.

## Interface Principles

| Rule | Guideline | Why |
|------|-----------|-----|
| I.1 | Make interfaces explicit | Hidden assumptions cause bugs |
| I.2 | Avoid non-const global variables | Global mutable state breaks modularity |
| I.3 | Avoid singletons | Hidden dependency, hard to test |
| I.4 | Make interfaces precisely typed | Stringly-typed APIs invite errors |
| I.5 | State preconditions | Caller must know requirements |
| I.6 | Prefer `Expects()` for preconditions | GSL contract checking |
| I.7 | State postconditions | Caller must know guarantees |
| I.8 | Prefer `Ensures()` for postconditions | GSL contract checking |
| I.9 | If interface is a template, document with concepts | Self-documenting constraints |
| I.10 | Use exceptions to signal inability to perform | Don't use error codes for fatal failures |
| I.11 | Never transfer ownership by raw pointer (T*) | Use unique_ptr for ownership |
| I.12 | Declare non-null pointers as `not_null` | Self-documenting, checked |
| I.13 | Do not pass arrays as pointers | Use span<T> or vector<T>& |
| I.22 | Avoid complex global initialization | Static init order fiasco |
| I.23 | Keep function argument count low | 3-4 max, use struct beyond |
| I.24 | Avoid adjacent swappable parameters | Same-type params are error-prone |
| I.25 | Prefer empty abstract classes as interfaces | Pure interface pattern |
| I.26 | Use C-style subset for cross-compiler ABI | extern "C", POD types |
| I.27 | Consider Pimpl for stable library ABI | Hide implementation details |

## Preconditions and Postconditions

```cpp
// BAD: implicit precondition
int sqrt(int x);  // What if x < 0? Undefined behavior?

// GOOD: explicit precondition (GSL)
int sqrt(int x) {
    Expects(x >= 0);
    // Implementation
    Ensures(result >= 0);
    return result;
}

// BAD: precondition documented only in comment
// Requires: ptr != nullptr
void process(int* ptr);  // Comments rot; code is truth

// GOOD: precondition expressed in type
void process(not_null<int*> ptr);  // Type system enforces it
```

### GSL Contract Macros

```cpp
#include <gsl/assert>

void set_age(Person& p, int age) {
    Expects(age >= 0 && age <= 150);
    // ... mutation code ...
    Ensures(p.age() == age);
}

// When contract is violated:
// - Default: calls std::terminate
// - Custom: install gsl::contract_violation handler

// Without GSL, the equivalent:
void set_age(Person& p, int age) {
    if (age < 0 || age > 150) {
        throw std::invalid_argument("invalid age");
    }
    // ...
}
```

## Pointer Semantics

| Type | Meaning | Rule | Example |
|------|---------|------|---------|
| `not_null<T*>` | Must not be null | I.12 | `void process(not_null<Widget*> pw);` |
| `span<T>` | Sequence of T | I.13, F.24 | `void handle(span<const byte> data);` |
| `T*` | Position, no ownership | I.11, F.42 | `void observe(const Widget* pw);` — nullable |
| `T&` | Non-null reference | I.11 | `void observe(const Widget& w);` |
| `zstring` | Null-terminated C string | I.13 | GSL type for C-string parameters |

```cpp
// BAD: ambiguous interface
void process(int* data, int size);
// Is data an array? Is it nullable? Does the function take ownership?

// GOOD: explicit semantics with span
void process(span<int> data);
// Clear: view into contiguous sequence, no ownership

// BAD: implicit null allowed
void set_name(char* name);  // Can pass nullptr — crash risk

// GOOD: not_null
void set_name(not_null<zstring> name);
// Clear: name must be a valid C string
```

## Reducing Complexity

```cpp
// BAD: too many parameters (hard to understand, easy to misorder)
void create_user(
    string name,
    string email,
    int age,
    string address,
    string phone
);
// Call site:
create_user("Alice", "alice@example.com", 30, "123 Main St", "555-0100");
// Is it (name, email) or (email, name)? Easy to swap.

// GOOD: parameter object
struct UserParams {
    string name;
    string email;
    int age = 0;
    string address;
    string phone;
};
void create_user(UserParams params);
// Call site:
create_user({.name = "Alice", .email = "alice@example.com", .age = 30});
// Designated initializers make call sites self-documenting
```

## Anti-Patterns

```cpp
// BAD: singleton (hidden global dependency)
class Logger {
public:
    static Logger& instance();
    void log(string_view msg);
};

// GOOD: dependency injection
class Logger {
public:
    virtual void log(string_view msg) = 0;
};
class App {
    Logger& logger_;
public:
    App(Logger& logger) : logger_(logger) {}
    void run() { logger_.log("started"); }
};

// BAD: raw pointer for sequence (ambiguous)
void save(int* data, int size);

// GOOD: span
void save(span<const int> data);

// BAD: adjacent swappable parameters
void configure(int width, int height);

// Call site:
configure(100, 200);  // Is it (width, height) or (height, width)?

// GOOD: strong types
struct Width { int value; };
struct Height { int value; };
void configure(Width w, Height h);

configure(Width{100}, Height{200});  // Unambiguous
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-avoid-non-const-global-variables` | I.2, R.6 |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | I.13 |
| `cppcoreguidelines-interfaces-global-init` | I.22 |
| `bugprone-easily-swappable-parameters` | I.24 |
| `bugprone-throwing-static-initialization` | I.22 |
| `misc-static-initialization-cycle` | I.22 |

## Cross-References

- For function parameter passing: load `functions`
- For smart pointer ownership semantics: load `resource-management`
- For const correctness in interfaces: load `constants`
- For clang-tidy configuration: load `clang-tidy`
