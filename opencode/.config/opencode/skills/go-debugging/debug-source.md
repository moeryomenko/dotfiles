---
name: go-debug-source
description: Live source-level debugging of Go programs via mcp-dap-server with Delve. Use when stepping through Go code, finding bugs, inspecting runtime state, or debugging a Go program from source.
---

# Go Source-Level Debugging (mcp-dap-server + Delve)

## Pre-flight Checklist

Before starting, gather:
1. **Go module root** — the directory containing `go.mod`
2. **What is the bug or behavior?** — form your hypothesis
3. **Which function/file is most likely involved?** — first breakpoint target
4. **Build tags or environment needed?** — pass via `buildFlags="..."` parameter
5. **Program arguments?** — pass via `programArgs=["arg1", "arg2"]`
6. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

---

## Step-by-Step Workflow

### 1. Start a Debug Session

**Debug from source (recommended for most Go programs):**
```json
debug(mode="source", path="/abs/path/to/go/module/root", debugger="delve")
```

**With program arguments and build flags:**
```json
debug(
  mode="source",
  path="/abs/path/to/go/module/root",
  programArgs=["-port", "8080", "-config=dev.yaml"],
  buildFlags="-tags=integration",
  debugger="delve"
)
```

**Debug tests:**
```json
debug(
  mode="source",
  path="/abs/path/to/go/module/root",
  programArgs=["-test.run", "TestCreateUser"],
  debugger="delve"
)
```

**Pre-compiled test binary (alternative):**
```bash
go test -c -o /tmp/handler.test ./internal/handler
```
```json
debug(
  mode="binary",
  path="/tmp/handler.test",
  programArgs=["-test.run", "TestCreateUser"],
  debugger="delve"
)
```

Expected: Debugger starts, pauses at the first executable line or entry point. You receive location, stack trace, and variables.

If start fails:
- Verify `dlv` is in `$PATH` (`dlv version`)
- Ensure path is absolute
- Check module compiles cleanly (`go build ./...`)
- For test mode: ensure test package path is valid

### 2. Set Strategic Breakpoints

Set breakpoints **before continuing**, at the functions you want to investigate:

```json
breakpoint(function="main.main")
```

```json
breakpoint(file="/abs/path/to/handler.go", line=42)
```

```json
breakpoint(function="internal/handler.CreateUser")
```

**Choose locations based on your hypothesis:**
- Entry to the suspicious function
- Just before the condition you think is wrong
- At error return paths

**Clear breakpoints when done with them:**
```json
clear-breakpoints(file="/abs/path/to/handler.go")
```

### 3. Run to the First Interesting Point

```json
continue()
```

Execution pauses at your first breakpoint. The response includes:
- Current file/line
- Function call stack
- Local variables
- Goroutine/thread ID

**What to look for:**
- Is the current location where you expected?
- Are variable values what you expect?
- Is the call stack expected?

### 4. Inspect State in Depth

**Get full context at any time:**
```json
context()
```

Returns: current location, stack trace, scopes, and all local variables.

**Evaluate specific expressions (Delve syntax):**
```json
evaluate(expression="user")
```

```json
evaluate(expression="user.Address.City")
```

```json
evaluate(expression="items[0]")
```

```json
evaluate(expression="len(queue)")
```

```json
evaluate(expression="err.Error()")
```

```json
evaluate(expression="strings.HasPrefix(name, \"admin\")")
```

**Navigate the call stack:**
```json
context(frameId=<N>)
```

Frame IDs come from the stack trace returned by `context()` — use them to walk up/down the call chain and inspect variables from each frame.

**Decision guide:**
- Value is nil when it shouldn't be → trace back where it was set or returned
- Value is wrong → find where it was assigned incorrectly
- Value is correct here → the bug is downstream; add a later breakpoint

### 5. Step Through Logic

```json
step(mode="over")
```

*Execute current line, stay in same function (equivalent to Delve `next`).*

```json
step(mode="in")
```

*Step into the function being called (equivalent to Delve `step`).*

```json
step(mode="out")
```

*Run until current function returns (equivalent to Delve `stepout`).*

**When to use each:**
- `over`: when you don't suspect the called function
- `in`: when the called function is suspicious
- `out`: when you've seen enough in the current function

After each step, call `context()` or `evaluate()` to check if values changed as expected.

### 6. Examine Goroutines (Concurrent Programs)

```json
info(kind="threads")
```

This lists ALL goroutines with their locations. Look for:
- **Goroutines blocked on `sync.(*Mutex).Lock`** — potential lock contention or deadlock
- **Goroutines in `runtime.park`** — waiting on channel/select
- **Unexpectedly many goroutines** — goroutine leak
- **Goroutine 1 (main) in unexpected state** — main flow issue

Inspect suspicious goroutines:
```json
context(threadId=<ID>)
```

**Deadlock detection pattern:**
```
info(kind="threads") shows:
  Goroutine 1: sync.(*Mutex).Lock
  Goroutine 4: sync.(*Mutex).Lock
→ Switch to each with context(threadId=<ID>), inspect their stack + locals
```

### 7. Modify State to Test Hypotheses

