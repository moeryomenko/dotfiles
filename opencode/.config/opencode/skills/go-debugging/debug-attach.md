---
name: go-debug-attach
description: Live debugging by attaching mcp-dap-server to a running Go process via Delve. Use when investigating a live Go process by PID, diagnosing production issues, analyzing high CPU/deadlocks, or inspecting goroutine state in a running server.
---

# Live Attach Debugging (mcp-dap-server + Delve)

## Pre-flight Checklist

Before starting, gather:
1. **PID** of the target process (`ps aux | grep <name>` or `pgrep <name>`)
2. **Observed problem** — high CPU, hang, wrong behavior, memory leak
3. **Is this a production process?** Setting breakpoints pauses it for all users
4. **Binary path** — needed for source mapping (use `readlink -f /proc/<PID>/exe`)
5. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

## Important Warnings

- Attaching **pauses the process**. In production, this affects real users.
- `stop()` **kills the process** by default. Use `stop(detach=true)` to leave it running.
- You may need `sudo` or ptrace permissions: `echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`

---

## Step-by-Step Workflow

### 1. Attach to the Process

```json
debug(mode="attach", processId=<PID>, debugger="delve")
```

Expected: The process pauses. You receive the current execution location, stack trace, and local variables.

If attach fails:
- **Permission denied**: check `/proc/sys/kernel/yama/ptrace_scope` (0 = unrestricted) or run the mcp-dap-server process with `sudo`
- **Process not found**: `ps -p <PID>` to verify it's still running
- **Binary rebuilt since start**: Delve should still work; symbols may be slightly different

### 2. Understand What the Process Was Doing

The `debug()` call already returns the initial context at the moment of attach — review it immediately. Key questions:
- **Where is it?** What function and file?
- **Why is it there?** Does the stack trace make sense?
- **What are the local values?** Do they look reasonable?

If the process was in a system call (I/O, sleep, mutex wait), the stack shows that explicitly.

### 3. Check All Goroutines

```json
info(kind="threads")
```

This is critical for Go programs. Look for:

**Deadlock indicators:**
- Multiple goroutines at `sync.(*Mutex).Lock` or `sync.(*RWMutex).Lock`
- Goroutines blocked on `chan receive` / `chan send`
- No goroutine making progress

**Goroutine leak indicators:**
- More goroutines than expected
- Goroutines stuck at `runtime.park` (blocked on channel/select)
- Goroutines in unexpected locations

**Hot path indicators (high CPU):**
- Goroutines repeatedly in the same function
- Tight loops with no I/O or sleep calls

For each suspicious goroutine:
```json
context(threadId=<ID>)
```
Then inspect its stack and variables with `context()` output.

### 4. Scenario-Specific Investigation

#### High CPU Usage

Pause several times and look for patterns:
```json
pause()      // if the process was resumed
context()    // inspect current location
```

Repeat 3-5 times. If the same function keeps appearing, that's the hot path.

Alternative: use `SIGQUIT` to dump all goroutine stacks without Delve:
```bash
kill -3 <PID>   # writes stack traces to stderr / log
```

Once you identify the hot path, set breakpoints and inspect:
```json
breakpoint(function="hotFunction")
continue()
evaluate(expression="<suspect-values>")
```

#### Deadlock / Hang

```
info(kind="threads")
  Goroutine 1: sync.(*Mutex).Lock  → waiting for lock
  Goroutine 5: sync.(*Mutex).Lock  → also waiting for lock

context(threadId=1)
  → what code is trying to acquire the lock?

context(threadId=5)
  → what code is trying to acquire the lock?
```

**Circular deadlock pattern:**
```
Goroutine 1 holds lock A, waits for lock B
Goroutine 5 holds lock B, waits for lock A
→ Lock ordering inversion. Fix: always acquire locks in the same order.
```

**Channel deadlock pattern:**
```
Goroutine 1: chan receive on chA
Goroutine 5: chan receive on chB
And no goroutine is sending on either channel.
→ Check who should be sending. Was the sender started?
```

#### Memory Growth / Leak

Inspect collection sizes via evaluate:
```json
evaluate(expression="len(cache)")
evaluate(expression="len(connections)")
evaluate(expression="cap(buffer)")
```

Look for:
- Collections that grow but never shrink
- Goroutines accumulating in `info(kind="threads")` output
- Each re-attach shows more goroutines at the same location

#### Unexpected Behavior / Wrong Results

Set a targeted breakpoint at the function producing wrong output:
```json
breakpoint(function="pkg.FunctionName")
continue()
evaluate(expression="<input-params>")
```

Compare input values to expected. Single-step through the logic with `step(mode="over")`.

### 5. Detach (Leave Process Running)

To **detach** and leave the process running:
```json
stop(detach=true)
```

To **terminate** the debuggee:
```json
stop()
```

---

## Common Patterns

### All Goroutines Blocked on Mutex

```
→ Classic deadlock from lock ordering inversion
→ Use info(kind="threads") + context(threadId=...) to identify lock order
→ Fix: establish consistent lock acquisition order
```

### Many Goroutines in runtime.park

```
→ Goroutines blocked on channels/select
→ Check who should be sending/receiving
→ Common: missing sender, closed channel, or channel direction reversed
```

### Single Goroutine Consuming 100% CPU

```
→ Infinite loop or busy-wait
→ Attach, check the goroutine's stack via context()
→ Look for loop conditions that never terminate
```

### Goroutine Count Growing Over Time

```
→ Goroutine leak
→ Find goroutine that never completes
→ Check if there's a way to signal it to stop (context cancellation, channel close)
→ Common: spawned goroutine but never called cancel() on context
```

---

## Direct Stack Inspection Without Delve

When you can't attach a debugger, use `SIGQUIT`:
```bash
kill -3 <PID>
# Goroutine stacks are written to stderr; check application logs
```

This is safe for production — it doesn't pause the process.

---

## How to Present Findings

> **Diagnosis:** The process is deadlocked between goroutines 1 and 5.
> **Evidence:** Goroutine 1 is at `sync.Mutex.Lock` waiting for lock B (held by goroutine 5). Goroutine 5 is at `sync.Mutex.Lock` waiting for lock A (held by goroutine 1).
> **Root cause:** `ProcessRequest` acquires locks A→B, while `HandleCallback` acquires B→A, creating a lock-ordering inversion.
> **Fix:** Establish a consistent lock acquisition order across all code paths.

---

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Attach | `debug(mode="attach", processId=<PID>)` | Pause and inspect process |
| List goroutines | `info(kind="threads")` | See all goroutines |
| Inspect one | `context(threadId=N)` | Understand what it's doing |
| Inspect variables | `evaluate(expression=...)` | See current state |
| Set breakpoint | `breakpoint(file=..., line=N)` or `breakpoint(function=...)` | Pause at specific code |
| Resume | `continue()` | Continue execution |
| Detach (alive) | `stop(detach=true)` | Leave process running |
| Kill process | `stop()` | Terminate debuggee |
