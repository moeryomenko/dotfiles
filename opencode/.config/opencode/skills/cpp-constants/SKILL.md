---
name: cpp-constants
description: C++ Core Guidelines Con section: Constants and immutability. Use when applying const correctness, using constexpr, or configuring clang-tidy for const-related rules.
---

# C++ Constants and Immutability (Con Section)

Guidelines for `const` correctness and compile-time computation.

## Rules

| Rule | Guideline |
|------|-----------|
| Con.1 | By default, make objects immutable |
| Con.2 | By default, make member functions `const` |
| Con.3 | By default, pass pointers/references to `const` |
| Con.4 | Use `const` for values that don't change after construction |
| Con.5 | Use `constexpr` for compile-time computable values |

## Const Correctness

```cpp
// BAD: mutable default
string name;
void update();

// GOOD: const default
const string name;
void update() const;  // member function doesn't modify state

// BAD: non-const parameter
void print(string s);  // unnecessary copy

// GOOD: const reference
void print(const string& s);

// BAD: non-const pointer
void process(int* data);

// GOOD: const pointer
void process(const int* data);
```

## Constexpr

```cpp
// BAD: runtime computation of constant
int buffer_size = 1024;

// GOOD: constexpr
constexpr int BufferSize = 1024;

// GOOD: constexpr function
constexpr int square(int x) { return x * x; }
constexpr int s = square(5);  // computed at compile time
```

## Anti-Patterns

```cpp
// BAD: const in wrong place
const string* p;  // pointer to const string

// GOOD: const pointer
string* const p;  // const pointer to string

// BAD: non-const getter
string name() { return name_; }

// GOOD: const getter
string name() const { return name_; }
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `misc-const-correctness` | Con.1-3 |
| `readability-make-member-function-const` | Con.2 |
| `readability-const-return-type` | F.49 |
| `misc-misplaced-const` | Con.1 |
