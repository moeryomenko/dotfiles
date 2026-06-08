---
name: cpp-debug
description: |
  C++ debugging with GDB via mcp-dap-server. Debug C++ programs, inspect STL containers, analyze vtables, unwrap templates, diagnose crashes, and debug concurrency issues.
  TRIGGER when: debugging C/C++ code, inspecting STL containers, analyzing vtables, debugging C++ exceptions, investigating C++ crashes, or using GDB for C++ development.
  DO NOT TRIGGER when: debugging Go programs (use debug-source with delve), analyzing non-C++ core dumps, or reverse engineering binaries without debug symbols.
---

# C++ Debugging with GDB via mcp-dap-server

Debug C++ programs using GDB's native DAP server through mcp-dap-server. Covers STL inspection, vtable analysis, template debugging, and C++-specific crash diagnosis.

## Quick Start

```json
// Compile with debug symbols
// g++ -g -O0 -std=c++17 main.cpp -o main

// Start debugging
debug(mode="binary", path="/abs/path/to/main", debugger="gdb")
```

## C++ Debugging Checklist

Before debugging:
1. **Compile with**: `g++ -g -O0 -std=c++17` (never optimize when debugging)
2. **Enable STL pretty printers**: GDB 14+ includes them by default
3. **Check symbols**: `file /path/to/binary` shows if debug info exists
4. **Form hypothesis**: What C++ feature might be involved? (STL, templates, polymorphism, exceptions, threads)

## Core Workflow

### 1. Start Session
```json
debug(mode="binary", path="/abs/path/to/binary", debugger="gdb", stopOnEntry=true)
```

### 2. Set Breakpoints
```json
// By function (works with mangled names)
breakpoint(function="main")
breakpoint(function="std::vector<int>::push_back")

// By file and line
breakpoint(file="/path/to/file.cpp", line=42)

// By address
breakpoint(function="*0x401234")
```

### 3. Inspect C++ State
```json
context()  // Shows location, stack, variables with STL pretty printing
```

### 4. Evaluate C++ Expressions
```json
// STL containers
evaluate(expression="my_vector.size()")
evaluate(expression="my_map.begin()->first")
evaluate(expression="my_string.c_str()")

// Smart pointers
evaluate(expression="ptr.get()")
evaluate(expression="ptr.use_count()")

// Templates
evaluate(expression="container<T>::value_type")
```

## C++-Specific Techniques

### STL Container Inspection

GDB's pretty printers display STL containers naturally:

```json
// Vector
evaluate(expression="vec")
// Output: std::vector of length 3, capacity 4 = {1, 2, 3}

// Map
evaluate(expression="my_map")
// Output: std::map with 3 elements = {[key1] = val1, [key2] = val2}

// String
evaluate(expression="str")
// Output: "hello world"

// Inspect internals
evaluate(expression="vec._M_impl._M_finish - vec._M_impl._M_start")  // size
evaluate(expression="vec._M_impl._M_end_of_storage - vec._M_impl._M_start")  // capacity
```

### VTable and Polymorphism Debugging

When objects behave incorrectly through base class pointers:

```json
// Check vtable pointer
evaluate(expression="*(void**)obj")

// Dump vtable contents
evaluate(expression="*(void**)*(void**)obj")

// Check dynamic type
evaluate(expression="dynamic_cast<Derived*>(base_ptr)")

// Inspect virtual call
evaluate(expression="obj->type_info")
```

### Template Type Inspection

```json
// Get template arguments
evaluate(expression="sizeof(container)")
evaluate(expression="typeid(container).name()")

// Unwrap complex types
evaluate(expression="decltype(auto_func()){}")
```

### Exception Debugging

```json
// Catch C++ exceptions
breakpoint(function="__cxa_throw")
breakpoint(function="std::terminate")

// Inspect exception
evaluate(expression="__cxa_current_exception_type()")
evaluate(expression="e.what()")  // When caught
```

## Common C++ Bug Patterns

### 1. Dangling Reference/Pointer
```cpp
// Bug: reference to local
const string& get_name() { return local_name; }

// Debug: check if pointer is valid
evaluate(expression="(void*)ptr")  // Should not be 0x0 or garbage
evaluate(expression="ptr->type_info")  // Crash if dangling
```

### 2. STL Iterator Invalidated
```cpp
// Bug: iterator used after erase
auto it = vec.erase(it);  // Old it invalid

// Debug: check iterator state
evaluate(expression="it._M_current")
evaluate(expression="vec.end()._M_current")
```

### 3. Smart Pointer Cycle
```cpp
// Bug: shared_ptr cycle
evaluate(expression="ptr.use_count()")  // > 1 when should be 0
evaluate(expression="weak_ptr.lock()")  // nullptr if expired
```

### 4. Exception Swallowed
```cpp
// Bug: empty catch block
catch(...) {}  // Swallows everything

// Debug: set breakpoint on throw
breakpoint(function="__cxa_throw")
```

## Thread Debugging

```json
// List all threads
info(kind="threads")

// Switch to thread
context(threadId=<ID>)

// Check mutex state
evaluate(expression="mutex._M_mutex")
evaluate(expression="lock.owns_lock()")
```

## Memory Debugging

### Use-After-Free Detection
```json
// Check if memory is freed
evaluate(expression="(void*)ptr")
// If address looks valid but access crashes, likely use-after-free

// Enable GDB catchpoints
breakpoint(function="operator delete(void*)")
breakpoint(function="free")
```

### Double-Free Detection
```json
// Track deletions
breakpoint(function="operator delete(void*)")
// When hit, check if ptr was already freed
evaluate(expression="ptr")
```

## Core Dump Analysis

For C++ crashes:

```json
debug(mode="core", path="/abs/path/to/binary", coreFilePath="/abs/path/to/core", debugger="gdb")
```

Then:
```json
context()  // Crash location with C++ types
info(kind="threads")  // All thread states
```

Look for:
- **SIGSEGV**: Null/dangling pointer, vtable corruption
- **SIGABRT**: Failed assertion, double-free, bad alloc
- **Stack overflow**: Infinite recursion, large stack arrays

## Advanced GDB Features

### Watchpoints
```json
// Watch variable changes
breakpoint(function="*(&my_var)")  // Hardware watchpoint
```

### Conditional Breakpoints
```json
// Break when condition met
breakpoint(function="process", condition="index == 42")
```

### Reverse Debugging (if enabled)
```json
// Record execution
evaluate(expression="record")
// Go backwards
step(mode="reverse")
```

## Clean Up

```json
stop()  // Terminate debuggee
// or
stop(detach=true)  // Leave running
```

## References

- **GDB C++ pretty printers**: Built-in for STL, boost, Qt
- **mcp-dap-server tools**: `debug`, `context`, `breakpoint`, `evaluate`, `info`, `step`, `continue`, `stop`
- **C++ Core Guidelines**: Load `cpp-core-guidelines` for coding standards
