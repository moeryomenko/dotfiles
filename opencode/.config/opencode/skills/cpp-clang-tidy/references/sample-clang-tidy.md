# Sample .clang-tidy Configurations

Ready-to-use `.clang-tidy` configurations for different project profiles.

## Profile: Strict Core Guidelines (Recommended for new projects)

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
    -readability-function-size,
    -bugprone-easily-swappable-parameters
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
CheckOptions:
    - key: readability-function-size.FunctionLineThreshold
      value: '100'
    - key: readability-function-size.CommentLineThreshold
      value: '50'
FormatStyle: LLVM
---
```

## Profile: Modernization (Legacy code upgrade)

```yaml
---
Checks: >
    -*,
    modernize-*,
    -modernize-use-trailing-return-type,
    -modernize-use-auto,
    -modernize-use-concepts
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

## Profile: Safety (Bug-prone patterns only)

```yaml
---
Checks: >
    -*,
    bugprone-*,
    -bugprone-easily-swappable-parameters
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

## Profile: Performance

```yaml
---
Checks: >
    -*,
    performance-*,
    cppcoreguidelines-owning-memory,
    cppcoreguidelines-no-malloc
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

## Profile: Concurrency

```yaml
---
Checks: >
    -*,
    concurrency-*,
    bugprone-bad-signal-to-kill-thread,
    bugprone-spuriously-wake-up-functions,
    cppcoreguidelines-no-suspend-with-lock,
    cppcoreguidelines-avoid-capturing-lambda-coroutines
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

## Profile: Minimal (Quick check)

```yaml
---
Checks: >
    -*,
    bugprone-*,
    cppcoreguidelines-owning-memory,
    cppcoreguidelines-virtual-class-destructor,
    cppcoreguidelines-no-malloc,
    modernize-use-nullptr,
    modernize-use-override,
    modernize-use-equals-default,
    modernize-use-equals-delete
WarningsAsErrors: ''
FormatStyle: LLVM
---
```

## Common CheckOptions

```yaml
CheckOptions:
    # Allow longer functions
    - key: readability-function-size.FunctionLineThreshold
      value: '150'
    # Ignore specific magic numbers
    - key: readability-magic-numbers.IgnoreHexLiteral
      value: '1'
    - key: readability-magic-numbers.IgnoreBytewiseImportantLiteral
      value: '1'
    # Custom naming convention
    - key: readability-identifier-naming.LongCase
      value: 'camelCase'
    - key: readability-identifier-naming.ShortCase
      value: 'camelCase'
```

## CI Integration

### GitHub Actions

```yaml
- name: clang-tidy
  run: |
    clang-tidy --fix src/**/*.cpp --format-style LLVM
```

### CMake

```cmake
set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=.clang-tidy")
```

### Compile Commands

Ensure `compile_commands.json` exists (CMake generates it with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`).
