---
name: cmake-modularize
description: Split monolithic CMakeLists.txt into modular, maintainable CMake scripts. Covers extracting components into cmake/ modules, managing include order, and keeping the root CMakeLists.txt as a thin orchestrator. Use when a root CMakeLists.txt exceeds 200 lines or contains clearly separable concerns.
when_to_use: "When the root CMakeLists.txt has grown unwieldy (300+ lines), contains clearly separable concerns (tooling/install/platform checks), or a new contributor needs to understand the build quickly. NOT for new projects with <100 lines of CMake."
allowed-tools: Read, Write, Bash, Grep, Glob
effort: medium
---

# CMake Modularize — Splitting the Monolithic CMakeLists.txt

> A CMakeLists.txt with 500 lines is an accident waiting to happen. Extract modules by concern, keep the root as a thin conductor.

---

## Modularization Strategy

```
CMakeLists.txt          ← 80 lines: project(), options, add_subdirectory()
cmake/
  options.cmake         ← Option declarations and early configuration
  compiler-flags.cmake  ← Compiler-specific flags (GNU/Clang/MSVC)
  modules-support.cmake ← C++ modules detection and setup
  dependencies.cmake    ← find_package(), FetchContent()
  tooling.cmake         ← format, lint, docs custom targets
  install.cmake         ← install(), export(), CPack
```

Each module:
- Is included via `include(cmake/<module>.cmake)` from root CMakeLists.txt
- Receives variables set before it (options, compiler detection)
- Sets variables for modules included after it (if needed)
- Has a clear single responsibility

---

## Root CMakeLists.txt (Thin Orchestrator)

```cmake
cmake_minimum_required(VERSION 3.23)
project(${PROJECT_NAME} VERSION 1.0.0 LANGUAGES CXX)

# === Project-wide settings ===
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# === Options ===
include(cmake/options)

# === Compiler configuration ===
include(cmake/compiler-flags)

# === Dependencies ===
include(cmake/dependencies)

# === Main library target ===
include(cmake/modules-support)   # conditionally sets up C++ modules
include(cmake/main-target)      # add_library(...)

# === Subdirectories ===
if(BUILD_EXAMPLES)
  add_subdirectory(examples)
endif()
if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()

# === Tooling (optional) ===
include(cmake/tooling)

# === Install (optional) ===
include(cmake/install)

# === Summary ===
include(cmake/summary)
```

---

## Module Patterns

### `cmake/options.cmake` — All Options in One Place

```cmake
# Options
option(BUILD_EXAMPLES "Build example applications" ON)
option(BUILD_TESTS "Build test suite" ON)
option(INSTALL "Generate install target" ON)
option(USE_MODULES "Use C++23 modules if available" OFF)
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)

# Guard for modules
if(USE_MODULES AND CMAKE_VERSION VERSION_LESS "3.28")
  message(FATAL_ERROR "C++23 modules require CMake 3.28+, got ${CMAKE_VERSION}")
endif()
```

### `cmake/compiler-flags.cmake` — Platform-First Isolation

```cmake
# This module is included after the library target exists

function(_set_compile_opts scope target)
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(${target} ${scope}
      -Wall -Wextra -Wpedantic
      $<$<CONFIG:Debug>:-g -O0>
      $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
  elseif(MSVC)
    target_compile_options(${target} ${scope}
      /W4 /permissive-
      $<$<CONFIG:Debug>:/Od /Zi>
      $<$<CONFIG:Release>:/O2 /DNDEBUG>
    )
  endif()
endfunction()

if(USE_MODULES)
  _set_compile_opts(PUBLIC ${PROJECT_NAME})
else()
  _set_compile_opts(INTERFACE ${PROJECT_NAME})
endif()
```

### `cmake/dependencies.cmake` — All External Dependencies

```cmake
include(CMakePackageConfigHelpers)

find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME} Threads::Threads)
```

### `cmake/main-target.cmake` — Library Target Definition

