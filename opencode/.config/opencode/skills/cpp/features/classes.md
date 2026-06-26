# C++ Classes (C Section)

Guidelines for class design, special member functions, inheritance, and operators.

## Class Design

- **`struct`**: data aggregate, no invariant, all public
- **`class`**: has invariant, encapsulated data
- **Concrete types**: make regular — default-copyable, default-movable
- **Polymorphic types**: suppress public copy/move — prevent slicing

### Struct vs Class Decision

```cpp
// Struct: when no invariant exists
struct Point {
    double x, y, z;
};

// Class: when invariant must be maintained
class Date {
    int year_, month_, day_;
public:
    Date(int y, int m, int d);  // Validates and establishes invariant
    // All mutators must preserve: valid date, month 1-12, day in range
};
```

## Special Member Functions (Rule of All/Four/Zero)

If you define **any** of copy/move/destructor, define **all**:

```cpp
class Widget {
public:
    // Default constructor
    Widget() = default;                    // Make it simple, non-throwing

    // Destructor
    ~Widget() = default;                   // Only if custom logic needed

    // Copy
    Widget(const Widget&) = default;       // Must copy all members
    Widget& operator=(const Widget&) = default;  // Non-virtual, const& param

    // Move
    Widget(Widget&&) noexcept = default;   // Leave source in valid state
    Widget& operator=(Widget&&) noexcept = default;  // Non-virtual, T&& param
};
```

### Rule of Zero

Prefer design where default semantics work:

```cpp
// Rule of Zero: no user-defined special members needed
class Employee {
    std::string name_;     // string handles its own copy/move
    std::vector<int> ids_; // vector handles its own copy/move
    double salary_;        // fundamental type trivially copyable
};
```

### Rule of Five

When managing a resource:

```cpp
class StringBuffer {
    char* data_;
    size_t size_;
public:
    explicit StringBuffer(size_t n) : data_(new char[n]), size_(n) {}
    ~StringBuffer() noexcept { delete[] data_; }

    // Copy
    StringBuffer(const StringBuffer& other)
        : data_(new char[other.size_]), size_(other.size_) {
        std::copy(other.data_, other.data_ + size_, data_);
    }
    StringBuffer& operator=(const StringBuffer& other) {
        if (this != &other) {                    // Self-assignment safe
            auto tmp = new char[other.size_];     // Strong guarantee
            std::copy(other.data_, other.data_ + other.size_, tmp);
            delete[] data_;
            data_ = tmp;
            size_ = other.size_;
        }
        return *this;
    }

    // Move
    StringBuffer(StringBuffer&& other) noexcept
        : data_(other.data_), size_(other.size_) {
        other.data_ = nullptr;   // Leave source in valid state
        other.size_ = 0;
    }
    StringBuffer& operator=(StringBuffer&& other) noexcept {
        if (this != &other) {
            delete[] data_;
            data_ = other.data_;
            size_ = other.size_;
            other.data_ = nullptr;
            other.size_ = 0;
        }
        return *this;
    }
};
```

## Constructor Rules

| Guideline | Why |
|-----------|-----|
| Constructor should establish invariant | Object validity from birth |
| Throw if cannot construct valid object | Never leave half-baked |
| Use member initializers in same order as declaration | Order-dependent initialization |
| Prefer default constructors to be simple and non-throwing | Usability in containers |
| Single-arg constructors: `explicit` by default | Prevents implicit conversions |
| Define and initialize member variables in order of declaration | Matches destruction order |
| Prefer in-class member initializers over constructor init lists | Consistency, less duplication |
| Prefer initialization to assignment in constructors | Avoids default-construct-then-assign |
| Don't call virtual functions during construction | Base class version runs, not derived |
| No plain `new`/`delete` in constructor | Use RAII |

```cpp
// Non-explicit single-arg constructor leads to implicit conversion
class Vec {
    Vec(int n);  // Vec v = 42; compiles
};

// explicit prevents accidental conversion
class Vec {
    explicit Vec(int n);
};

// Virtual function call in constructor
class Base {
public:
    Base() { init(); }  // Calls Base::init, not Derived::init
    virtual void init() { /* ... */ }
};

// Safe: separate construction from virtual dispatch
class Base {
public:
    explicit Base(int n) { /* ... */ }
    virtual void init() { /* ... */ }
};
```

