---
name: cpp-error-handling
description: C++ Core Guidelines E section: Error handling. Use when designing exception strategies, implementing noexcept functions, RAII error safety, or catch clause ordering.
---

# C++ Error Handling (E Section)

Exception-based error handling with RAII safety.

## Core Strategy

1. **Develop error strategy early** (E.1)
2. **Throw when function cannot perform task** (E.2)
3. **Exceptions for errors only, not control flow** (E.3)
4. **Design around invariants** (E.4)

## Exception Rules

| Rule | Guideline |
|------|-----------|
| Throw by value | E.15 |
| Catch by reference | E.15 |
| Use UDTs, not built-ins | E.14 |
| Order catch clauses: derived first | E.31 |
| Minimize explicit try/catch | E.18 |
| Don't catch every exception everywhere | E.17 |

## Noexcept

- **Declare `noexcept`** when throw is impossible or unacceptable (E.12, F.6)
- **Destructors must be `noexcept`** (C.37)
- **Move operations must be `noexcept`** (C.66)
- **Never throw while owning an object** (E.13) -- use RAII

## RAII for Error Safety

```cpp
// BAD: manual cleanup on error
void f() {
    auto p = new Buffer();
    process(p);  // might throw
    delete p;    // unreachable on throw
}

// GOOD: RAII
void f() {
    Buffer b;     // or unique_ptr<Buffer>
    process(&b);  // if this throws, ~Buffer runs
}
```

## No-Exception Alternative

When exceptions are unavailable:

1. **Simulate RAII** (E.25): manual cleanup with structured error codes
2. **Fail fast** (E.26): `abort()` on unrecoverable error
3. **Systematic error codes** (E.27): consistent return convention
4. **No global errno** (E.28)

## Anti-Patterns

```cpp
// BAD: throw built-in type
throw 42;
throw "error";

// GOOD: UDT
throw runtime_error{"error message"};

// BAD: catch by value
catch (exception e) {}

// GOOD: catch by reference
catch (const exception& e) {}

// BAD: exception spec
void f() throw(int, char*); // deprecated

// GOOD: noexcept
void f() noexcept;

// BAD: throw in destructor
~Widget() { throw runtime_error{"cleanup failed"}; }

// GOOD: swallow or abort in destructor
~Widget() noexcept {
    try { cleanup(); }
    catch (...) { /* log */ }
}
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

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
