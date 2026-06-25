# C++ Crash Diagnosis

Post-mortem and live crash diagnosis for C++ programs using GDB via mcp-dap-server. Covers segfaults, aborts, memory corruption, and stack overflows.

## Crash Types Quick Reference

| Signal | Cause | C++ Common Causes |
|--------|-------|-------------------|
| SIGSEGV | Invalid memory access | Null/dangling pointer, vtable corruption, buffer overflow |
| SIGABRT | Explicit abort | Failed assertion, double-free, bad alloc, uncaught exception |
| SIGBUS | Bus error | Misaligned access, huge page fault |
| SIGFPE | Arithmetic error | Division by zero, overflow (with -ftrapv) |
| SIGILL | Illegal instruction | Corrupted binary, CPU feature mismatch |
| SIGSTACK/SIGSEGV | Stack overflow | Infinite recursion, large stack allocation |

## Core Dump Workflow

### 1. Load Core Dump

```json
debug(mode="core", path="/abs/path/to/binary", coreFilePath="/abs/path/to/core", debugger="gdb")
```

If binary path unknown (GDB can auto-detect):
```json
debug(mode="core", coreFilePath="/abs/path/to/core", debugger="gdb")
```

### 2. Get Crash Context

```json
context()
```

Extract immediately:
- **Crash function**: What C++ function was executing?
- **Signal**: What killed the process?
- **Stack trace**: Call sequence leading to crash
- **Local variables**: State at crash moment

### 3. Diagnose by Pattern

#### Null Pointer Dereference

```json
// Check pointer value
evaluate(expression="ptr")
// Output: 0x0

// Find where ptr came from
context(frameId=2)  // Check caller
evaluate(expression="return_value_from_caller")
```

**Fix**: Add null check or fix function that returns null.

#### Dangling Pointer

```json
// Pointer looks valid but points to freed memory
evaluate(expression="ptr")
// Output: 0x555555555555 (looks valid)

// Try to access - may crash or show garbage
evaluate(expression="*ptr")
// Garbage values or crash

// Check if object was destroyed
evaluate(expression="ptr->type_info")
// Crash = vtable corrupted/destroyed
```

**Fix**: Use smart pointers, null after delete, check ownership model.

#### VTable Corruption

```json
// Check vtable pointer
evaluate(expression="*(void**)obj")
// Output: 0x4242424242424242 (garbage) or 0x0

// Object memory overwritten
evaluate(expression="sizeof(*obj)")
// Check nearby memory for buffer overflow
```

**Fix**: Buffer overflow writing past object. Use bounds checking.

#### Buffer Overflow

```json
// Crash in memset/memcpy/memmove
context()
// Stack shows: __GI_memset -> your_function

// Check buffer and size
evaluate(expression="buffer")
evaluate(expression="size")
evaluate(expression="buffer_size")
// size > buffer_size = overflow
```

**Fix**: Use std::array, std::vector, bounds checking, address sanitizer.

#### Double Free

```json
// Crash in free/delete
context()
// Stack shows: __GI___libc_free -> _int_free -> abort

// Check what's being freed
evaluate(expression="ptr")

// Look for multiple owners
info(kind="threads")
// Check if another thread also frees ptr
```

**Fix**: Use unique_ptr, clear pointers after free, check ownership model.

#### Stack Overflow

```json
// Very deep stack trace
context()
// Look for repeated frames = infinite recursion

// Check stack usage
evaluate(expression="(void*)$rsp")
evaluate(expression="(void*)$rbp")
evaluate(expression="(long)$rbp - (long)$rsp")  // Frame size
```

**Fix**: Fix recursion base case, use heap allocation, increase stack size.

#### Bad Alloc

```json
// std::bad_alloc caught or terminated
context()
// Stack shows: operator new -> __gnu_cxx::new_handler -> std::terminate

// Check memory usage
evaluate(expression="malloc_stats()")
// Or check container sizes
evaluate(expression="large_vector.size()")
```

**Fix**: Reduce memory usage, check for leaks, use memory pooling.

### 4. Walk Call Stack

```json
// Examine each frame
context(frameId=1)  // Crash frame
context(frameId=2)  // Caller
context(frameId=3)  // Grandcaller

// Trace bad value back to origin
evaluate(expression="argument_that_became_null")
```

### 5. Check All Threads

```json
info(kind="threads")
// Look for:
// - Threads holding locks that crashed thread needs
// - Threads that may have corrupted shared memory
// - Threads in unexpected states
```

## Live Crash Debugging

When program crashes repeatedly:

### 1. Catch Signals

```json
debug(mode="binary", path="/abs/path/to/binary", debugger="gdb", stopOnEntry=true)

// Break on signal handlers
breakpoint(function="__GI_raise")
breakpoint(function="abort")
breakpoint(function="std::terminate")

continue()
```

### 2. Catch Exceptions

```json
breakpoint(function="__cxa_throw")
continue()

// When hit:
evaluate(expression="$rdx")  // Exception type
evaluate(expression="*(void**) $rax")  // Exception object
context()  // Full state
```

### 3. Catch Memory Operations

```json
// Track allocations
breakpoint(function="operator new(unsigned long)")
breakpoint(function="operator delete(void*)")

// Track specific object
breakpoint(function="*(&my_object)")  // Hardware watchpoint
```

## Memory Corruption Detection

### Enable GDB Features

```json
// Catch memory errors
evaluate(expression="catch segfault")
evaluate(expression="catch abort")

// Enable hardware watchpoints
evaluate(expression="watch suspicious_var")
```

### Check Heap Integrity

```json
// When crash occurs
evaluate(expression="malloc_trim(0)")  // Check for corruption

// Inspect heap
evaluate(expression="malloc_stats()")
```

## Post-Mortem Checklist

After analysis, answer:

1. **What signal?** (SIGSEGV, SIGABRT, etc.)
2. **Where in code?** (Function, file, line)
3. **What was the invalid operation?** (Null deref, buffer overflow, etc.)
4. **What caused the bad state?** (Trace back through call stack)
5. **How to reproduce?** (Minimal steps)
6. **How to fix?** (Code change)

## Example Analysis

```
Crash: SIGSEGV at 0x00005555555551a0 in Widget::process()
Stack:
  #0 Widget::process() at widget.cpp:42
  #1 Manager::handle() at manager.cpp:15
  #2 main() at main.cpp:8

Analysis:
evaluate(expression="this") -> 0x555555555555
evaluate(expression="*(void**)this") -> 0x0  <- VTABLE CORRUPTED

Root cause: Widget memory overwritten by buffer overflow in Manager::handle()
Fix: Add bounds checking in Manager::handle() buffer copy
```

## Clean Up

```json
stop()
```

## References

- **GDB crash debugging**: `info signals`, `catch`, `watch`
- **mcp-dap-server tools**: `debug`, `context`, `evaluate`, `info`, `breakpoint`
- **C++ ABI**: Itanium C++ ABI for vtable layout, exception handling
- For STL debugging techniques: load `debug`
