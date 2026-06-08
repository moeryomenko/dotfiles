---
name: cpp-resource-management
description: C++ Core Guidelines R section: Resource management. Use when implementing RAII, choosing smart pointers, managing ownership, or avoiding raw new/delete.
---

# C++ Resource Management (R Section)

Resource management through RAII and smart pointers.

## Core Principle

**Manage resources automatically using RAII** (R.1). Every resource acquisition must be immediately wrapped in a handle object whose destructor releases the resource.

## Ownership Rules

| Type | Ownership | Rule |
|------|-----------|------|
| `T*` | Non-owning (observer) | R.3 |
| `T&` | Non-owning (observer) | R.4 |
| `unique_ptr<T>` | Exclusive ownership | R.20, R.21 |
| `shared_ptr<T>` | Shared ownership | R.20 |
| `weak_ptr<T>` | Non-owning, breaks cycles | R.24 |

## Smart Pointer Selection

1. **Default**: `unique_ptr` (R.21)
2. **Need sharing**: `shared_ptr` (R.20)
3. **Break cycles**: `weak_ptr` (R.24)
4. **Never**: raw `new`/`delete` (R.11)

## Construction

```cpp
// BAD: naked new
auto p = new Widget();

// GOOD: make_unique
auto p = make_unique<Widget>();     // R.23

// BAD: naked new with shared_ptr
auto sp = shared_ptr<Widget>(new Widget());

// GOOD: make_shared
auto sp = make_shared<Widget>();    // R.22
```

## Parameter Semantics

| Parameter | Meaning | Rule |
|-----------|---------|------|
| `unique_ptr<W>` | Function takes ownership | R.32 |
| `unique_ptr<W>&` | Function may reseat | R.33 |
| `shared_ptr<W>` | Function shares ownership | R.34 |
| `shared_ptr<W>&` | Function may reseat | R.35 |
| `const shared_ptr<W>&` | Function may retain ref | R.36 |
| `T*` / `T&` | General use, no ownership | R.2, F.7 |

## Anti-Patterns

```cpp
// BAD: raw new/delete
void f() {
    int* p = new int[100];
    // ... risk of leak
    delete[] p;
}

// GOOD: RAII
void f() {
    vector<int> v(100);
    // automatic cleanup
}

// BAD: malloc/free
void* p = malloc(100);
free(p);

// GOOD: smart pointer or container
auto p = make_unique<byte[]>(100);

// BAD: shared_ptr to array
shared_ptr<int> p(new int[10]);

// GOOD: unique_ptr for arrays
unique_ptr<int[]> p(new int[10]);
// or better: vector<int> p(10);
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `cppcoreguidelines-owning-memory` | R.20, R.3 |
| `cppcoreguidelines-no-malloc` | R.10 |
| `modernize-make-unique` | R.23 |
| `modernize-make-shared` | R.22 |
| `modernize-replace-auto-ptr` | R.20 |
| `bugprone-unused-raii` | R.1 |
| `bugprone-unused-local-non-trivial-variable` | R.1 |
| `bugprone-shared-ptr-array-mismatch` | R.20 |
| `bugprone-unique-ptr-array-mismatch` | R.20 |
| `bugprone-multiple-new-in-one-expression` | R.13 |
| `readability-redundant-smartptr-get` | R.20 |
| `misc-uniqueptr-reset-release` | R.20 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
