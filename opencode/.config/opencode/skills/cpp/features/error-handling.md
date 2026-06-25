# C++ Error Handling (E Section)

Exception-based error handling with RAII safety.

## Core Strategy

1. **Develop error strategy early** (E.1): decide exception/no-exception from the start
2. **Throw when function cannot perform its task** (E.2): exceptions are for failures
3. **Exceptions for errors only, not control flow** (E.3): never throw for expected outcomes
4. **Design around invariants** (E.4): each function ensures invariants hold on exit

```cpp
// BAD: using exceptions for control flow
try {
    if (!find_value(key)) throw not_found{};
    // Process value
} catch (const not_found&) {
    // Expected case handled as exception — wasteful
}

// GOOD: return status for expected outcomes
if (auto val = find_value(key)) {
    process(*val);
} else {
    // Expected case: value not found
}
```

## Exception Rules

| Rule | Guideline | Good | Bad |
|------|-----------|------|-----|
| E.14 | Use purpose-designed UDTs | `throw ValidationError{msg}` | `throw "error"` |
| E.15 | Throw by value, catch by reference | `catch(const exception& e)` | `catch(exception e)` |
| E.16 | Never throw from destructors | Destructors `noexcept` | Throw in ~T() |
| E.17 | Don't catch every exception everywhere | Selective catch | `catch(...)` blanket |
| E.18 | Minimize explicit try/catch | Use RAII for cleanup | Manual cleanup on error |
| E.31 | Order catches: most derived first | `catch(Derived)` before `catch(Base)` | Wrong order = dead code |

```cpp
// BAD: throw built-in type
throw 42;
throw "error occurred";

// GOOD: purpose-designed exception type
class ValidationError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};
throw ValidationError{"invalid input"};

// BAD: catch by value (slicing)
try { /* ... */ }
catch (std::exception e) {  // Slices derived types
    std::cerr << e.what();
}

// GOOD: catch by reference (no slicing)
try { /* ... */ }
catch (const std::exception& e) {
    std::cerr << e.what();
}

// BAD: wrong catch order — Base catches everything
try { /* ... */ }
catch (const std::exception& e) { /* catches all */ }
catch (const ValidationError& e) { /* dead code */ }

// GOOD: most derived first
try { /* ... */ }
catch (const ValidationError& e) { /* specific handling */ }
catch (const std::exception& e) { /* general fallback */ }
```

## Noexcept

| Rule | Guideline | Example |
|------|-----------|---------|
| E.12 | Declare `noexcept` when throw is impossible | Move ops, destructors, swap |
| C.37 | Destructors must be `noexcept` | `~Widget() noexcept` |
| C.64 | Move operations must be `noexcept` | `Widget(Widget&&) noexcept` |
| C.85 | Swap must be `noexcept` | `void swap(Widget& other) noexcept` |
| E.13 | Never throw while owning a resource | Use RAII to avoid this |

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
// BAD: manual cleanup on error
void process() {
    Buffer* buf = new Buffer(1024);
    FILE* f = fopen("data.bin", "r");
    // ... if anything throws here, both leak
    delete buf;
    fclose(f);
}

// GOOD: RAII for all resources
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

| Rule | Strategy | Example |
|------|----------|---------|
| E.25 | Simulate RAII with scope guards | `auto guard = scope_exit([&]{ cleanup(); })` |
| E.26 | Fail fast | `if (fatal_error) std::terminate()` |
| E.27 | Systematic error codes | `std::error_code` or `tl::expected<T, E>` |
| E.28 | No global errno | Thread-safety, composability issues |

```cpp
// No-exception pattern with expected<T, E>
auto result = parse_config("app.conf");
if (!result) {
    // Handle error
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
// BAD: throw in destructor (program termination or UB)
~Widget() {
    throw std::runtime_error{"cleanup failed"};  // Called during stack unwinding?
}

// GOOD: swallow or abort in destructor
~Widget() noexcept {
    try {
        cleanup();
    } catch (...) {
        // Log, but don't throw
        std::terminate();  // Or log and suppress
    }
}

// BAD: empty catch block (swallows all errors)
catch (...) {}

// GOOD: specific catch with at least logging
catch (const std::exception& e) {
    log_error("Operation failed: {}", e.what());
    throw;  // Re-throw if can't handle
}

// BAD: exception specification (deprecated in C++11, removed in C++17)
void f() throw(std::runtime_error);

// GOOD: noexcept
void f() noexcept;
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `modernize-use-noexcept` | E.12, F.6 |
| `bugprone-throw-keyword-missing` | E.2 |
| `bugprone-empty-catch` | E.17 |
| `bugprone-exception-escape` | E.16 |
| `bugprone-no-escape` | E.16 |
| `misc-throw-by-value-catch-by-reference` | E.15 |
| `performance-noexcept-destructor` | C.37 |
| `performance-noexcept-move-constructor` | C.66 |
| `modernize-use-uncaught-exceptions` | E.16 |
| `modernize-use-nodiscard` | E.2 |
| `modernize-avoid-setjmp-longjmp` | E.2 |

## Cross-References

- For RAII patterns in resource management: load `resource-management`
- For noexcept in class design: load `classes`
- For noexcept in function design: load `functions`
- For clang-tidy configuration: load `clang-tidy`
