# C++ Enumerations (Enum Section)

Guidelines for enumeration design and usage.

## Rules

| Guideline | Rationale |
|-----------|-----------|
| Prefer enumerations over macros | Type safety, scoping, debuggability |
| Use enums for related named constants | Groups logically connected values |
| Prefer `enum class` over plain `enum` | Scoped, no implicit conversion |
| Define operations on enums for safe use | Serialization, iteration, bitmask ops |
| Don't use `ALL_CAPS` for enumerators | Reserve ALL_CAPS for macros |
| Avoid unnamed enumerations | Every type deserves a name |
| Specify underlying type only when necessary | `int` is default, `char` for space |
| Specify enumerator values only when necessary | Auto-numbering is clearer |

## Enum Class (Preferred)

```cpp
// Plain enum (pollutes enclosing scope, implicit int conversion)
enum Color { Red, Green, Blue };
int x = Red;  // Implicit conversion — type safety lost
// Red, Green, Blue also pollute the enclosing namespace

// enum class (scoped, no implicit conversion)
enum class Color { Red, Green, Blue };
auto c = Color::Red;
// int x = c;  // Error: no implicit conversion (type safe)
```

### When Plain Enum Is Acceptable

```cpp
// As a bitmask (requires explicit operators)
enum Flags { None = 0, Read = 1, Write = 2, Exec = 4 };

// For ABI stability with C code
enum DeviceState { Offline, Online, Error };
// Use with extern "C" interfaces
```

## Operations on Enums

```cpp
// Define operations for safe and simple use

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

// Iteration helper (manual, C++ has no magic enumeration)
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
    Iterator end() const {
        return {static_cast<E>(static_cast<int>(Last) + 1)};
    }
};
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
// Macros for constants (no type safety, no scoping)
#define MAX_SIZE 1024
#define COLOR_RED 0

// enum class or constexpr
enum class Color { Red, Green, Blue };
constexpr int MaxSize = 1024;

// ALL_CAPS enumerators (collides with macros)
enum class Status { SUCCESS, FAILURE, PENDING };

// PascalCase or CamelCase
enum class Status { Success, Failure, Pending };

// Unnamed enum (hard to reference the type)
enum { Off, On, Standby };
void set_mode(int mode);  // What type? No way to enforce correctness.

// Named
enum class PowerState { Off, On, Standby };
void set_mode(PowerState state);

// Specifying underlying type unnecessarily
enum class Color : int { Red, Green, Blue };  // int is already default

// Only specify when necessary
enum class Color : std::uint8_t { Red, Green, Blue };  // Compact storage
```

### Switch Exhaustiveness

When switching on an enum class, enable compiler warnings to catch missing cases:

```cpp
// Enable: -Wswitch -Werror=switch (or -Wcovered-switch-default in clang)

enum class Color { Red, Green, Blue };

// Missing case (compiler warning if -Wswitch is on)
std::string to_string(Color c) {
    switch (c) {
    case Color::Red:   return "Red";
    case Color::Green: return "Green";
    // Blue not handled
    }
}

// All cases covered
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
// Pattern 1: switch (compiler checks exhaustiveness)
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

// Pattern 2: array lookup (fast, but risks sync issues)
constexpr std::string_view ErrorCodeNames[] = {
    "none",              // None = 0
    "not found",         // NotFound = 1
    "permission denied", // PermissionDenied = 2
    "unknown error",     // Unknown = 3
};
static_assert(std::size(ErrorCodeNames) ==
              static_cast<int>(ErrorCode::Unknown) + 1);
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-use-enum-class` | Prefer enum class over plain enum |
| `modernize-macro-to-enum` | Replace constant macros with enums |
| `readability-enum-initial-value` | Ensure enum initial values are consistent |

## Cross-References

- For enum modernization (macro to enum): load `modernize`
- For clang-tidy configuration: load `clang-tidy`
