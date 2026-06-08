# C++ Debugging Reference

## mcp-dap-server Tool Mapping

| GDB Command | mcp-dap-server Tool | Notes |
|-------------|---------------------|-------|
| `gdb -i dap` | `debug(mode="binary", debugger="gdb")` | Start session |
| `break main` | `breakpoint(function="main")` | Set breakpoint |
| `break file.cpp:42` | `breakpoint(file="file.cpp", line=42)` | File+line breakpoint |
| `continue` | `continue()` | Run to next breakpoint |
| `next` | `step(mode="over")` | Step over |
| `step` | `step(mode="in")` | Step into |
| `finish` | `step(mode="out")` | Step out |
| `info locals` | `context()` | Current variables |
| `bt` | `context()` | Stack trace |
| `print expr` | `evaluate(expression="expr")` | Evaluate expression |
| `info threads` | `info(kind="threads")` | List threads |
| `thread N` | `context(threadId=N)` | Switch thread |
| `quit` | `stop()` | End session |

## STL Container Inspection

### Vector
```json
// Basic inspection
evaluate(expression="vec")
// Pretty printed: std::vector of length 3, capacity 4 = {1, 2, 3}

// Size and capacity
evaluate(expression="vec.size()")
evaluate(expression="vec.capacity()")

// Access elements
evaluate(expression="vec[0]")
evaluate(expression="vec.front()")
evaluate(expression="vec.back()")

// Internal layout (libstdc++)
evaluate(expression="vec._M_impl._M_start")  // begin pointer
evaluate(expression="vec._M_impl._M_finish")  // end pointer
evaluate(expression="vec._M_impl._M_end_of_storage")  // capacity pointer
```

### String
```json
evaluate(expression="str")
// Pretty printed: "hello world"

evaluate(expression="str.size()")
evaluate(expression="str.capacity()")
evaluate(expression="str.c_str()")  // Raw C string
evaluate(expression="str.data()")
```

### Map/Unordered Map
```json
evaluate(expression="my_map")
// Pretty printed: std::map with 3 elements = {[key1] = val1, ...}

// Access
evaluate(expression="my_map[key]")
evaluate(expression="my_map.at(key)")
evaluate(expression="my_map.find(key)->second")

// Iterators
evaluate(expression="my_map.begin()->first")
evaluate(expression="my_map.rbegin()->second")
```

### Set
```json
evaluate(expression="my_set")
// Pretty printed: std::set with 3 elements = {1, 2, 3}

evaluate(expression="my_set.count(value)")
evaluate(expression="my_set.find(value)")
```

### Smart Pointers
```json
// unique_ptr
evaluate(expression="ptr")
// Pretty printed: std::unique_ptr to value or 0x0

evaluate(expression="ptr.get()")
evaluate(expression="*ptr")  // Dereference

// shared_ptr
evaluate(expression="ptr")
// Pretty printed: std::shared_ptr to value (count N)

evaluate(expression="ptr.use_count()")
evaluate(expression="ptr.get()")
evaluate(expression="ptr.unique()")

// weak_ptr
evaluate(expression="wp.lock()")  // Promote to shared_ptr
evaluate(expression="wp.expired()")
```

## VTable Debugging

### Check Object's Dynamic Type
```json
// Get vtable pointer
evaluate(expression="*(void**)obj")

// First entry in vtable (usually type_info)
evaluate(expression="*(void**)*(void**)obj")

// Check specific type
evaluate(expression="dynamic_cast<Derived*>(base_ptr) != nullptr")

// Type info name
evaluate(expression="__cxxabiv1::__class_type_info")
```

### VTable Corruption Detection
```json
// Valid vtable starts with type_info pointer
evaluate(expression="*(void**)obj")
// If this is 0x0 or garbage, vtable is corrupted

// Check if object is properly constructed
evaluate(expression="obj->type_info")
// Crash here means object not fully constructed or memory corrupted
```

## Template Debugging

### Inspect Template Arguments
```json
// Get type info
evaluate(expression="typeid(vec).name()")
// Returns mangled name, use c++filt to demangle

// Check template parameters
evaluate(expression="sizeof(vec)")
evaluate(expression="vec.max_size()")

// decltype inspection
evaluate(expression="decltype(auto_func()){}")
```

### Lambda Debugging
```json
// Lambda is a unique type with operator()
evaluate(expression="lambda")
// Shows: <lambda(...)>::<unnamed>

// Call lambda
evaluate(expression="lambda(args)")

// Inspect captured variables
evaluate(expression="lambda._data")  // Implementation dependent
```

## Exception Debugging

