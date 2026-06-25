# C++ Functions (F Section)

Guidelines for function design, parameter passing, return conventions, and lambdas.

## Parameter Passing Conventions

| Intent | Convention | Rule | Rationale |
|--------|-----------|------|-----------|
| In (cheap to copy) | `T` by value | F.16 | Simple, no aliasing concerns |
| In (expensive to copy) | `const T&` | F.16 | Avoids copy, maintains const |
| In-out | `T&` | F.17 | Modifies caller's variable |
| Will-move-from | `T&&` + `std::move` | F.18 | Takes ownership via move |
| Forward | `T&&` + `std::forward` | F.19 | Perfect forwarding |
| Out | Return value, not parameter | F.20 | Clear intent, enables RVO |
| Multiple out | Return struct / tuple | F.21 | Structured bindings available |
| Position (no ownership) | `T*` (nullable) | F.22, F.42 | Use `not_null` if never null |
| Non-null position | `not_null<T*>` | F.23 | Self-documenting non-null |
| Sequence | `span<T>` | F.24 | Replaces `T*` + size |
| Transfer ownership | `unique_ptr<T>` | F.26 | Exclusive ownership |
| Shared ownership | `shared_ptr<T>` | F.27 | Reference-counted sharing |

### Parameter Passing Depth

```cpp
// GOOD: cheap to copy — pass by value
void set_name(std::string name);  // Fine for short strings with SSO

// GOOD: expensive to copy — const ref
void render(const std::vector<Vertex>& vertices);  // Large, read-only

// BAD: forcing copy for no reason
void process(std::vector<int> data);  // Copy even when caller doesn't need it

// GOOD: move when callers can transfer ownership
void consume(std::vector<int> data);  // Caller can std::move or copy
```

### Will-Move-From vs Forward

```cpp
// F.18: will-move-from — function takes ownership
void sink(std::string&& s) {
    storage_ = std::move(s);  // s is moved into storage
}

// F.19: perfect forwarding — forward to another function
template<typename T>
void wrapper(T&& arg) {
    target(std::forward<T>(arg));  // preserves value category
}
```

## Return Type Rules

| Rule | Guideline | Anti-Pattern |
|------|-----------|--------------|
| F.43 | Never return local by pointer/reference | `int& get() { int x; return x; }` — dangling ref |
| F.45 | Don't return `T&&` | `auto&& f() { return std::move(x); }` — dangling |
| F.48 | Don't `return std::move(local)` | RVO handles it, move inhibits RVO |
| F.49 | Don't return `const T` | Prevents move of caller's result |
| F.47 | Assignment operators return `T&` | Enables chaining: `a = b = c` |

### Return Value Optimization

```cpp
// BAD: return std::move prevents RVO
std::string make_name() {
    std::string s = "hello";
    return std::move(s);  // RVO disabled, must copy or move
}

// GOOD: return local directly (RVO applies)
std::string make_name() {
    std::string s = "hello";
    return s;  // RVO: constructed directly in caller's storage
}

// BAD: const return prevents move
const std::string make_const_name();

auto s = make_const_name();  // Copy, not move (const prevents move)

// GOOD: non-const return enables move
std::string make_name();

auto s = make_name();  // Move (or RVO)
```

## Lambda Rules

| Rule | Guideline | Example |
|------|-----------|---------|
| F.11 | One-use simple | unnamed lambda inline |
| F.52 | Local use | capture by reference `[&]` |
| F.53 | Non-local use | capture by value `[=]` |
| F.54 | Never `[=]` when capturing `this` | Copy of `this` pointer, not object |

### Lambda Capture Pitfalls

```cpp
// BAD: [=] captures this as a pointer
class Widget {
    void start_timer() {
        // [=] captures this by pointer, not by copy
        timer_.start([=]() {
            update();  // DANGER: this may be dangling
        });
    }
};

// GOOD: capture object by copy for async
class Widget {
    void start_timer() {
        // Capture a copy of the shared state
        auto self = shared_from_this();
        timer_.start([self]() {
            self->update();
        });
    }
};

// BAD: default capture modes hide intent
std::thread t([=]() {
    process(data);  // Which captures are used? Unclear.
});

// GOOD: explicit capture
std::thread t([data]() {
    process(data);
});
```

## Function Properties

| Property | Declaration | Rule |
|----------|-------------|------|
| Must not throw | `noexcept` | F.6 |
| Compile-time evaluable | `constexpr` | F.4 |
| Small + time-critical | `inline` | F.5 |
| Unused params | leave unnamed | F.9 |
| Prefer default args | over overloading | F.51 |

## Anti-Patterns

```cpp
// BAD: varargs (no type safety)
void log(const char* fmt, ...);

// GOOD: variadic templates (type-safe)
template<typename... Args>
void log(std::format_string<Args...> fmt, Args&&... args);

// BAD: raw pointer for sequence (ambiguous ownership)
void process(int* data, int size);

// GOOD: span (clear: read-only view)
void process(std::span<int> data);

// BAD: multiple bool parameters (error-prone)
void configure(bool enabled, bool persistent, bool cache);

// GOOD: named enum or bit flags
enum class ConfigFlags { None, Enabled, Persistent, Cache };
void configure(ConfigFlags flags);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-rvalue-reference-param-not-moved` | F.18 |
| `cppcoreguidelines-misleading-capture-default-by-value` | F.54 |
| `cppcoreguidelines-missing-std-forward` | F.19 |
| `cppcoreguidelines-pro-type-vararg` | F.55 |
| `modernize-use-noexcept` | F.6 |
| `modernize-pass-by-value` | F.16 |
| `misc-unused-parameters` | F.9 |
| `readability-non-const-parameter` | F.16 |
| `readability-const-return-type` | F.49 |
| `performance-unnecessary-value-param` | F.16 |

## Cross-References

- For parameter types that use pointers/smart pointers: load `resource-management`
- For interface design and contracts: load `interfaces`
- For noexcept and exceptions: load `error-handling`
- For clang-tidy configuration: load `clang-tidy`
