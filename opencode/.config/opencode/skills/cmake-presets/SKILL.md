---
name: cmake-presets
description: Create and manage CMakePresets.json for reproducible build configurations. Supports configurePresets, buildPresets, testPresets, and IDE integration. Use when setting up a new project's build workflow or standardizing developer build commands.
when_to_use: "When setting up CMake build workflows, standardizing developer builds, adding CI presets, eliminating manual configure command copy-paste, or when CMakePresets.json is missing from a project using CMake. NOT for editing CMakeLists.txt directly."
allowed-tools: Read, Write, Bash, Grep, Glob
effort: low
---

# CMake Presets — Reproducible Build Configurations

> CMakePresets.json encodes the "correct build command" so developers never need to remember compiler flags, generator choices, or cache variable incantations.

## Overview

CMakePresets.json lives at the project root and supports three preset types:

| Preset Type | File | Purpose |
|---|---|---|
| `configurePresets` | `CMakePresets.json` | cmake -S . -B _build --preset <name> |
| `buildPresets` | `CMakePresets.json` | cmake --build --preset <name> |
| `testPresets` | `CMakePresets.json` | ctest --preset <name> |

All three can be in a single `CMakePresets.json`, or split into `CMakeUserPresets.json` for user-local overrides (which should be gitignored).

---

## Preset Schema

### Minimal Project Root `CMakePresets.json`

```json
{
  "version": 8,
  "configurePresets": [
    {
      "name": "default",
      "displayName": "Default",
      "description": "Default build with Ninja, ccache, mold, debug config",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/_build",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_C_COMPILER_LAUNCHER": "/usr/bin/ccache",
        "CMAKE_CXX_COMPILER_LAUNCHER": "/usr/bin/ccache",
        "CMAKE_EXE_LINKER_FLAGS_INIT": "-fuse-ld=mold",
        "CMAKE_SHARED_LINKER_FLAGS_INIT": "-fuse-ld=mold"
      }
    },
    {
      "name": "release",
      "displayName": "Release",
      "description": "Release build with optimizations",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/_build/release",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      },
      "inherits": ["default"]
    },
    {
      "name": "ci",
      "displayName": "CI",
      "description": "CI build with minimal dependencies, no docs",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/_build/ci",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "OFF"
      }
    },
    {
      "name": "modules",
      "displayName": "C++23 Modules",
      "description": "Experimental C++23 modules mode (requires CMake 3.28+)",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/_build/modules",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "PROJECT_USE_MODULES": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "default",
      "configurePreset": "default"
    },
    {
      "name": "release",
      "configurePreset": "release"
    },
    {
      "name": "ci",
      "configurePreset": "ci"
    },
    {
      "name": "modules",
      "configurePreset": "modules"
    }
  ],
  "testPresets": [
    {
      "name": "default",
      "configurePreset": "default",
      "output": {"outputOnFailure": true},
      "execution": {"noTestsAction": "error", "stopOnFailure": false}
    },
    {
      "name": "ci",
      "configurePreset": "ci",
      "output": {"outputOnFailure": true},
      "execution": {"noTestsAction": "error", "stopOnFailure": true}
    }
  ]
}
```

---

## Preset Design Principles

### 1. Start with a `default` preset
- Most developers should only need `cmake --preset default && cmake --build --preset default`
- Encode the team's standard configuration (generator, tools, build type)

### 2. Use `inherits` to avoid duplication
- Define common cacheVariables in a hidden `base` preset, inherit in others
- Example: all presets need ccache + mold, only build type varies

### 3. Separate `CMakeUserPresets.json` for personal overrides
```json
{
  "version": 8,
  "configurePresets": [
    {
      "name": "user",
      "inherits": "default",
      "displayName": "User Override",
      "cacheVariables": {
        "CMAKE_C_COMPILER_LAUNCHER": "",
        "CMAKE_CXX_COMPILER_LAUNCHER": ""
      }
    }
  ]
}
```
- Add `CMakeUserPresets.json` to `.gitignore`
- Lets individuals override tool paths without touching the shared file

### 4. Encode CI presets
- CI should use documented presets, not inline cmake arguments
- Includes `-DWARNINGS_AS_ERRORS=ON` or similar strict flags

### 5. Align JSON schema version with `cmake_minimum_required()`
- Use the same version as `cmake_minimum_required` in CMakeLists.txt
- Prevents surprising errors from preset-only features

---

## Workflow

```bash
# Configure with default preset
cmake --preset default

# Build
cmake --build --preset default

# Run tests with output on failure
ctest --preset default

# Configure a different preset
cmake --preset release && cmake --build --preset release

# List available presets
cmake --list-presets
```

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Forgetting `binaryDir` | All configurePresets need binaryDir |
| Overlapping binaryDir | Use `${sourceDir}/_build/<preset-name>` |
| Hardcoded absolute paths | Use `${sourceDir}`, `${sourceParentDir}`, `$env{HOME}` |
| Missing `version` field | Always set `"version": 8` |
| buildPresets referencing unknown configurePreset | Ensure the name matches exactly |
| CMAKE_BUILD_TYPE in Ninja Multi-Config | Use multi-config presets instead |

---

## Debugging Presets

```bash
# Validate JSON syntax
python3 -m json.tool CMakePresets.json

# Debug preset resolution (CMake 3.27+)
cmake --preset default --debug-preset
```

---

## Verification Checklist

- [ ] `cmake --list-presets` shows all expected presets
- [ ] `cmake --preset default` configures without errors
- [ ] `cmake --build --preset default` compiles successfully
- [ ] Tools (ccache, mold) are picked up correctly per preset
- [ ] Different presets produce different binary directories
- [ ] CI preset works in CI environment
- [ ] Version field is the latest supported by minimum CMake version
