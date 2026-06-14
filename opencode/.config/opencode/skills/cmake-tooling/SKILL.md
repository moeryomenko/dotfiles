---
name: cmake-tooling
description: Configure CMake custom targets for formatting, linting, documentation, and pre-commit hooks. Covers clang-format, clang-tidy, Doxygen, include-what-you-use, sanitizers, and CTest configuration. Use when adding code quality tooling to a CMake project.
when_to_use: "When setting up code quality tooling (formatters, linters, documentation generators), adding sanitizer configurations, configuring CTest output behavior, creating pre-commit check targets, or replacing fragile GLOB_RECURSE patterns in custom targets."
allowed-tools: Read, Write, Bash, Grep, Glob
effort: medium
---

# CMake Tooling — Format, Lint, Docs & Pre-Commit

> Code quality tooling should be a single `cmake --build` invocation away. If it requires hunting through AGENTS.md, nobody runs it.

---

## Custom Target Principles

1. **Make it discoverable** — `cmake --build _build --target help` should show all tooling targets
2. **Graceful degradation** — If a tool is not installed, either skip the target or give a clear install hint
3. **No GLOB_RECURSE in tool targets** — Source lists should be explicit or use a CMake source file variable

---

## Formatting (clang-format)

### Robust Source File Collection

Instead of `file(GLOB_RECURSE ...)` which misses new files:

```cmake
# Option A: Explicit file list (maintainable for smaller projects)
set(FORMAT_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/include/project/header.hpp
    # ....every file....
)

# Option B: Use a helper to regenerate the list without GLOB pitfalls
set(FORMAT_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/examples
    ${CMAKE_CURRENT_SOURCE_DIR}/tests
)

# Option C: Accept GLOB but warn at configure time
file(GLOB_RECURSE FORMAT_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp
)
```

### Format and Format-Check Targets

```cmake
find_program(CLANG_FORMAT_EXECUTABLE NAMES clang-format)
if(CLANG_FORMAT_EXECUTABLE)
  # Apply formatting in-place
  add_custom_target(format
    COMMAND ${CLANG_FORMAT_EXECUTABLE} -i -style=file ${FORMAT_SOURCES}
    COMMENT "Running clang-format (in-place)"
    VERBATIM
  )

  # Check formatting without modifying (for CI)
  add_custom_target(format-check
    COMMAND ${CLANG_FORMAT_EXECUTABLE} -n -style=file --Werror ${FORMAT_SOURCES}
    COMMENT "Checking clang-format compliance"
    VERBATIM
  )
endif()
```

---

## Linting (clang-tidy)

```cmake
find_program(CLANG_TIDY_EXECUTABLE NAMES clang-tidy)
if(CLANG_TIDY_EXECUTABLE)
  add_custom_target(lint
    COMMAND ${CLANG_TIDY_EXECUTABLE}
            -p ${CMAKE_CURRENT_BINARY_DIR}
            ${LINT_SOURCES}
            -- -std=c++23 -I${CMAKE_CURRENT_SOURCE_DIR}/include
    COMMENT "Running clang-tidy"
    VERBATIM
  )

  add_custom_target(lint-fix
    COMMAND ${CLANG_TIDY_EXECUTABLE}
            -p ${CMAKE_CURRENT_BINARY_DIR}
            -fix
            ${LINT_SOURCES}
            -- -std=c++23 -I${CMAKE_CURRENT_SOURCE_DIR}/include
    COMMENT "Running clang-tidy with auto-fix"
    VERBATIM
  )
endif()
```

### Better Approach: Use CMAKE_CXX_CLANG_TIDY

For per-file linting during build (catches issues early):

```cmake
if(CLANG_TIDY_EXECUTABLE)
  set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXECUTABLE}"
      "--extra-arg=-std=c++23"
      "--extra-arg=-I${CMAKE_CURRENT_SOURCE_DIR}/include"
  )
endif()
```

---

## Documentation (Doxygen)

