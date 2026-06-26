# C++ Error Handling (E Section)

Exception-based error handling with RAII safety.

## Core Strategy

1. **Develop error strategy early**: decide exception/no-exception from the start
2. **Throw when function cannot perform its task**: exceptions are for failures
3. **Exceptions for errors only, not control flow**: never throw for expected outcomes
4. **Design around invariants**: each function ensures invariants hold on exit

```cpp
// Using exceptions for control flow (wasteful)
try {
    if (!find_value(key)) throw not_found{};
} catch (const not_found&) {
    // Expected case — should not be an exception
}

// Return status for expected outcomes
if (auto val = find_value(key)) {
    process(*val);
} else {
    // Expected case
}
```

## Exception Rules

| Guideline | Good | Bad |
|-----------|------|-----|
| Use purpose-designed UDTs | `throw ValidationError{msg}` | `throw "error"` |
| Throw by value, catch by reference | `catch(const exception& e)` | `catch(exception e)` |
| Never throw from destructors | Destructors `noexcept` | Throw in ~T() |
| Don't catch every exception everywhere | Selective catch | `catch(...)` blanket |
| Minimize explicit try/catch | Use RAII for cleanup | Manual cleanup on error |
| Order catches: most derived first | `catch(Derived)` before `catch(Base)` | Wrong order = dead code |

```cpp
// Throw built-in type (opaque, can't catch by type)
throw 42;
throw "error occurred";

// Purpose-designed exception type
class ValidationError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};
throw ValidationError{"invalid input"};

// Catch by value (slicing)
try { /* ... */ }
catch (std::exception e) {  // Slices derived types
    std::cerr << e.what();
}

// Catch by reference (no slicing)
try { /* ... */ }
catch (const std::exception& e) {
    std::cerr << e.what();
}
```

## Noexcept

| Guideline | Example |
|-----------|---------|
| Declare `noexcept` when throw is impossible | Move ops, destructors, swap |
| Destructors must be `noexcept` | `~Widget() noexcept` |
| Move operations must be `noexcept` | `Widget(Widget&&) noexcept` |
| Swap must be `noexcept` | `void swap(Widget& other) noexcept` |
| Never throw while owning a resource | Use RAII to avoid this |

```cpp
// Why noexcept matters:
// std::vector uses move when push_back reallocates
// BUT: only if move is noexcept
// If move can throw, vector COPIES instead (slower)

struct Safe {
    Safe(Safe&&) noexcept;  // noexcept — vector will move
};

struct Unsafe {
    Unsafe(Unsafe&&);  // Can throw — vector will copy
};
```

## RAII for Error Safety

```cpp
// Manual cleanup on error (leak-prone)
void process() {
    Buffer* buf = new Buffer(1024);
    FILE* f = fopen("data.bin", "r");
    // ... if anything throws here, both leak
    delete buf;
    fclose(f);
}

// RAII for all resources
void process() {
    auto buf = std::make_unique<Buffer>(1024);
    std::ifstream f("data.bin");
    // ... if anything throws, ~unique_ptr and ~ifstream run
}
```

### Exception Safety Guarantees

| Guarantee | Meaning | When |
|-----------|---------|------|
| **No-throw** | Operation always succeeds | Destructors, swap, move |
| **Strong** | On failure, state is unchanged | Most mutating operations |
| **Basic** | On failure, no resource leak, valid state | Default for operations that can't provide strong |
| **No** | No guarantees | Never acceptable in modern C++ |

```cpp
// Strong guarantee: copy-and-swap
class Widget {
    std::vector<int> data_;
public:
    void assign(const std::vector<int>& new_data) {
        auto tmp = new_data;           // Can throw — no side effect yet
        data_.swap(tmp);               // noexcept — commit
    }  // Strong guarantee: on exception, data_ unchanged
};
```

## No-Exception Alternative

When exceptions are unavailable or prohibited:

| Strategy | Example |
|----------|---------|
| Simulate RAII with scope guards | `auto guard = scope_exit([&]{ cleanup(); })` |
| Fail fast | `if (fatal_error) std::terminate()` |
| Systematic error codes | `std::error_code` or `tl::expected<T, E>` |
| No global errno | Thread-safety, composability issues |

```cpp
// No-exception pattern with expected<T, E>
auto result = parse_config("app.conf");
if (!result) {
    auto err = result.error();
    return;
}
auto value = *result;

// Scope guard for manual cleanup
auto cleanup = scope_exit([&] {
    if (file) fclose(file);
    free(buffer);
});
```

## Anti-Patterns

```cpp
// Throw in destructor (program termination or UB)
~Widget() {
    throw std::runtime_error{"cleanup failed"};
}

// Swallow or abort in destructor
~Widget() noexcept {
    try {
        cleanup();
    } catch (...) {
        std::terminate();
    }
}

// Empty catch block (swallows all errors)
catch (...) {}

// Specific catch with at least logging
catch (const std::exception& e) {
    log_error("Operation failed: {}", e.what());
    throw;
}

// Exception specification (deprecated C++11, removed C++17)
void f() throw(std::runtime_error);

// noexcept
void f() noexcept;
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `modernize-use-noexcept` | Replace throw() with noexcept |
| `bugprone-throw-keyword-missing` | Detect missing throw in rethrow context |
| `bugprone-empty-catch` | Detect empty catch blocks |
| `bugprone-exception-escape` | Detect functions that may throw unexpectedly |
| `misc-throw-by-value-catch-by-reference` | Enforce throw/catch convention |
| `performance-noexcept-destructor` | Ensure noexcept on dtors |
| `performance-noexcept-move-constructor` | Ensure noexcept on moves |
| `modernize-use-nodiscard` | Add [[nodiscard]] |
| `modernize-avoid-setjmp-longjmp` | Replace setjmp/longjmp |

## Cross-References

- For RAII patterns in resource management: load `resource-management`
- For noexcept in class design: load `classes`
- For noexcept in function design: load `functions`
- For clang-tidy configuration: load `clang-tidy`
