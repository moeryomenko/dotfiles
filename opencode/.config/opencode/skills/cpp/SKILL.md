---
name: cpp
description: Complete C++ development skill — Core Guidelines, clang-tidy, modernization, debugging, and crash diagnosis. Load automatically when working on C++ projects.
invocation_policy: automatic
---

# C++ Skill Assembly

Unified C++ knowledge base organized by domain features. Route to the correct feature file based on the task.

## Configuration

The C++ skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Core Guidelines Reference
When asked about C++ Core Guidelines, writing new C++ code, or reviewing code for guideline compliance:
1. Load `features/guidelines.md` for section navigation
2. Load the domain-specific feature matching the code area:
   - **Functions**: `features/functions.md`
   - **Classes**: `features/classes.md`
   - **Resource management**: `features/resource-management.md`
   - **Concurrency**: `features/concurrency.md`
   - **Interfaces**: `features/interfaces.md`
   - **Templates**: `features/templates.md`
   - **Error handling**: `features/error-handling.md`
   - **Expressions and statements**: `features/expressions.md`
   - **Performance**: `features/performance.md`
   - **Enumerations**: `features/enumerations.md`
   - **Constants**: `features/constants.md`
   - **Source files**: `features/source-files.md`

### Clang-Tidy Configuration
When setting up .clang-tidy, selecting checkers, suppressing warnings, or configuring CI gates:
1. Load `features/clang-tidy.md`

### Code Modernization
When upgrading legacy C++98/03 code to C++11/14/17/20, replacing C-style patterns, or running clang-tidy modernize checks:
1. Load `features/modernize.md`

### Crash Diagnosis
When debugging a C++ crash, analyzing core dumps, investigating segfaults, or diagnosing memory corruption:
1. Load `features/crash-debug.md`
2. Use GDB via mcp-dap-server for analysis

### Live Debugging
When debugging C++ programs, inspecting STL containers, analyzing vtables, or unwrapping templates:
1. Load `features/debug.md`
2. Use GDB via mcp-dap-server for inspection

## Cross-Referencing

When a task spans multiple domains, load the primary domain feature first, then load additional features as needed. Features reference each other for cross-cutting topics.