```cmake
find_program(DOXYGEN_EXECUTABLE NAMES doxygen)
if(DOXYGEN_EXECUTABLE AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile)
  add_custom_target(docs
    COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating API documentation with Doxygen"
    VERBATIM
  )

  # Clean docs
  add_custom_target(docs-clean
    COMMAND ${CMAKE_COMMAND} -E remove_directory
            ${CMAKE_CURRENT_BINARY_DIR}/html
    COMMENT "Removing generated documentation"
  )
endif()
```

---

## Pre-Commit Target

Combine all checks into a single target for CI and pre-commit hooks:

```cmake
add_custom_target(pre-commit
  COMMAND ${CMAKE_MAKE_PROGRAM} format-check
  COMMAND ${CMAKE_MAKE_PROGRAM} lint
  COMMAND ${CMAKE_MAKE_PROGRAM} docs 2>/dev/null || true
  COMMENT "Running pre-commit checks (format + lint)"
  VERBATIM
)
```

---

## Sanitizers (Debug builds)

```cmake
# In the configure preset or CMakeLists.txt
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)

if(ENABLE_ASAN AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(${PROJECT_NAME} INTERFACE -fsanitize=address -fno-omit-frame-pointer)
  target_link_options(${PROJECT_NAME} INTERFACE -fsanitize=address)
endif()

if(ENABLE_UBSAN AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(${PROJECT_NAME} INTERFACE -fsanitize=undefined)
  target_link_options(${PROJECT_NAME} INTERFACE -fsanitize=undefined)
endif()
```

---

## CTest Configuration

Instead of minimal `enable_testing()`:

```cmake
enable_testing()

# In root CMakeLists.txt
set(CTEST_OUTPUT_ON_FAILURE TRUE PARENT_SCOPE)
set(CTEST_TEST_TIMEOUT 60)

# Per-test configuration in tests/CMakeLists.txt
include(GoogleTest)  # if using GTest

foreach(TEST_SOURCE ${TEST_SOURCES})
  get_filename_component(TEST_NAME ${TEST_SOURCE} NAME_WE)
  add_executable(${TEST_NAME} ${TEST_SOURCE})
  target_link_libraries(${TEST_NAME} PRIVATE ${PROJECT_NAME}::${PROJECT_NAME})

  add_test(
    NAME ${TEST_NAME}
    COMMAND ${TEST_NAME}
    CONFIGURATIONS Debug Release
  )

  # Set per-test timeout
  set_tests_properties(${TEST_NAME} PROPERTIES TIMEOUT 30)

  # Label tests for subset runs
  set_tests_properties(${TEST_NAME} PROPERTIES LABELS "unit")
endforeach()
```

### Test Filtering by Label

```cmake
# In the test file or CMake
add_test(NAME io_uring_test COMMAND ...)
set_tests_properties(io_uring_test PROPERTIES LABELS "io_uring")

add_test(NAME scheduler_test COMMAND ...)
set_tests_properties(scheduler_test PROPERTIES LABELS "core")
```

Then run filtered:
```bash
ctest --preset default -L core
ctest --preset default -L io_uring -LE slow
```

---

## Summary: Tooling Target Naming Convention

| Target | Tool | CI Gate |
|---|---|---|
| `format` | clang-format (in-place) | No |
| `format-check` | clang-format (check only) | Yes |
| `lint` | clang-tidy | Yes |
| `lint-fix` | clang-tidy with auto-fix | No |
| `docs` | Doxygen | No |
| `pre-commit` | format-check + lint | Yes |

---

## Verification Checklist

- [ ] `format` target runs clang-format without errors
- [ ] `format-check` target exits non-zero on unformatted code
- [ ] `lint` target finds violations (or passes)
- [ ] `pre-commit` runs all checks sequentially
- [ ] Sanitizer builds work (compile and run tests)
- [ ] `ctest --output-on-failure` shows test output
- [ ] Test labels work for filtering
- [ ] Missing tools produce a clear message (not a cryptic error)
- [ ] New source files added to project appear in format/lint targets without reconfiguration (if using non-GLOB approach)
