---
name: cmake-install-export
description: Configure CMake install, export, and packaging (CPack) for C++ libraries. Use when setting up library distribution, fixing broken install targets, or adding packaging.
when_to_use: "When configuring library install/export targets, fixing install errors, adding CPack packaging, writing CMake config file templates (*Config.cmake.in), or when cmake --install fails. NOT for writing CMakePresets.json or build logic."
allowed-tools: Read, Write, Bash, Grep, Glob
effort: high
---

# CMake Install, Export & Packaging

> A library that cannot be installed by a package manager does not exist for consumers. This skill ensures your CMake install/export chain is correct end-to-end.

---

## Install/Export Flow

```
add_library → install(TARGETS) → install(EXPORT) → configure_package_config_file → CPack
                      ↓
          Consumer's find_package()
                      ↓
          <Package>Config.cmake (generated from .in template)
                      ↓
               find_dependency() for each dependency
                      ↓
               add_library(<pkg>::<pkg> ALIAS ...)
                      ↓
          Consumer's target_link_libraries()
```

---

## Step-by-Step Install Configuration

### 1. Include Required Modules

```cmake
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
```

### 2. Install the Library Target

```cmake
# For an INTERFACE (header-only) library
install(
  TARGETS ${PROJECT_NAME}
  EXPORT ${PROJECT_NAME}Targets
  FILE_SET CXX_MODULES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}  # only if modules
  INCLUDES
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# For a real (STATIC/SHARED) library
install(
  TARGETS mylib
  EXPORT mylibTargets
  ARCHIVE  DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY  DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME  DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

### 3. Install Headers Separately

```cmake
install(
  DIRECTORY include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING
  PATTERN "*.hpp"
  PATTERN "*.h"
)
```

### 4. Export Targets

```cmake
# Install export (for find_package after install)
install(
  EXPORT ${PROJECT_NAME}Targets
  FILE ${PROJECT_NAME}Targets.cmake
  NAMESPACE ${PROJECT_NAME}::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

# Build-tree export (for find_package in build dir)
export(
  EXPORT ${PROJECT_NAME}Targets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake
  NAMESPACE ${PROJECT_NAME}::
)
```

### 5. Configure Package Config Files

`cmake/${PROJECT_NAME}Config.cmake.in`:
```cmake
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}Targets.cmake")

check_required_components(${PROJECT_NAME})
```

With dependencies:
```cmake
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
find_dependency(Threads)

include("${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}Targets.cmake")
check_required_components(${PROJECT_NAME})
```

Back in CMakeLists.txt:
```cmake
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

install(
  FILES
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)
```

---

## CPack Packaging

### Minimal CPack Integration

```cmake
# Add at the end of root CMakeLists.txt
set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_VENDOR "Project Authors")

# Source package
set(CPACK_SOURCE_GENERATOR "TGZ")

# Binary package formats
set(CPACK_GENERATOR "TGZ;DEB")

# DEB-specific
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "author@example.com")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

include(CPack)
```

Usage:
```bash
# Build the package
cmake --build _build
cpack --config _build/CPackConfig.cmake

# Source package
cpack --config _build/CPackSourceConfig.cmake
```

### CPack Component-Based Installation (Advanced)

```cmake
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets ... COMPONENT runtime)
install(FILES LICENSE DESTINATION ... COMPONENT license)

set(CPACK_COMPONENTS_ALL runtime license development)
set(CPACK_COMPONENT_RUNTIME_DISPLAY_NAME "Runtime")
set(CPACK_COMPONENT_DEVELOPMENT_DISPLAY_NAME "Development Headers")
```

---

## Common Issues and Fixes

| Symptom | Cause | Fix |
|---|---|---|
| `find_package` can't find package | Targets not in CMAKE_MODULE_PATH | Install to `${CMAKE_INSTALL_LIBDIR}/cmake/<pkg>` |
| Missing `@PACKAGE_INIT@` | Template missing the init macro | Add `@PACKAGE_INIT@` as first line of Config.cmake.in |
| Missing `check_required_components` | Template has no guard | Add `check_required_components(mylib)` after include |
| FILE_SET CXX_MODULES error when modules disabled | Install block references module file set unconditionally | Guard with `if(PROJECT_USE_MODULES)` |
| `find_dependency` not found | Missing `include(CMakeFindDependencyMacro)` | Add it before the first `find_dependency` call |
| Version mismatch at consumer | `COMPATIBILITY` too strict | Use `SameMajorVersion` for semver |
| Headers not found at consumer | Wrong INSTALL_INTERFACE include dir | Use `$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>` |
| Dual-use headers (build tree + install) | Missing generator expressions | Use `$<BUILD_INTERFACE:...>$<INSTALL_INTERFACE:...>` |

---

## Testing the Install

```bash
# Install to a staging directory
cmake --install _build --prefix /tmp/staging

# Or test via CPack
cpack --config _build/CPackConfig.cmake -B /tmp/packages

# Test with a consumer project
cat > /tmp/consumer/CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.23)
project(test_consumer CXX)
find_package(${PROJECT_NAME} REQUIRED)
add_executable(test_app main.cpp)
target_link_libraries(test_app PRIVATE ${PROJECT_NAME}::${PROJECT_NAME})
EOF

cd /tmp/consumer
cmake -S . -B _build -DCMAKE_PREFIX_PATH=/tmp/staging
cmake --build _build
```

---

## Verification Checklist

- [ ] `cmake --install _build --prefix /tmp/install` succeeds
- [ ] Config files are installed to `lib/cmake/<pkg>/`
- [ ] Headers are installed to `include/`
- [ ] Build-tree `export()` works (without install)
- [ ] Consumer `find_package` succeeds with `CMAKE_PREFIX_PATH`
- [ ] Consumer project links and compiles
- [ ] CPack produces archive(s) without errors
- [ ] DEB/RPM packages have correct metadata
- [ ] `SameMajorVersion` compatibility works across minor versions
- [ ] Conditional install sections (e.g., modules mode) are properly guarded
