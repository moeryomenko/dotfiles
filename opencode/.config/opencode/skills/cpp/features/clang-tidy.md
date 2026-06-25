# C++ Clang-Tidy Configuration

Configure clang-tidy to enforce C++ Core Guidelines and best practices.

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
    -modernize-use-auto,
    -readability-identifier-length
WarningsAsErrors: ''
FormatStyle: file
---
```

Run: `clang-tidy --fix src/**/*.cpp`

## Core Principles

- **Enable by group**: Use `cppcoreguidelines-*`, `bugprone-*`, `modernize-*` rather than individual checks. Groups catch more issues and auto-update as new checks are added.
- **Suppress selectively**: Use `// NOLINTNEXTLINE(check-id)` for justified exceptions, never blanket suppress entire files.
- **Auto-fix first**: Run `--fix` to apply safe fixes automatically, then review remaining warnings.
- **CI gate**: Block merges on new `bugprone-*` or `cppcoreguidelines-*` violations. Use `clang-tidy-diff` to only check changed lines.
- **Incremental adoption**: Start with `bugprone-*` and `performance-*` for immediate value, then add `cppcoreguidelines-*` once the codebase is clean.

## Checker Groups

### Core Guidelines

| Check | Rule | Auto-fix |
|-------|------|----------|
| `cppcoreguidelines-*` | All Core Guidelines | Partial |
| `cppcoreguidelines-avoid-goto` | ES.76 | No |
| `cppcoreguidelines-avoid-capturing-lambda-coroutines` | CP.51 | No |
| `cppcoreguidelines-avoid-const-or-ref-data-members` | C.12 | No |
| `cppcoreguidelines-avoid-do-while` | ES.75 | No |
| `cppcoreguidelines-avoid-non-const-global-variables` | I.2 | No |
| `cppcoreguidelines-avoid-reference-coroutine-parameters` | CP.53 | No |
| `cppcoreguidelines-init-variables` | ES.20 | Yes |
| `cppcoreguidelines-interfaces-global-init` | I.22 | No |
| `cppcoreguidelines-macro-usage` | ES.30-33 | No |
| `cppcoreguidelines-misleading-capture-default-by-value` | F.54 | No |
| `cppcoreguidelines-missing-std-forward` | F.19 | No |
| `cppcoreguidelines-no-malloc` | R.10 | Yes |
| `cppcoreguidelines-no-suspend-with-lock` | CP.52 | No |
| `cppcoreguidelines-owning-memory` | R.20 | No |
| `cppcoreguidelines-prefer-member-initializer` | C.49 | Yes |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | I.13 | No |
| `cppcoreguidelines-pro-bounds-constant-array-index` | ES.55 | No |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | ES.42 | No |
| `cppcoreguidelines-pro-type-const-cast` | ES.50 | No |
| `cppcoreguidelines-pro-type-cstyle-cast` | ES.48-49 | Yes |
| `cppcoreguidelines-pro-type-reinterpret-cast` | ES.48 | No |
| `cppcoreguidelines-pro-type-union-access` | C.181 | No |
| `cppcoreguidelines-pro-type-vararg` | ES.34 / F.55 | No |
| `cppcoreguidelines-rvalue-reference-param-not-moved` | F.18 | No |
| `cppcoreguidelines-slicing` | ES.63 | No |
| `cppcoreguidelines-special-member-functions` | C.21 | No |
| `cppcoreguidelines-use-enum-class` | Enum.3 | No |
| `cppcoreguidelines-virtual-class-destructor` | C.35 / C.127 | No |

### Bug Prone

| Check | Auto-fix |
|-------|----------|
| `bugprone-*` | Partial |
| `bugprone-empty-catch` | No |
| `bugprone-exception-escape` | No |
| `bugprone-multiple-new-in-one-expression` | No |
| `bugprone-narrowing-conversions` | No |
| `bugprone-reserved-identifier` | Yes |
| `bugprone-shared-ptr-array-mismatch` | No |
| `bugprone-signal-to-kill-thread` | No |
| `bugprone-signed-bitwise` | No |
| `bugprone-spuriously-wake-up-functions` | No |
| `bugprone-throw-keyword-missing` | No |
| `bugprone-unique-ptr-array-mismatch` | No |
| `bugprone-unused-raii` | No |
| `bugprone-easily-swappable-parameters` | No |
| `bugprone-incorrect-enable-if` | No |
| `bugprone-no-escape` | No |
| `bugprone-std-namespace-modification` | No |
| `bugprone-throwing-static-initialization` | No |
| `bugprone-unused-local-non-trivial-variable` | No |

