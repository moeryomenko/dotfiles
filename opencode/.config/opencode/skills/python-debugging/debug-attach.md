---
name: python-debug-attach
description: Live debugging by attaching mcp-dap-server to a running Python process via debugpy. Use when investigating a live Python process by PID, diagnosing production issues, analyzing high CPU/deadlocks, or inspecting thread state in a running server.
---

# Live Attach Debugging (mcp-dap-server + debugpy)

## Pre-flight Checklist

Before starting, gather:
1. **PID** of the target process (`ps aux | grep python` or `pgrep -f python`)
2. **Observed problem** — high CPU, hang, wrong behavior, memory leak
3. **Is this a production process?** Setting breakpoints pauses it for all users
4. **Virtual environment** — the venv the process was launched with (for `debugpy` to resolve)
5. **debugpy available in the target venv?** — `python -c "import debugpy"` inside the target venv
6. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

## Important Warnings

- Attaching **pauses the process**. In production, this affects real users.
- `stop()` **kills the process** by default. Use `stop(detach=true)` to leave it running.
- You may need `sudo` or ptrace permissions: `echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`
- `debugpy` attach requires the target interpreter to be able to import `debugpy`; if it can't, use the remote-listen workflow below.

---

## Step-by-Step Workflow

### 1. Find the Process ID

```bash
pgrep -f "python.*myapp"
```

```bash
ps aux | grep python | grep -v grep
```

```bash
pgrep -af python   # full command line for each match
```

Confirm the process is the one you want:
```bash
ps -p <PID> -o pid,ppid,cmd
```

### 2. Attach to the Process

**Direct attach via mcp-dap-server (GDB DAP mode):**
```json
debug(mode="attach", processId=<PID>, debugger="gdb")
```

Expected: The process pauses. You receive the current execution location, stack trace, and local variables.

If attach fails:
- **Permission denied**: check `/proc/sys/kernel/yama/ptrace_scope` (0 = unrestricted) or run the mcp-dap-server process with `sudo`
- **Process not found**: `ps -p <PID>` to verify it's still running
- **debugpy not importable**: fall back to the remote-listen workflow below

### 3. Attach by PID (Code Injection)

When the target process is already running but didn't start with debugpy, use
`--pid` to inject the debugger:

```bash
python -m debugpy --listen 0.0.0.0:5678 --pid <PID>
```

This triggers a **two-stage code injection** process:

**Stage 1 -- PEP 768 sys.remote_exec() (Python 3.14+, preferred):**
If `sys.remote_exec()` is available and `--disable-sys-remote-exec` was not set,
debugpy writes injected Python code to a temp file and passes it via
`sys.remote_exec(pid, tmp_file_path)`. The file is self-deleting after execution.

```bash
# Force legacy injection for debugging attach issues:
python -m debugpy --listen 5678 --pid <PID> --disable-sys-remote-exec
```

**Stage 2 -- pydevd_attach_to_process (fallback):**
If sys.remote_exec() is unavailable or fails, debugpy falls back to the pydevd
attach helper. This uses `add_code_to_python_process.run_python_code()` from
the `pydevd_attach_to_process` directory.

The injected code:
1. Adds the debugpy server directory to sys.path
2. Calls `attach_pid_injected.attach(setup)` which runs `debugpy.listen()` or
   `debugpy.connect()` inside the target process

**Requirements:**
- The target process must be running the same Python version and architecture
- ptrace permissions may be needed on Linux:
  ```bash
  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
  ```
- The injecting process and target process must share the same filesystem

**Diagnostics:**
```bash
# Enable verbose attach logging:
DEBUGPY_ATTACH_BY_PID_DEBUG_INFO=1 python -m debugpy --listen 5678 --pid <PID>
```

### 3b. Attach via AdapterAccessToken (Secure)

When connecting to an adapter that requires authentication:

```bash
# On the adapter side (start first):
python -m debugpy.adapter --port 5678 --server-access-token "mytoken"

# On the debuggee side (connect with token):
python -m debugpy --connect localhost:5678 --adapter-access-token "mytoken" --pid <PID>
```

### 3c. Attach with Parent Session PID

For complex process trees where the debuggee is not an immediate child of the
parent session process:

