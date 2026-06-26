# C++ Interfaces (I Section)

Guidelines for interface design, contracts, and type safety.

## Interface Principles

| Guideline | Why |
|-----------|-----|
| Make interfaces explicit | Hidden assumptions cause bugs |
| Avoid non-const global variables | Global mutable state breaks modularity |
| Avoid singletons | Hidden dependency, hard to test |
| Make interfaces precisely typed | Stringly-typed APIs invite errors |
| State preconditions | Caller must know requirements |
| Prefer `Expects()` for preconditions | GSL contract checking |
| State postconditions | Caller must know guarantees |
| Prefer `Ensures()` for postconditions | GSL contract checking |
| Use concepts to document template interfaces | Self-documenting constraints |
| Use exceptions to signal inability to perform | Don't use error codes for fatal failures |
| Never transfer ownership by raw pointer | Use unique_ptr for ownership |
| Declare non-null pointers as `not_null` | Self-documenting, checked |
| Do not pass arrays as pointers | Use span<T> or vector<T>& |
| Avoid complex global initialization | Static init order fiasco |
| Keep function argument count low | 3-4 max, use struct beyond |
| Avoid adjacent swappable parameters | Same-type params are error-prone |
| Prefer empty abstract classes as interfaces | Pure interface pattern |
| Use C-style subset for cross-compiler ABI | extern "C", POD types |
| Consider Pimpl for stable library ABI | Hide implementation details |

## Preconditions and Postconditions

```cpp
// Implicit precondition (what if x < 0?)
int sqrt(int x);  // Undefined behavior?

// Explicit precondition (GSL)
int sqrt(int x) {
    Expects(x >= 0);
    // Implementation
    Ensures(result >= 0);
    return result;
}

// Precondition documented only in comment (rots over time)
// Requires: ptr != nullptr
void process(int* ptr);

// Precondition expressed in type (enforced by compiler)
void process(not_null<int*> ptr);
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
}
```

## Pointer Semantics

| Type | Meaning | Example |
|------|---------|---------|
| `not_null<T*>` | Must not be null | `void process(not_null<Widget*> pw);` |
| `span<T>` | Sequence of T | `void handle(span<const byte> data);` |
| `T*` | Position, no ownership | `void observe(const Widget* pw);` — nullable |
| `T&` | Non-null reference | `void observe(const Widget& w);` |
| `zstring` | Null-terminated C string | GSL type for C-string parameters |

```cpp
// Ambiguous interface
void process(int* data, int size);
// Is data an array? Is it nullable? Does the function take ownership?

// Explicit semantics with span
void process(span<int> data);
// Clear: view into contiguous sequence, no ownership

// Implicit null allowed
void set_name(char* name);  // Can pass nullptr — crash risk

// not_null
void set_name(not_null<zstring> name);
// Clear: name must be a valid C string
```

## Reducing Complexity

```cpp
// Too many parameters (hard to understand, easy to misorder)
void create_user(
    string name, string email, int age, string address, string phone
);
// Call site:
create_user("Alice", "alice@example.com", 30, "123 Main St", "555-0100");
// Is it (name, email) or (email, name)? Easy to swap.

// Parameter object with designated initializers
struct UserParams {
    string name;
    string email;
    int age = 0;
    string address;
    string phone;
};
void create_user(UserParams params);

create_user({.name = "Alice", .email = "alice@example.com", .age = 30});
```

## Anti-Patterns

```cpp
// Singleton (hidden global dependency)
class Logger {
public:
    static Logger& instance();
    void log(string_view msg);
};

// Dependency injection — explicit, testable
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

// Raw pointer for sequence (ambiguous: array? ownership?)
void save(int* data, int size);

// span makes intent clear
void save(span<const int> data);

// Adjacent swappable parameters — easy to misorder
void configure(int width, int height);
configure(100, 200);  // (width, height) or (height, width)?

// Strong types — unambiguous
struct Width { int value; };
struct Height { int value; };
void configure(Width w, Height h);
configure(Width{100}, Height{200});  // Order is enforced by type

// void* interface — no type safety
void serialize(void* data, size_t size, int type_tag);

// Type-safe alternatives: templates, variant, or overload set
template<typename T>
void serialize(const T& data);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-avoid-non-const-global-variables` | Detect non-const globals |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | Detect array decay |
| `cppcoreguidelines-interfaces-global-init` | Detect global init issues |
| `bugprone-easily-swappable-parameters` | Detect swappable params |
| `bugprone-throwing-static-initialization` | Detect throwing static init |
| `misc-static-initialization-cycle` | Detect static init cycles |

## Cross-References

- For function parameter passing: load `functions`
- For smart pointer ownership semantics: load `resource-management`
- For const correctness in interfaces: load `constants`
- For clang-tidy configuration: load `clang-tidy`
