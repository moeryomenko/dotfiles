# C++ Classes (C Section)

Guidelines for class design, special member functions, inheritance, and operators.

## Class Design

- **`struct`**: data aggregate, no invariant, all public (C.2, C.8)
- **`class`**: has invariant, encapsulated data (C.2, C.8)
- **Concrete types**: make regular (C.11) — default-copyable, default-movable
- **Polymorphic types**: suppress public copy/move (C.67) — prevent slicing

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

If you define **any** of copy/move/destructor, define **all** (C.21):

```cpp
class Widget {
public:
    // Default constructor
    Widget() = default;                    // C.44: simple, non-throwing

    // Destructor
    ~Widget() = default;                   // C.30: only if custom logic needed

    // Copy
    Widget(const Widget&) = default;       // C.61: must copy all members
    Widget& operator=(const Widget&) = default;  // C.60: non-virtual, const& param, T& return

    // Move
    Widget(Widget&&) noexcept = default;   // C.64: leave source in valid state
    Widget& operator=(Widget&&) noexcept = default;  // C.63: non-virtual, T&& param
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

| Rule | Guideline |
|------|-----------|
| C.41 | Constructor should establish invariant |
| C.42 | Throw if cannot construct valid object — never leave half-baked |
| C.43 | Use member initializers in same order as declaration |
| C.44 | Prefer default constructors to be simple and non-throwing |
| C.46 | Single-arg constructors: `explicit` by default |
| C.47 | Define and initialize member variables in order of declaration |
| C.48 | Prefer in-class member initializers over constructor init lists |
| C.49 | Prefer initialization to assignment in constructors |
| C.82 | Don't call virtual functions during construction |
| C.84 | No plain `new`/`delete` in constructor — use RAII |

```cpp
// BAD: non-explicit single-arg constructor
class Vec {
    Vec(int n);  // Implicit conversion: Vec v = 42;
};

// GOOD: explicit
class Vec {
    explicit Vec(int n);
};

// BAD: virtual function call in constructor
class Base {
public:
    Base() { init(); }  // Calls Base::init, not Derived::init
    virtual void init() { /* ... */ }
};

// GOOD: two-phase or factory
class Base {
public:
    explicit Base(int n) { /* ... */ }
    virtual void init() { /* ... */ }
};
```

## Destructor Rules

| Rule | Guideline |
|------|-----------|
| C.30 | Define destructor only if class manages a resource |
| C.35 | Base class destructor: public+virtual or protected+non-virtual |
| C.36 | Destructor must not fail |
| C.37 | Destructor must be `noexcept` |
| C.127 | Class with virtual function needs virtual/protected destructor |

## Virtual Functions

| Rule | Guideline |
|------|-----------|
| C.128 | Specify exactly one of: `virtual`, `override`, `final` |
| C.129 | Use `override` when overriding — compiler catches mismatches |
| C.130 | Redefine or prohibit copying for polymorphic classes |
| C.131 | Avoid trivial getters/setters |
| C.132 | Don't make functions virtual without reason |
| C.133 | Avoid protected data |
| C.153 | Prefer virtual function to casting |

## Inheritance

```cpp
// C.135: MI for distinct interfaces
class InputDevice { /* ... */ };
class OutputDevice { /* ... */ };
class IODevice : public InputDevice, public OutputDevice { };

// C.136: MI for implementation union is a last resort
// Prefer composition over implementation inheritance

// C.138: using to expose base overloads
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

| Rule | Guideline |
|------|-----------|
| C.160 | Mimic conventional usage |
| C.161 | Symmetric operators: non-member |
| C.162 | Overload only for operations roughly equivalent to built-in |
| C.164 | Avoid implicit conversion operators |
| C.86 | `==` must be symmetric and `noexcept` |
| C.85 | `swap` must be `noexcept` |

```cpp
// C.161: symmetric operator as non-member
class Rational {
    int num_, den_;
public:
    Rational(int n, int d);
};
Rational operator+(const Rational& a, const Rational& b);  // Non-member
Rational operator*(const Rational& a, const Rational& b);

// Enables: Rational(1,2) + 1 and 1 + Rational(1,2)
```

## Anti-Patterns

```cpp
// BAD: slicing
void process(Base b) { }   // Takes by value — slices derived
Derived d;
process(d);                // d is sliced to Base

// GOOD: pass by reference
void process(Base& b) { }
process(d);                // No slicing

// BAD: public data in class with invariant
class Date { public: int year, month, day; };  // No way to enforce invariant

// GOOD: private data with accessors
class Date {
    int year_, month_, day_;
public:
    void set_month(int m);  // Can validate 1-12
};
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-special-member-functions` | C.21 |
| `cppcoreguidelines-virtual-class-destructor` | C.35, C.127 |
| `cppcoreguidelines-slicing` | ES.63 |
| `cppcoreguidelines-avoid-const-or-ref-data-members` | C.12 |
| `cppcoreguidelines-prefer-member-initializer` | C.49 |
| `modernize-use-override` | C.128 |
| `modernize-use-equals-default` | C.80 |
| `modernize-use-equals-delete` | C.81 |
| `modernize-use-default-member-init` | C.48 |
| `misc-explicit-constructor` | C.46 |
| `performance-noexcept-move-constructor` | C.66 |
| `performance-noexcept-destructor` | C.37 |
| `performance-noexcept-swap` | C.85 |

## Cross-References

- For RAII and resource management: load `resource-management`
- For error handling in constructors/destructors: load `error-handling`
- For const member functions: load `constants`
- For clang-tidy configuration: load `clang-tidy`