```bash
python -m debugpy --connect localhost:5678 --parent-session-pid <PPID> --pid <PID>
```

Used when a child of the parent needs to be debugged, but the connecting process
is a sibling or deeper descendant.

### 4. Understand What the Process Was Doing — useful for debugging early startup.

**Then attach from mcp-dap-server to the listening port** (treat as a remote attach):
```json
debug(mode="attach", processId=<PID>, debugger="gdb")
```

For pure remote scenarios (process on another host), point the DAP connection at the remote host:port. The `mcp-dap-server` `debug` tool's `processId` parameter targets the local PID; for cross-host remote attach, ensure `debugpy --listen` is reachable and the GDB DAP session bridges to it.

### 4. Understand What the Process Was Doing

The `debug()` call already returns the initial context at the moment of attach — review it immediately. Key questions:
- **Where is it?** What function and file?
- **Why is it there?** Does the stack trace make sense?
- **What are the local values?** Do they look reasonable?

If the process was in a system call (I/O, sleep, lock wait), the stack shows that explicitly.

### 5. Check All Threads

```json
info(kind="threads")
```

This is critical for threaded Python programs. Look for:

**Deadlock indicators:**
- Multiple threads at `threading.Lock.acquire` or `threading.RLock.acquire`
- Threads blocked on `threading.Event.wait` / `queue.Queue.get`
- No thread making progress

**Thread leak indicators:**
- More threads than expected
- Threads stuck in `threading.Condition.wait`
- Threads in unexpected locations

**Hot path indicators (high CPU):**
- Threads repeatedly in the same function
- Tight loops with no I/O or sleep calls

For each suspicious thread:
```json
context(threadId=<ID>)
```

Then inspect its stack and variables with `context()` output.


### Configuring Attach Behavior

When attaching to a running process, you may need to set configuration that
can't be set via the DAP "attach" request because it must apply before tracing
starts. Use `debugpy.configure()` from within the target process, or pass
`--configure-<name>` flags:

```bash
python -m debugpy --connect localhost:5678 --configure-subProcess False --pid <PID>
```

Available pre-attach configurations:
- `subProcess=False` -- disable auto-debugging of subprocesses
- `qt="pyside2"` -- enable Qt event loop support
- `pythonEnv={...}` -- environment variables for the adapter process

### 6. Scenario-Specific Investigation

#### High CPU Usage

Pause several times and look for patterns:
```json
pause()      // if the process was resumed
context()    // inspect current location
```

Repeat 3-5 times. If the same function keeps appearing, that's the hot path.

Alternative: dump thread stacks without a debugger using `faulthandler`:
```bash
kill -SIGUSR1 <PID>   # dumps all thread stacks to stderr
```

Once you identify the hot path, set breakpoints and inspect:
```json
breakpoint(function="hot_function")
continue()
evaluate(expression="<suspect-values>")
```

#### Deadlock / Hang

```
info(kind="threads")
  Thread 1: threading.Lock.acquire  → waiting for lock
  Thread 5: threading.Lock.acquire  → also waiting for lock

context(threadId=1)
  → what code is trying to acquire the lock?

context(threadId=5)
  → what code is trying to acquire the lock?
```

**Circular deadlock pattern:**
```
Thread 1 holds lock A, waits for lock B
Thread 5 holds lock B, waits for lock A
→ Lock ordering inversion. Fix: always acquire locks in the same order.
```

**Queue deadlock pattern:**
```
Thread 1: queue.Queue.get on qA
Thread 5: queue.Queue.get on qB
And no thread is putting on either queue.
→ Check who should be producing. Was the producer started?
```

#### Memory Growth / Leak

Inspect collection sizes via evaluate:
```json
evaluate(expression="len(cache)")
evaluate(expression="len(connections)")
evaluate(expression="sys.getsizeof(buffer)")
```

Look for:
- Collections that grow but never shrink
- Threads accumulating in `info(kind="threads")` output
- Each re-attach shows more threads at the same location

#### Unexpected Behavior / Wrong Results

Set a targeted breakpoint at the function producing wrong output:
```json
breakpoint(function="pkg.module.function_name")
continue()
evaluate(expression="<input-params>")
```