If the debugger supports it (capability-gated):
```json
set-variable(variablesReference=<ref>, name="count", value="0")
```

Then `continue()` to see if the fix works. This confirms your hypothesis before writing real code.

### 8. Trace Execution Flow

Set multiple breakpoints and continue between them:
```json
breakpoint(file="/abs/path/to/handler.go", line=100)
breakpoint(file="/abs/path/to/handler.go", line=150)
continue()    // runs from current position to next breakpoint
```

**Restart the program (capability-gated):**
```json
restart()
```

### 9. Clean Up

```json
stop()
```

---

## Common Go Debugging Patterns

### Nil Pointer Panic

```
Symptom: "invalid memory address or nil pointer dereference"

1. evaluate(expression="stack") – or context() gives stack automatically
   → where did it happen?
2. evaluate(expression="<suspect-vars>") – which pointer is nil?
3. Trace back: who created/returned that pointer?
4. Fix: add nil check before dereference, or fix the callee
```

### Wrong Value in Calculation

```
Symptom: computed value is wrong

1. Set breakpoint at the computation start
2. evaluate(expression="<inputs>") – are inputs correct?
3. step(mode="over") through the computation line by line
4. evaluate() after each step to find where value diverges
```

### Infinite Loop

```
Symptom: program hangs, high CPU

1. breakpoint(file="<loop-file>", line=<loop-line>)
2. continue()
3. evaluate(expression="i")          # loop variable
4. evaluate(expression="len(slice)") # bound
5. Does the loop variable ever reach the bound?
```

### Goroutine Leak

```
Symptom: goroutine count keeps growing

1. info(kind="threads")           # list all goroutines
2. Count goroutines at each location
3. Look for goroutines that never finish
4. Trace: who spawned them? Is there a way to signal them to stop?
```

### Interface Dispatch — Which Concrete Type?

```
Symptom: unexpected behavior from interface call

evaluate(expression="reader")
→ Shows dynamic type: *os.File, *bytes.Buffer, etc.

evaluate(expression="reader.(*os.File)")
→ Type assert to check specific type
```

### Channel Operations

```
Symptom: goroutine stuck on channel

info(kind="threads")                    # find blocked goroutine
context(threadId=<N>)                   # switch to it
evaluate(expression="ch")               # inspect channel state
```

### Race Condition

```
Symptom: intermittent failures, data races

Use the race detector first:
  go test -race ./...
  go run -race .

Then use mcp-dap-server to inspect shared state:
1. breakpoint(file="<file>", line=<access-point-1>)
2. breakpoint(file="<file>", line=<access-point-2>)
3. continue() between them, noting thread IDs
4. Look for unsynchronized reads/writes
```

---

## mcp-dap-server Command Reference

| Command | Description |
|---------|-------------|
| `debug(mode="source", path=..., debugger="delve")` | Start source debug session |
| `debug(mode="binary", path=..., debugger="delve")` | Start pre-built binary session |
| `debug(mode="core", path=..., coreFilePath=..., debugger="delve")` | Start core dump session |
| `debug(mode="attach", processId=<PID>, debugger="delve")` | Attach to running process |
| `breakpoint(file=..., line=N)` | Set file:line breakpoint |
| `breakpoint(function=...)` | Set function breakpoint |
| `clear-breakpoints()` | Remove all breakpoints |
| `clear-breakpoints(file=...)` | Remove breakpoints in file |
| `continue()` | Run until next breakpoint or end |
| `step(mode="over")` | Step over to next line |
| `step(mode="in")` | Step into function call |
| `step(mode="out")` | Run until function returns |
| `pause()` | Pause a running program |
| `context()` | Get location, stack, variables |
| `context(threadId=N)` | Switch to thread/goroutine N |
| `context(frameId=N)` | Switch to stack frame N |
| `evaluate(expression=...)` | Evaluate expression |
| `info(kind="threads")` | List all goroutines |
| `info(kind="sources")` | List source files |
| `info(kind="modules")` | List loaded modules |
| `set-variable(variablesReference=..., name=..., value=...)` | Modify variable (capability-gated) |
| `disassemble(address=..., count=N)` | Disassemble (capability-gated) |
| `restart()` | Restart session (capability-gated) |
| `stop()` | End session and kill debuggee |
| `stop(detach=true)` | End session, leave process running |

---

## How to Present Findings

State clearly:

> **Bug found at** `handler.go:142` in `CreateUser`.
> **Variable** `user` **is nil** when it should be `*User{ID: 42, Name: "alice"}`.
> **Root cause:** `getUserByID()` returns `nil` on cache miss without error, but the caller at line 140 doesn't check the error return.
> **Fix:** Add nil check (or handle the error from `getUserByID()` before dereferencing `user.Name`).

---

## When Not to Use This Skill

- **Crash dump analysis** — use `go-debug-core-dump` for post-mortem via `debug(mode="core")`
- **Attaching to production process** — use `go-debug-attach` for careful attach/detach
- **Race condition detection** — use `go test -race` first, then debug with mcp-dap-server
- **Performance profiling** — use `pprof` instead (CPU, memory, mutex profiles)
