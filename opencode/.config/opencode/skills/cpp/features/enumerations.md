# C++ Enumerations (Enum Section)

Guidelines for enumeration design and usage.

## Rules

| Rule | Guideline | Rationale |
|------|-----------|-----------|
| Enum.1 | Prefer enumerations over macros | Type safety, scoping, debuggability |
| Enum.2 | Use enums for related named constants | Groups logically connected values |
| Enum.3 | Prefer `enum class` over plain `enum` | Scoped, no implicit conversion |
| Enum.4 | Define operations on enums for safe use | Serialization, iteration, bitmask ops |
| Enum.5 | Don't use `ALL_CAPS` for enumerators | Reserve ALL_CAPS for macros |
| Enum.6 | Avoid unnamed enumerations | Every type deserves a name |
| Enum.7 | Specify underlying type only when necessary | `int` is default, `char` for space |
| Enum.8 | Specify enumerator values only when necessary | Auto-numbering is clearer |

## Enum Class (Preferred)

```cpp
// BAD: plain enum (pollutes enclosing scope, implicit int conversion)
enum Color { Red, Green, Blue };
int x = Red;  // Implicit conversion — type safety lost
// Also: Red, Green, Blue pollute the namespace

// GOOD: enum class (scoped, no implicit conversion)
enum class Color { Red, Green, Blue };
auto c = Color::Red;
// int x = c;  // Error: no implicit conversion (type safe)
```

### When Plain Enum Is Acceptable

```cpp
// As a bitmask (requires explicit operators)
enum Flags { None = 0, Read = 1, Write = 2, Exec = 4 };
// Flags f = Read | Write;  // OK: int conversion enables bitwise ops

// For ABI stability with C code
enum DeviceState { Offline, Online, Error };
// Use with extern "C" interfaces
```

## Operations on Enums

```cpp
// Enum.4: define operations for safe and simple use

enum class Color { Red, Green, Blue };

// Stream operator
std::ostream& operator<<(std::ostream& os, Color c) {
    switch (c) {
    case Color::Red:   return os << "Red";
    case Color::Green: return os << "Green";
    case Color::Blue:  return os << "Blue";
    }
    return os << "unknown";
}

// Conversion from string
std::optional<Color> to_color(std::string_view name) {
    if (name == "Red")   return Color::Red;
    if (name == "Green") return Color::Green;
    if (name == "Blue")  return Color::Blue;
    return std::nullopt;
}

// Iteration (manual, C++ doesn't have magic enumeration)
template<typename E, E First, E Last>
struct EnumRange {
    struct Iterator {
        E value;
        E operator*() const { return value; }
        Iterator& operator++() {
            value = static_cast<E>(static_cast<int>(value) + 1);
            return *this;
        }
        bool operator!=(const Iterator& other) const {
            return value != other.value;
        }
    };
    Iterator begin() const { return {First}; }
    Iterator end() const { return {static_cast<E>(static_cast<int>(Last) + 1)}; }
};

// Usage: for (auto c : EnumRange<Color, Color::Red, Color::Blue>) { ... }
```

## Bitmask Enums

```cpp
// Bitmask enum pattern
enum class Permissions : unsigned {
    None    = 0,
    Read    = 1 << 0,
    Write   = 1 << 1,
    Execute = 1 << 2,
    All     = Read | Write | Execute
};

// Bitwise operators for enum class
constexpr Permissions operator|(Permissions a, Permissions b) {
    return static_cast<Permissions>(static_cast<unsigned>(a) |
                                     static_cast<unsigned>(b));
}
constexpr Permissions operator&(Permissions a, Permissions b) {
    return static_cast<Permissions>(static_cast<unsigned>(a) &
                                     static_cast<unsigned>(b));
}
constexpr Permissions operator~(Permissions a) {
    return static_cast<Permissions>(~static_cast<unsigned>(a));
}

// Usage
Permissions p = Permissions::Read | Permissions::Write;
if ((p & Permissions::Read) != Permissions::None) {
    // Has read permission
}
```

## Anti-Patterns

```cpp
// BAD: macros for constants
#define MAX_SIZE 1024
#define COLOR_RED 0
#define COLOR_GREEN 1
#define COLOR_BLUE 2
// No type safety, no scoping, preprocessor-only

// GOOD: enum class or constexpr
enum class Color { Red, Green, Blue };
constexpr int MaxSize = 1024;

// BAD: ALL_CAPS enumerators
enum class Status { SUCCESS, FAILURE, PENDING };
// ALL_CAPS collides with macros; SUCCESS is likely #defined elsewhere

// GOOD: PascalCase or CamelCase enumerators
enum class Status { Success, Failure, Pending };

// BAD: unnamed enum (hard to reference the type)
enum { Off, On, Standby };
// void set_mode(int mode);  // What type?

// GOOD: named
enum class PowerState { Off, On, Standby };
void set_mode(PowerState state);

// BAD: specifying underlying type unnecessarily
enum class Color : int { Red, Green, Blue };  // int is already default

// GOOD: only specify when necessary
enum class Color : std::uint8_t { Red, Green, Blue };  // Compact storage
```

### Switch Exhaustiveness

When switching on an enum class, enable compiler warnings to catch missing cases:

```cpp
// Enable: -Wswitch -Werror=switch (or -Wcovered-switch-default in clang)

enum class Color { Red, Green, Blue };

// BAD: missing case (compiler warning if -Wswitch is on)
std::string to_string(Color c) {
    switch (c) {
    case Color::Red:   return "Red";
    case Color::Green: return "Green";
    // Blue not handled
    }
}

// GOOD: all cases covered
std::string to_string(Color c) {
    switch (c) {
    case Color::Red:   return "Red";
    case Color::Green: return "Green";
    case Color::Blue:  return "Blue";
    }
    std::unreachable();  // All cases handled
}
```

### Enum-to-String Mapping Patterns

```cpp
// Pattern 1: switch (compile-time dispatch, compiler checks exhaustiveness)
enum class ErrorCode { None, NotFound, PermissionDenied, Unknown };

std::string_view to_string(ErrorCode ec) {
    using enum ErrorCode;
    switch (ec) {
    case None:             return "none";
    case NotFound:         return "not found";
    case PermissionDenied: return "permission denied";
    case Unknown:          return "unknown error";
    }
    std::unreachable();
}

// Pattern 2: array lookup (fast, but risks getting out of sync)
constexpr std::string_view ErrorCodeNames[] = {
    "none",              // None = 0
    "not found",         // NotFound = 1
    "permission denied", // PermissionDenied = 2
    "unknown error",     // Unknown = 3
};
static_assert(std::size(ErrorCodeNames) == static_cast<int>(ErrorCode::Unknown) + 1);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-use-enum-class` | Enum.3 |
| `modernize-macro-to-enum` | Enum.1 |
| `readability-enum-initial-value` | Enum.8 |

## Cross-References

- For enum modernization (macro to enum): load `modernize`
- For clang-tidy configuration: load `clang-tidy`