### Catch Exceptions
```json
// Break on throw
breakpoint(function="__cxa_throw")

// Break on catch (implementation specific)
breakpoint(function="__cxa_begin_catch")

// Break on terminate
breakpoint(function="std::terminate")
breakpoint(function="__cxa_fatal_error")
```

### Inspect Exception
```json
// When stopped at __cxa_throw
evaluate(expression="$rax")  // First arg: exception object
evaluate(expression="*(std::exception**) $rax")

// In catch block
evaluate(expression="e")
evaluate(expression="e.what()")
evaluate(expression="typeid(e).name()")
```

## Concurrency Debugging

### Thread State
```json
info(kind="threads")
// Shows all threads with their current function

// Switch and inspect
context(threadId=2)
```

### Mutex Debugging
```json
// Check if mutex is locked
evaluate(expression="mutex._M_mutex.__data.__owner")
// Non-zero = locked by that thread

// Check lock_guard/unique_lock
evaluate(expression="lock.owns_lock()")
evaluate(expression="lock.mutex()")
```

### Data Race Detection
```json
// Watch variable access
evaluate(expression="watch my_var")

// Check atomic operations
evaluate(expression="atomic_var.load()")
evaluate(expression="atomic_var.is_lock_free()")
```

## Memory Debugging

### Heap Inspection
```json
// Check allocation
breakpoint(function="operator new(unsigned long)")
breakpoint(function="malloc")

// Check deallocation
breakpoint(function="operator delete(void*)")
breakpoint(function="free")

// Inspect heap pointer
evaluate(expression="(void*)ptr")
evaluate(expression="malloc_info")  // GDB specific
```

### Use-After-Free
```json
// Enable catchpoints
breakpoint(function="__libc_free")

// When hit, check pointer
evaluate(expression="ptr")
// Continue and see if same ptr is accessed again
```

### Stack Overflow
```json
// Check stack usage
evaluate(expression="(void*)$rsp")
evaluate(expression="(void*)$rbp")

// Calculate frame size
evaluate(expression="(long)$rbp - (long)$rsp")

// Very deep stack? Check for infinite recursion
info(kind="threads")
context()  // Look for repeated frames
```

## Core Dump Analysis

### C++ Crash Patterns

#### SIGSEGV - Null Pointer
```json
context()
// Look for:
evaluate(expression="ptr")  // Shows 0x0
evaluate(expression="obj->method()")  // Crash here
```

#### SIGSEGV - VTable Corruption
```json
context()
// Look for:
evaluate(expression="*(void**)obj")  // Garbage address
// Object memory corrupted, check for buffer overflow nearby
```

#### SIGABRT - Assertion Failed
```json
context()
// Stack shows: __GI___assert_fail -> your_function
evaluate(expression="assertion_string")
evaluate(expression="file")
evaluate(expression="line")
```

#### SIGABRT - Double Free
```json
context()
// Stack shows: __GI___libc_free -> _int_free -> error
// Check what ptr was freed twice
evaluate(expression="ptr")
```

## GDB Pretty Printers

GDB 14+ includes pretty printers for:
- **libstdc++**: vector, string, map, set, list, deque, etc.
- **libc++**: Same STL containers
- **Boost**: smart_ptr, container, etc.
- **Qt**: QString, QVector, QMap, etc.

Enable with:
```json
evaluate(expression="set print pretty on")
evaluate(expression="set print object on")
```

## Common GDB Expressions for C++

```json
// Cast to specific type
evaluate(expression="(Derived*)base_ptr")

// Check type
evaluate(expression="typeid(*obj).name()")

// Array inspection
evaluate(expression="{int[10]}ptr")  // Cast pointer to array

// String from address
evaluate(expression="(char*)addr")

// Demangle type name
evaluate(expression="typeid(T).name()")
// Then: echo $var | c++filt
```

## Debugging Workflow Templates

### Template 1: STL Container Bug
```json
1. breakpoint(function="container_method")
2. continue()
3. evaluate(expression="container")  // Pretty print
4. evaluate(expression="container.size()")
5. evaluate(expression="iterator")  // Check iterator validity
6. step(mode="over")  // Step through operation
7. evaluate(expression="container")  // Check state change
```

### Template 2: Polymorphism Bug
```json
1. breakpoint(function="virtual_method")
2. continue()
3. evaluate(expression="this")  // Check object
4. evaluate(expression="*(void**)this")  // Check vtable
5. evaluate(expression="dynamic_cast<ExpectedType*>(this)")  // Verify type
6. context()  // Full state
```

### Template 3: Exception Bug
```json
1. breakpoint(function="__cxa_throw")
2. continue()
3. evaluate(expression="$rdx")  // Exception type
4. evaluate(expression="$rsi")  // Destructor
5. evaluate(expression="*(void**) $rax")  // Exception object
6. info(kind="threads")  // Check other threads
```