### Modernize

| Check | Auto-fix |
|-------|----------|
| `modernize-*` | Extensive |
| `modernize-avoid-c-arrays` | Yes |
| `modernize-avoid-bind` | Yes |
| `modernize-avoid-c-style-cast` | Yes |
| `modernize-loop-convert` | Yes |
| `modernize-macro-to-enum` | Yes |
| `modernize-make-shared` | Yes |
| `modernize-make-unique` | Yes |
| `modernize-pass-by-value` | Yes |
| `modernize-replace-auto-ptr` | Yes |
| `modernize-use-auto` | Yes |
| `modernize-use-concepts` | No |
| `modernize-use-constraints` | No |
| `modernize-use-default-member-init` | Yes |
| `modernize-use-equals-default` | Yes |
| `modernize-use-equals-delete` | Yes |
| `modernize-use-noexcept` | Yes |
| `modernize-use-nullptr` | Yes |
| `modernize-use-override` | Yes |
| `modernize-use-scoped-lock` | Yes |
| `modernize-use-using` | Yes |
| `modernize-concat-nested-namespaces` | Yes |

### Performance

| Check | Auto-fix |
|-------|----------|
| `performance-*` | Partial |
| `performance-avoid-endl` | Yes |
| `performance-for-range-copy` | No |
| `performance-inefficient-algorithm` | No |
| `performance-inefficient-string-concatenation` | Yes |
| `performance-inefficient-vector-operation` | Yes |
| `performance-move-const-arg` | Yes |
| `performance-move-constructor-init` | Yes |
| `performance-no-automatic-move` | No |
| `performance-noexcept-destructor` | No |
| `performance-noexcept-move-constructor` | No |
| `performance-noexcept-swap` | No |
| `performance-trivially-destructible` | Yes |
| `performance-type-promotion-in-math-fn` | No |
| `performance-unnecessary-copy-initialization` | No |
| `performance-unnecessary-value-param` | No |
| `performance-use-std-move` | Yes |

## Suppression Patterns

```cpp
// Single line: place at end of the line to suppress
int x = reinterpret_cast<int>(ptr); // NOLINT(cppcoreguidelines-pro-type-reinterpret-cast)

// Next line: place before the line to suppress
// NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
printf("%d", x);

// Block: suppresses for all lines between NOLINTBEGIN/NOLINTEND
// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg, cppcoreguidelines-pro-type-reinterpret-cast)
void legacy_api(const char* fmt, ...) {
    long addr = (long)&fmt;
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg, cppcoreguidelines-pro-type-reinterpret-cast)
```

## CI Integration

### clang-tidy-diff for Changed Lines

```bash
git diff origin/main...HEAD | clang-tidy-diff -p1 -path build/ |
    grep -E '(warning|error):' > clang-tidy-report.txt
```

### CMake Integration

```cmake
# Enable in CMakePresets.json or CMakeLists.txt
set(CMAKE_CXX_CLANG_TIDY
    "clang-tidy;--checks=-*,bugprone-*,cppcoreguidelines-*;--warnings-as-errors=*")
```

## Incremental Adoption Strategy

1. **Week 1**: Enable `bugprone-*` and `performance-*`. Fix all warnings. These catch real bugs and slow code.
2. **Week 2**: Enable `modernize-*` (excluding controversial ones like `modernize-use-auto`). Run `--fix` for automated migration.
3. **Week 3**: Enable `readability-*` (excluding style preferences). Review each category.
4. **Week 4**: Enable `cppcoreguidelines-*`. Start with `init-variables`, `no-malloc`, `slicing`, `special-member-functions`. Add more as the codebase stabilizes.
5. **Ongoing**: Add `concurrency-*` and `cert-*` based on project needs.

## References

- For section-specific rules and their clang-tidy mappings, load the domain feature (e.g., `features/functions.md` for F section checks)
