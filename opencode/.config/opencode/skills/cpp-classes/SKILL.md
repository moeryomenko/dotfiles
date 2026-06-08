---
name: cpp-classes
description: C++ Core Guidelines C section: Classes and class hierarchies. Use when designing classes, implementing constructors/destructors, copy/move semantics, virtual functions, inheritance, or operators.
---

# C++ Classes (C Section)

Guidelines for class design, special member functions, inheritance, and operators.

## Class Design

- **`struct`**: data aggregate, no invariant, all public (C.2, C.8)
- **`class`**: has invariant, encapsulated data (C.2, C.8)
- **Concrete types**: make regular (C.11)
- **Polymorphic types**: suppress public copy/move (C.67)

## Special Member Functions (Rule of All/Four/Zero)

If you define **any** of copy/move/destructor, define **all** (C.21):

```cpp
class Widget {
public:
    Widget() = default;                    // C.44: simple, non-throwing
    ~Widget() = default;                   // C.30: only if needed

    Widget(const Widget&) = default;       // C.61: must copy
    Widget& operator=(const Widget&) = default;  // C.60: non-virtual, const& param, non-const& return
    Widget(Widget&&) noexcept = default;   // C.64: leave source valid
    Widget& operator=(Widget&&) noexcept;  // C.63: non-virtual, && param
};
```

- **`=default`** when explicit about default semantics (C.80)
- **`=delete`** to disable (C.81)
- **Move operations must be `noexcept`** (C.66)
- **Self-assignment safety** (C.62, C.65)

## Constructor Rules

- **Establish invariant** (C.41)
- **Throw if cannot construct valid object** (C.42)
- **Prefer member initializers** (C.48): `int x = 0;` over constructor init list
- **Prefer initialization to assignment** (C.49)
- **Single-arg constructors: `explicit` by default** (C.46)
- **Don't call virtual functions in ctors/dtors** (C.82)

## Destructor Rules

- **Base class destructor**: public+virtual or protected+non-virtual (C.35)
- **Must not fail** (C.36)
- **Must be `noexcept`** (C.37)
- **Class with virtual function needs virtual/protected destructor** (C.127)

## Virtual Functions

- **Specify exactly one of**: `virtual`, `override`, `final` (C.128)
- **Don't make virtual without reason** (C.132)
- **Prefer virtual to casting** (C.153)
- **Abstract interface**: pure abstract class (C.121)

## Inheritance

- **MI for distinct interfaces** (C.135)
- **MI for implementation union** (C.136)
- **Avoid `protected` data** (C.133)
- **Same access level for all non-const data** (C.134)
- **`using` to expose base overloads** (C.138)
- **`final` sparingly** (C.139)

## Operators

- **Mimic conventional usage** (C.160)
- **Symmetric operators: non-member** (C.161)
- **Avoid implicit conversion operators** (C.164)
- **`==` must be symmetric + `noexcept`** (C.86)
- **`swap` must be `noexcept`** (C.85)

## Anti-Patterns

```cpp
// BAD: missing virtual destructor
class Base { virtual void foo(); }; // no ~Base()

// GOOD
class Base { virtual ~Base() = default; virtual void foo(); };

// BAD: non-explicit single-arg constructor
class Vec { Vec(int n); }; // implicit conversion from int

// GOOD
class Vec { explicit Vec(int n); };

// BAD: return std::move of local
Widget make() { return std::move(w); }

// GOOD: RVO
Widget make() { return w; }

// BAD: slicing
void f(Base b) { }
Derived d; f(d); // slice!

// GOOD
void f(const Base& b) { }
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
| `misc-non-copyable-objects` | C.11 |
| `performance-noexcept-move-constructor` | C.66 |
| `performance-noexcept-destructor` | C.37 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