```cmake
# This module defines the main library target.
# It must be included after dependencies (find_package has populated targets)
# and before subdirectories (examples/tests need the library to exist).

add_library(${PROJECT_NAME})

# Header-only library pattern (no source files)
target_sources(${PROJECT_NAME}
  INTERFACE
    FILE_SET CXX_MODULES
    BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
    FILES
    include/${PROJECT_NAME}/core.hpp
)

# Use generator expressions for dual-use include dirs (build tree + install)
target_include_directories(${PROJECT_NAME}
  INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

# Link public dependencies from dependencies.cmake
target_link_libraries(${PROJECT_NAME}
  INTERFACE
    Threads::Threads
)
```

### `cmake/tooling.cmake` — Optional Tool Discovery

```cmake
# Include only if BUILD_TOOLING is ON (default from options)
if(NOT BUILD_TOOLING)
  return()
endif()

# Helper macro for consistent source lists
macro(_collect_sources out_var)
  set(${out_var})
  foreach(_dir ${ARGN})
    file(GLOB_RECURSE _files ${_dir}/*.hpp ${_dir}/*.cpp)
    list(APPEND ${out_var} ${_files})
  endforeach()
endmacro()

_collect_sources(ALL_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/examples
  ${CMAKE_CURRENT_SOURCE_DIR}/tests
)

# --- clang-format ---
find_program(CLANG_FORMAT_EXECUTABLE NAMES clang-format)
if(CLANG_FORMAT_EXECUTABLE)
  add_custom_target(format ...)
  add_custom_target(format-check ...)
endif()

# --- clang-tidy ---
find_program(CLANG_TIDY_EXECUTABLE NAMES clang-tidy)
if(CLANG_TIDY_EXECUTABLE)
  add_custom_target(lint ...)
  add_custom_target(lint-fix ...)
endif()

# --- Doxygen ---
find_program(DOXYGEN_EXECUTABLE NAMES doxygen)
if(DOXYGEN_EXECUTABLE)
  add_custom_target(docs ...)
endif()
```

### `cmake/summary.cmake` — Configuration Summary

```cmake
message(STATUS "")
message(STATUS "${PROJECT_NAME} configuration summary:")
message(STATUS "  Version:              ${PROJECT_VERSION}")
message(STATUS "  C++ Standard:         ${CMAKE_CXX_STANDARD}")
message(STATUS "  Build type:           ${CMAKE_BUILD_TYPE}")
message(STATUS "  Build examples:       ${BUILD_EXAMPLES}")
message(STATUS "  Build tests:          ${BUILD_TESTS}")
message(STATUS "  Install:              ${INSTALL}")
message(STATUS "  Use C++ modules:      ${USE_MODULES}")
message(STATUS "  Compiler:             ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "")
```

---

## When to Modularize

| Symptom | Trigger |
|---|---|
| Root CMakeLists.txt > 300 lines | Extract immediately |
| Multiple `if()...elseif()...endif()` blocks for the same concern | Group into one module |
| `option()` declarations scattered through the file | Centralize in options.cmake |
| Platform-specific compiler logic interleaved with library logic | Extract to compiler-flags.cmake |
| Tooling targets take >50 lines | Extract to tooling.cmake |
| Install logic spans >80 lines | Extract to install.cmake |
| The build summary is hard to find | Extract to summary.cmake |

---

## Module Include Order Rules

1. **Options first** — all `option()` and early validation
2. **Dependencies** — `find_package()`, `FetchContent()`
3. **Main target** — `add_library()` must exist before subdirectories
4. **Subdirectories** — examples, tests
5. **Tooling** — optional, can be skipped for CI speed
6. **Install** — optional, can be skipped for development builds
7. **Summary** — always last

---

## Verification Checklist

- [ ] Root CMakeLists.txt is < 100 lines (or significantly reduced)
- [ ] Each cmake module has a single clear responsibility
- [ ] All modules are in `cmake/` subdirectory
- [ ] `cmake --preset default` configures without errors
- [ ] `cmake --build --preset default` compiles all targets
- [ ] All existing options, targets, and install behavior preserved
- [ ] Each module is independently readable (no cross-module surprises)
- [ ] New contributor can understand the build flow from root CMakeLists.txt
- [ ] LLM agents (or new devs) can find specific logic without reading the entire build file
