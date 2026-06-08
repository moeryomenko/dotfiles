---
name: go-debug-core-dump
description: Post-mortem analysis of Go core dumps via mcp-dap-server with Delve. Use when analyzing a Go crash, investigating a panic, understanding a segfault, or examining an application that crashed in production.
---

# Go Core Dump Analysis (mcp-dap-server + Delve)

## Pre-flight Checklist

Before starting, confirm:
1. **Absolute path** to the Go binary that crashed
2. **Absolute path** to the core dump file
3. **Do the binary and core match?** A rebuilt binary will NOT match the core dump
4. **Was the binary built with debugging symbols?** Build with `-gcflags=all=-N -l` for best results
5. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

**Enabling core dumps in production:**
```bash
ulimit -c unlimited                  # enable core dumps
echo /tmp/core.%p > /proc/sys/kernel/core_pattern  # set location
```

**Key insight:** Execution is frozen. You cannot step forward. You're reading a snapshot of memory at the moment of crash.

---

## Step-by-Step Workflow

### 1. Start the Core Dump Session

```json
debug(
  mode="core",
  path="/abs/path/to/binary",
  coreFilePath="/abs/path/to/core",
  debugger="delve"
)
```

The debugger loads the core and positions at the crash frame. You receive the crash location, stack trace, and local variables.

If loading fails:
- Check paths are absolute and files are readable
- Confirm binary matches the core (same build, not recompiled after crash)
- Check Go version matches between build and Delve version
- Verify `dlv` is in `$PATH` (`dlv version`)
- Try `file /path/to/binary` to check for debug info

### 2. Get the Full Picture of the Crash

```json
context()
```

This is your most important call. Extract:
- **Crash function and line** — where exactly did the program die?
- **Signal** — what killed it? (see signal guide below)
- **Local variables at the crash frame** — any nil pointers? Invalid values?
- **Full stack trace** — what sequence of calls led to the crash?

**Go crash signal guide:**

| Signal | Meaning | Common Go Causes |
|--------|---------|------------------|
| `SIGSEGV` | Segmentation fault | Nil pointer dereference, cgo memory misuse, stack overflow |
| `SIGABRT` | Abort | Go runtime panic (after recovery fails), explicit `os.Exit` |
| `SIGBUS` | Bus error | Misaligned memory access (rare, usually cgo) |
| `SIGFPE` | Arithmetic | Integer divide by zero in cgo code |
| `SIGPIPE` | Broken pipe | Write to closed socket (Go handles this unless SIGPIPE disposition is changed) |

### 3. Examine Crash Frame Variables

Look at every variable shown in `context()`:
- **Nil pointer being dereferenced?** → SIGSEGV
- **Index used on nil/zero-length slice?** → SIGSEGV
- **Corrupt value** (negative size, astronomical number)?
- **Error value that was ignored?** → `err` variable non-nil but was not checked

Use `evaluate()` to drill into values not shown automatically:
```json
evaluate(expression="err.Error()")
evaluate(expression="req.Body")
evaluate(expression="items[0]")
evaluate(expression="len(items)")
```

### 4. Walk the Call Stack

Work backwards through the stack. Each frame shows different variables:

```json
context(frameId=0)    # crash frame (current)
```
```json
context(frameId=1)    # caller
```
```json
context(frameId=2)    # caller's caller
```

**For each frame ask:**
- What argument was passed to the crashing function?
- Was that argument already nil/invalid when it was passed?
- Which caller is responsible for the bad value?

This traces the bad value back to its origin.

### 5. Check Other Goroutines

```json
info(kind="threads")
```

In concurrent programs:
- Another goroutine may have corrupted shared memory before the crash
- A goroutine in an unexpected state may indicate a race condition

Inspect interesting goroutines:
```json
context(threadId=<ID>)
```

### 6. Evaluate Suspicious Expressions

Based on your hypothesis, test specific values:
```json
evaluate(expression="config.MaxRetries")
evaluate(expression="len(pool.connections)")
evaluate(expression="handler != nil")
evaluate(expression="user.String()")
```

### 7. Pattern-Based Diagnosis

Match the crash to a known pattern:

**Nil Pointer (SIGSEGV):**
```
→ Which pointer is nil?
→ Who created/returned that pointer?
→ Was the nil return from a function call checked?
→ Fix: add nil check before dereference, or fix the callee
```

**Index Out of Range (SIGABRT / runtime panic):**
```
→ Look for panic message in the stack or variables
→ What is the index value?
→ What is the length of the slice/map?
→ Fix: bounds check before indexing, or ensure slice is non-empty
```

**Nil Map Write (SIGABRT / runtime panic):**
```
→ A map variable was never initialized with make()
→ Look for `var m map[string]T` that was never assigned
→ Fix: use `make(map[string]T)` or map literal
```

**Concurrent Map Read/Write (fatal error):**
```
→ The runtime detected concurrent access to a map
→ Look for goroutines accessing the same map without synchronization
→ Fix: add sync.RWMutex or use sync.Map
```

**Infinite Recursion → Stack Overflow (SIGSEGV):**
```
→ Very deep stack with the same function repeating
→ What is the base case? Is it reachable?
→ Fix: add/fix the base case, or convert to iterative
```

**Cgo Crash (SIGSEGV in C code):**
```
→ Stack shows frames in cgo/c called from Go
→ C code does not have Go's memory safety
→ Fix: check C code for buffer overflows, use-after-free, etc.
```

### 8. Conclude

Answer:
1. **What crashed?** — function, file, line number
2. **What signal/error?** — and what it means
3. **What bad value caused it?** — which variable, what value
4. **Where did that value come from?** — trace through the call stack
5. **Root cause?** — the code defect to fix

```json
stop()
```

---

## How to Present Findings

> **Crash at** `handler.go:142` in `handleRequest`. **Signal:** SIGSEGV.
> **Cause:** `conn.writer` is nil. `conn` is non-nil but was not fully initialized because `newConn()` returns on timeout without setting `writer`.
> **Fix:** Either return an error from `newConn()` on timeout, or add a nil check before `conn.writer.Write()`.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `debug(mode="core", path=..., coreFilePath=..., debugger="delve")` | Load core dump |
| `context()` | Crash location, stack, variables |
| `context(frameId=N)` | Switch to stack frame N |
| `context(threadId=N)` | Switch to goroutine N |
| `info(kind="threads")` | All goroutines at crash time |
| `evaluate(expression=...)` | Evaluate expression |
| `stop()` | Clean up |

## Delve Equivalent Mapping

| mcp-dap-server Command | Equivalent Delve CLI |
|------------------------|---------------------|
| `context()` | `(dlv) stack` + `(dlv) locals` |
| `context(frameId=N)` | `(dlv) frame N` + `(dlv) locals` |
| `info(kind="threads")` | `(dlv) goroutines` |
| `context(threadId=N)` | `(dlv) goroutine N` + `(dlv) stack` |
| `evaluate(expression="x")` | `(dlv) print x` |

---

## When Not to Use This Skill

- **Process still running** — use `go-debug-attach` to attach to a live process via `debug(mode="attach")`
- **Interactive debugging** — use `go-debug-source` for step-through debugging
- **Race detection** — use `go test -race` or `go build -race`
- **Performance profiling** — use pprof profiles instead