## Destructor Rules

| Guideline | Why |
|-----------|-----|
| Define destructor only if class manages a resource | Rule of Zero preferred |
| Base class destructor: public+virtual or protected+non-virtual | Correct polymorphic deletion |
| Destructor must not fail | Exception during stack unwinding = terminate |
| Destructor must be `noexcept` | Required for containers, move ops |
| Class with virtual function needs virtual/protected destructor | Polymorphic deletion safety |

## Virtual Functions

| Guideline | Why |
|-----------|-----|
| Specify exactly one of: `virtual`, `override`, `final` | Clear intent, compiler checks |
| Use `override` when overriding | Catches signature mismatches |
| Redefine or prohibit copying for polymorphic classes | Prevent slicing |
| Avoid trivial getters/setters | Encapsulation violation |
| Don't make functions virtual without reason | Runtime cost, design complexity |
| Avoid protected data | Breaks encapsulation, hard to maintain |
| Prefer virtual function to casting | Type-safe polymorphism |

## Inheritance

```cpp
// Multiple inheritance for distinct interfaces
class InputDevice { /* ... */ };
class OutputDevice { /* ... */ };
class IODevice : public InputDevice, public OutputDevice { };

// Use 'using' to expose base overloads
class Base {
public:
    void foo(int);
    void foo(double);
};
class Derived : public Base {
    using Base::foo;  // Brings Base's foo overloads into scope
    void foo(std::string);
};
```

## Operators

| Guideline | Example |
|-----------|---------|
| Mimic conventional usage | `+` for addition, not subtraction |
| Symmetric operators: non-member | Enables mixed-type operands |
| Overload only for operations equivalent to built-in | Don't overload `||` for SQL |
| Avoid implicit conversion operators | Surprising implicit conversions |
| `==` must be symmetric and `noexcept` | Required for standard library use |
| `swap` must be `noexcept` | Required for strong exception guarantee |

```cpp
// Symmetric operator as non-member enables mixed operands
class Rational {
    int num_, den_;
public:
    Rational(int n, int d);
};
Rational operator+(const Rational& a, const Rational& b);
// Enables: Rational(1,2) + 1 and 1 + Rational(1,2)
```

## Anti-Patterns

```cpp
// Slicing: passing polymorphic type by value
void process(Base b) { }   // Takes by value — slices derived
Derived d;
process(d);                // d is sliced to Base

// Safe: pass by reference
void process(Base& b) { }

// Public data in class with invariant — no way to enforce
class Date { public: int year, month, day; };

// Private data with accessors preserves invariant
class Date {
    int year_, month_, day_;
public:
    void set_month(int m);  // Can validate 1-12
};
```

## Key Clang-Tidy Checks

| Check | Purpose |
|-------|---------|
| `cppcoreguidelines-special-member-functions` | Enforce rule of five |
| `cppcoreguidelines-virtual-class-destructor` | Enforce virtual/protected dtor |
| `cppcoreguidelines-slicing` | Detect slicing |
| `cppcoreguidelines-avoid-const-or-ref-data-members` | Prevent const/ref member issues |
| `cppcoreguidelines-prefer-member-initializer` | Prefer init lists |
| `modernize-use-override` | Add override specifier |
| `modernize-use-equals-default` | Use = default |
| `modernize-use-equals-delete` | Use = delete |
| `modernize-use-default-member-init` | Use in-class initializers |
| `misc-explicit-constructor` | Enforce explicit on single-arg ctors |
| `performance-noexcept-move-constructor` | Ensure noexcept on moves |
| `performance-noexcept-destructor` | Ensure noexcept on dtors |
| `performance-noexcept-swap` | Ensure noexcept on swap |

## Cross-References

- For RAII and resource management: load `resource-management`
- For error handling in constructors/destructors: load `error-handling`
- For const member functions: load `constants`
- For clang-tidy configuration: load `clang-tidy`
