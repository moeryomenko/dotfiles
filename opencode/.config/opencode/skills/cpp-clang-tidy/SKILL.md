---
name: cpp-clang-tidy
description: Configure clang-tidy for C++ Core Guidelines compliance. Use when setting up .clang-tidy, selecting checkers, suppressing warnings, integrating clang-tidy into CI, or mapping Core Guidelines rules to clang-tidy checks.
---

# C++ Clang-Tidy Configuration

Configure clang-tidy to enforce C++ Core Guidelines. See [checker-catalog.md](references/checker-catalog.md) for the complete checker list organized by guideline section, and [sample-clang-tidy.md](references/sample-clang-tidy.md) for ready-to-use configurations.

## Quick Start

Create `.clang-tidy` at project root:

```yaml
---
Checks: >
    -*,
    cppcoreguidelines-*,
    bugprone-*,
    modernize-*,
    performance-*,
    readability-*,
    -modernize-use-trailing-return-type,
    -modernize-use-auto
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

Run: `clang-tidy --fix src/**/*.cpp`

## Core Principles

- **Enable by group**: Use `cppcoreguidelines-*`, `bugprone-*`, `modernize-*` rather than individual checks
- **Suppress selectively**: Use `// NOLINTNEXTLINE(check-id)` for justified exceptions
- **Auto-fix first**: Run `--fix` to apply safe fixes, then review remaining warnings
- **CI gate**: Block merges on new `bugprone-*` or `cppcoreguidelines-*` violations

## Checker Groups

| Group | Purpose | Auto-fix |
|-------|---------|----------|
| `cppcoreguidelines-*` | Direct Core Guidelines enforcement | Partial |
| `bugprone-*` | Common bug patterns | Partial |
| `modernize-*` | C++11/14/17/20 upgrades | Extensive |
| `performance-*` | Performance anti-patterns | Partial |
| `readability-*` | Code clarity | Partial |
| `cert-*` | CERT C++ security rules | Partial |
| `concurrency-*` | Thread safety | None |

## Suppression

```cpp
// Single line suppression
int x = foo(); // NOLINT(modernize-use-auto)

// Next line suppression
int* p = reinterpret_cast<int*>(buf); // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)

// Block suppression
// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)
// legacy code block
// NOLINTEND(cppcoreguidelines-pro-type-vararg)
```

## References

- **Complete checker catalog**: [checker-catalog.md](references/checker-catalog.md)
- **Sample configurations**: [sample-clang-tidy.md](references/sample-clang-tidy.md)