Compare input values to expected. Single-step through the logic with `step(mode="over")`.

### 7. Detach (Leave Process Running)

To **detach** and leave the process running:
```json
stop(detach=true)
```

To **terminate** the debuggee:
```json
stop()
```

For remote `debugpy --listen` sessions, detaching leaves the listener open; the process continues. To fully remove `debugpy`, the process must be restarted without the `--listen` flag.

---

## Common Patterns

### All Threads Blocked on Lock

```
→ Classic deadlock from lock ordering inversion
→ Use info(kind="threads") + context(threadId=...) to identify lock order
→ Fix: establish consistent lock acquisition order
```

### Many Threads in threading.Event.wait

```
→ Threads blocked on events/queues
→ Check who should be setting the event or putting on the queue
→ Common: missing producer, event never set, or queue consumer crashed
```

### Single Thread Consuming 100% CPU

```
→ Infinite loop or busy-wait
→ Attach, check the thread's stack via context()
→ Look for loop conditions that never terminate
```

### Thread Count Growing Over Time

```
→ Thread leak
→ Find thread that never completes
→ Check if there's a way to signal it to stop (threading.Event, cancel flag)
→ Common: spawned thread but never set the stop event
```

---

## Direct Stack Inspection Without a Debugger

When you can't attach a debugger, use `faulthandler` to dump thread stacks:
```bash
kill -SIGUSR1 <PID>
# Thread stacks are written to stderr; check application logs
```

Or enable `faulthandler` at startup for automatic dumps on crashes:
```python
import faulthandler
faulthandler.enable()
faulthandler.dump_traceback_later(30)  # dump after 30s hang
```

This is safe for production — it doesn't pause the process.

---


### debugpy Built-in Stack Dump

debugpy includes its own stack dumping utility that logs all thread stacks:

```python
from debugpy.common import stacks
stacks.dump()          # dump all thread stacks now
stacks.dump_after(5)   # dump after 5 seconds (for hang detection)
```

This is more detailed than faulthandler because it logs debugpy's internal
state along with the Python stacks. Call `stacks.dump_after(5)` just before
a suspected blocking operation -- if it hangs, the stacks are logged.

---

## How to Present Findings
> **Diagnosis:** The process is deadlocked between threads 1 and 5.
> **Evidence:** Thread 1 is at `threading.Lock.acquire` waiting for lock B (held by thread 5). Thread 5 is at `threading.Lock.acquire` waiting for lock A (held by thread 1).
> **Root cause:** `process_request` acquires locks A→B, while `handle_callback` acquires B→A, creating a lock-ordering inversion.
> **Fix:** Establish a consistent lock acquisition order across all code paths.

---

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Find PID | `pgrep -f python` or `ps aux \| grep python` | Locate target process |
| Attach | `debug(mode="attach", processId=<PID>, debugger="gdb")` | Pause and inspect process |
| Attach by PID (CLI) | `python -m debugpy --listen 5678 --pid <PID>` | Inject debugpy into running PID |
| Attach with token | add `--adapter-access-token <token>` | Authenticated attach |
| Attach with parent | add `--parent-session-pid <pid>` | Complex process tree attach |
| Verbose attach | `DEBUGPY_ATTACH_BY_PID_DEBUG_INFO=1` | Diagnose attach failures |
| Configure pre-attach | `--configure-subProcess False` | Set config before tracing starts |
| List threads | `info(kind="threads")` | See all threads |
| Inspect one | `context(threadId=N)` | Understand what it's doing |
| Inspect variables | `evaluate(expression=...)` | See current state |
| Set breakpoint | `breakpoint(file=..., line=N)` or `breakpoint(function=...)` | Pause at specific code |
| Resume | `continue()` | Continue execution |
| Detach (alive) | `stop(detach=true)` | Leave process running |
| Kill process | `stop()` | Terminate debuggee |
| Stack dump (debugpy) | `stacks.dump()` | Log all thread stacks |
| Scheduled dump | `stacks.dump_after(5)` | Schedule hang dump |
| Stack dump (no debugger) | `kill -SIGUSR1 <PID>` | Dump thread stacks to stderr |
| Disable remexec | `--disable-sys-remote-exec` | Force legacy pydevd injection |