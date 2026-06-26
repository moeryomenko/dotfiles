# C++ Functions (F Section)

Guidelines for function design, parameter passing, return conventions, and lambdas.

## Parameter Passing Conventions

| Intent | Convention | Rationale |
|--------|-----------|-----------|
| In (cheap to copy) | `T` by value | Simple, no aliasing concerns |
| In (expensive to copy) | `const T&` | Avoids copy, maintains const |
| In-out | `T&` | Modifies caller's variable |
| Will-move-from | `T&&` + `std::move` | Takes ownership via move |
| Forward | `T&&` + `std::forward` | Perfect forwarding |
| Out | Return value, not parameter | Clear intent, enables RVO |
| Multiple out | Return struct / tuple | Structured bindings available |
| Position (no ownership) | `T*` (nullable) | Use `not_null` if never null |
| Non-null position | `not_null<T*>` | Self-documenting non-null |
| Sequence | `span<T>` | Replaces `T*` + size |
| Transfer ownership | `unique_ptr<T>` | Exclusive ownership |
| Shared ownership | `shared_ptr<T>` | Reference-counted sharing |

### Parameter Passing Depth

```cpp
// Cheap to copy — pass by value
void set_name(std::string name);  // Fine for short strings with SSO

// Expensive to copy — const ref
void render(const std::vector<Vertex>& vertices);  // Large, read-only

// Move when callers can transfer ownership
void consume(std::vector<int> data);  // Caller can std::move or copy
```

### Will-Move-From vs Forward

```cpp
// Will-move-from: function takes ownership
void sink(std::string&& s) {
    storage_ = std::move(s);  // s is moved into storage
}

// Perfect forwarding: forward to another function preserving value category
template<typename T>
void wrapper(T&& arg) {
    target(std::forward<T>(arg));
}
```

## Return Type Rules

| Guideline | Anti-Pattern |
|-----------|--------------|
| Never return local by pointer/reference | `int& get() { int x; return x; }` — dangling |
| Don't return `T&&` | `auto&& f() { return std::move(x); }` — dangling |
| Don't `return std::move(local)` | RVO handles it, move inhibits RVO |
| Don't return `const T` | Prevents move of caller's result |
| Assignment operators return `T&` | Enables chaining: `a = b = c` |

### Return Value Optimization

```cpp
// return std::move prevents RVO
std::string make_name() {
    std::string s = "hello";
    return std::move(s);  // RVO disabled, must copy or move
}

// return local directly (RVO applies)
std::string make_name() {
    std::string s = "hello";
    return s;  // RVO: constructed directly in caller's storage
}

// const return prevents move
const std::string make_const_name();
auto s = make_const_name();  // Copy, not move (const prevents move)

// non-const return enables move
std::string make_name();
auto s = make_name();  // Move (or RVO)
```

## Lambda Rules

| Guideline | Example |
|-----------|---------|
| One-use simple lambdas | unnamed lambda inline |
| Local use | capture by reference `[&]` |
| Non-local use | capture by value `[=]` |
| Never `[=]` when capturing `this` | Copy of `this` pointer, not object |

### Lambda Capture Pitfalls

```cpp
// [=] captures this as a pointer
class Widget {
    void start_timer() {
        timer_.start([=]() {
            update();  // DANGER: this may be dangling
        });
    }
};

// Capture object by copy for async
class Widget {
    void start_timer() {
        auto self = shared_from_this();
        timer_.start([self]() {
            self->update();
        });
    }
};

// Default capture modes hide intent
std::thread t([=]() {
    process(data);  // Which captures are used? Unclear.
});

// Explicit capture
std::thread t([data]() {
    process(data);
});
```

## Function Properties

| Property | Declaration | Why |
|----------|-------------|-----|
| Must not throw | `noexcept` | Enables optimizations in containers |
| Compile-time evaluable | `constexpr` | Computation moved to compile time |
| Small + time-critical | `inline` | Hint to avoid call overhead |
| Unused params | leave unnamed | Suppresses warnings, documents intent |
| Prefer default args | over overloading | Fewer functions, clearer API |

## Anti-Patterns

```cpp
// Varargs: no type safety
void log(const char* fmt, ...);

// Variadic templates: type-safe
template<typename... Args>
void log(std::format_string<Args...> fmt, Args&&... args);

// Raw pointer for sequence: ambiguous ownership
void process(int* data, int size);

// span: clear read-only view
void process(std::span<int> data);

// Multiple bool parameters: error-prone
void configure(bool enabled, bool persistent, bool cache);

// Named enum or bit flags
enum class ConfigFlags { None, Enabled, Persistent, Cache };
void configure(ConfigFlags flags);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-rvalue-reference-param-not-moved` | Detect rvalue ref not moved |
| `cppcoreguidelines-misleading-capture-default-by-value` | Detect [=] with this |
| `cppcoreguidelines-missing-std-forward` | Detect missing forward |
| `cppcoreguidelines-pro-type-vararg` | Detect varargs usage |
| `modernize-use-noexcept` | Replace throw() with noexcept |
| `modernize-pass-by-value` | Replace const& with value when moving |
| `misc-unused-parameters` | Detect unused parameters |
| `readability-non-const-parameter` | Detect parameters that should be const |
| `readability-const-return-type` | Detect const return types |
| `performance-unnecessary-value-param` | Detect unnecessary copies |

## Cross-References

- For parameter types that use pointers/smart pointers: load `resource-management`
- For interface design and contracts: load `interfaces`
- For noexcept and exceptions: load `error-handling`
- For clang-tidy configuration: load `clang-tidy`
