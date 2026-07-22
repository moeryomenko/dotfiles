---
name: python-debug-source
description: Live source-level debugging of Python programs via mcp-dap-server with debugpy. Use when stepping through Python code, finding bugs, inspecting runtime state, or debugging a Python program from source.
---

# Python Source-Level Debugging (mcp-dap-server + debugpy)

## Pre-flight Checklist

Before starting, gather:
1. **Python project root** — the directory containing `pyproject.toml`, `setup.py`, or the script's parent directory
2. **What is the bug or behavior?** — form your hypothesis
3. **Which function/file is most likely involved?** — first breakpoint target
4. **Virtual environment activated?** — `source .venv/bin/activate` or `uv sync` so `debugpy` resolves
5. **debugpy installed?** — `pip install debugpy` or `uv pip install debugpy`; verify with `python -c "import debugpy; print(debugpy.__version__)"`
6. **Program arguments?** — pass via `args=["arg1", "arg2"]` parameter
7. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

---

## Step-by-Step Workflow

### 1. Start a Debug Session

**Debug a Python script from source (recommended):**
```json
debug(mode="source", path="/abs/path/to/project", debugger="gdb")
```

**With program arguments:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["--port", "8080", "--config", "dev.yaml"],
  debugger="gdb"
)
```

**Debug a specific module (alternative entry point):**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["-m", "myapp.server"],
  debugger="gdb"
)
```

**Debug a single script file directly:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["scripts/run_migration.py"],
  debugger="gdb"
)
```

Expected: Debugger starts, pauses at the first executable line or entry point. You receive location, stack trace, and variables.

If start fails:
- Verify `debugpy` is importable in the target venv (`python -c "import debugpy"`)
- Ensure `path` is absolute and points at the project root
- Check the script compiles cleanly (`python -m py_compile scripts/run.py`)
- For module mode: ensure the module is installed or on `PYTHONPATH`

### CLI Reference for `python -m debugpy`

When you need to run a program under debugpy from the command line (e.g., outside
mcp-dap-server), the full CLI syntax is:

```
debugpy --listen | --connect [<host>:]<port>
         [--wait-for-client]
         [--configure-<name> <value>]...
         [--log-to <path>] [--log-to-stderr]
         [--parent-session-pid <pid>]
         [--adapter-access-token <token>]
         [--disable-sys-remote-exec]
         <filename> | -m <module> | -c <code> | --pid <pid>
         [<arg>]...
```

#### CLI Flags

| Flag | Description |
|------|-------------|
| `--listen <host>:<port>` | Listen for DAP client connection on address. If host omitted, defaults to 127.0.0.1. Mutually exclusive with --connect. |
| `--connect <host>:<port>` | Connect to an already-running adapter. Mutually exclusive with --listen. |
| `--wait-for-client` | Block startup until a DAP client connects. Use when you need to set breakpoints before any code runs. |
| `--configure-<name> <value>` | Set a debug configuration property at startup. E.g., `--configure-subProcess False`, `--configure-qt pyside2`. |
| `--log-to <path>` | Write debugpy logs to the specified directory. |
| `--log-to-stderr` | Write debugpy logs to stderr. |
| `--parent-session-pid <pid>` | Associate this session with a parent session PID (used with --connect when the process is not an immediate child of the parent). |
| `--adapter-access-token <token>` | Token for adapter authentication (required with --connect if the adapter expects one). |
| `--disable-sys-remote-exec` | Disable PEP 768 sys.remote_exec() fallback when attaching by PID. Forces legacy pydevd code injection. |

#### Target Types

debugpy supports 4 target types:

| Target | CLI Syntax | Description |
|--------|------------|-------------|
| **File** | `python -m debugpy --listen 5678 script.py` | Run a Python script file. Adds script's parent directory to sys.path. |
| **Module** | `python -m debugpy --listen 5678 -m mypackage.mymodule` | Run a module. Uses `runpy._run_module_as_main()` for correct `__name__ == "__main__"`. |
| **Code** | `python -m debugpy --listen 5678 -c "print('hello')"` | Run inline Python code. |
| **PID** | `python -m debugpy --listen 5678 --pid <PID>` | Attach to a running process by PID (see debug-attach.md). |

#### Environment Variable Configuration

CLI arguments can also be set via environment:

```bash
export DEBUGPY_EXTRA_ARGV="--configure-subProcess False --log-to /tmp/debugpy-logs"
python -m debugpy --listen 5678 script.py
```

Command-line arguments take precedence over `DEBUGPY_EXTRA_ARGV`.

#### Debugging with --wait-for-client

When you need to catch breakpoints from the very first line of your program:

```bash
python -m debugpy --listen 5678 --wait-for-client -m myapp.server
```

The process blocks at startup until a DAP client connects. Use this to set
breakpoints in `__init__`, module-level code, or dependency setup.

### 2. Set Strategic Breakpoints

Set breakpoints **before continuing**, at the functions you want to investigate:

```json
breakpoint(function="main")
```

```json
breakpoint(file="/abs/path/to/handler.py", line=42)
```

```json
breakpoint(function="app.handlers.create_user")
```

```json
breakpoint(function="models.User.save")
```

**Choose locations based on your hypothesis:**
- Entry to the suspicious function
- Just before the condition you think is wrong
- At exception raise paths (`raise` statements)

**Clear breakpoints when done with them:**
```json
clear-breakpoints(file="/abs/path/to/handler.py")
```

### 3. Run to the First Interesting Point

```json
continue()
```

Execution pauses at your first breakpoint. The response includes:
- Current file/line
- Function call stack
- Local variables
- Thread ID

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

**Evaluate specific expressions (Python syntax):**
```json
evaluate(expression="user")
```

```json
evaluate(expression="user.address.city")
```

```json
evaluate(expression="items[0]")
```

```json
evaluate(expression="len(queue)")
```

```json
evaluate(expression="str(exc)")
```

```json
evaluate(expression="name.startswith('admin')")
```

**Navigate the call stack:**
```json
context(frameId=<N>)
```

Frame IDs come from the stack trace returned by `context()` — use them to walk up/down the call chain and inspect variables from each frame.

**Decision guide:**
- Value is `None` when it shouldn't be → trace back where it was assigned or returned
- Value is wrong → find where it was assigned incorrectly
- Value is correct here → the bug is downstream; add a later breakpoint

### 5. Step Through Logic

```json
step(mode="over")
```

*Execute current line, stay in same function (step over function calls).*

```json
step(mode="in")
```

*Step into the function being called.*

```json
step(mode="out")
```

*Run until current function returns.*

**When to use each:**
- `over`: when you don't suspect the called function
- `in`: when the called function is suspicious
- `out`: when you've seen enough in the current function

After each step, call `context()` or `evaluate()` to check if values changed as expected.

### 6. Examine Threads (Concurrent Programs)

```json
info(kind="threads")
```

This lists all Python threads with their locations. Look for:
- **Threads blocked on `threading.Event.wait`** — potential deadlock
- **Threads in `threading.Lock.acquire`** — lock contention
- **Unexpectedly many threads** — thread leak
- **Main thread in unexpected state** — main flow issue

Inspect suspicious threads:
```json
context(threadId=<ID>)
```

**Deadlock detection pattern:**
```
info(kind="threads") shows:
  Thread 1: threading.Lock.acquire
  Thread 4: threading.Lock.acquire
→ Switch to each with context(threadId=<ID>), inspect their stack + locals
```



### Thread Registration for Non-Python Threads

If your program creates threads via native/C APIs (ctypes, CFFI, C extensions,
embedded Python), those threads won't automatically be visible to the debugger.

Register them explicitly:
```python
import debugpy

def native_thread_worker():
    debugpy.debug_this_thread()  # must be called on the native thread itself
    # breakpoints now work on this thread
```

### Trace Control

To improve performance when breakpoints aren't expected on a specific thread:
```python
import debugpy
debugpy.trace_this_thread(False)  # disable tracing on current thread
```

Tracing is automatically disabled for all threads when no client is connected.

### Programmatic breakpoint()

Use `debugpy.breakpoint()` for a conditional / programmatic pause:
```python
import debugpy
if condition:
    debugpy.breakpoint()  # pauses like a breakpoint at the next line
```

The built-in `breakpoint()` (Python 3.7+) also works if debugpy has been
imported and has registered itself as the default handler.

### 7. Modify State
If the debugger supports it (capability-gated):
```json
set-variable(variablesReference=<ref>, name="count", value="0")
```

Then `continue()` to see if the fix works. This confirms your hypothesis before writing real code.

### 8. Trace Execution Flow

Set multiple breakpoints and continue between them:
```json
breakpoint(file="/abs/path/to/handler.py", line=100)
breakpoint(file="/abs/path/to/handler.py", line=150)
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

## Common Python Debugging Patterns

### AttributeError: 'NoneType' object has no attribute

```
Symptom: "AttributeError: 'NoneType' object has no attribute 'name'"

1. context() – or evaluate(expression="stack") gives stack automatically
   → where did it happen?
2. evaluate(expression="<suspect-var>") – which value is None?
3. Trace back: who created/returned that value?
4. Fix: add None check before attribute access, or fix the callee to return a default
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
4. evaluate(expression="len(items)") # bound
5. Does the loop variable ever reach the bound?
```

### Thread Leak

```
Symptom: thread count keeps growing

1. info(kind="threads")           # list all threads
2. Count threads at each location
3. Look for threads that never finish
4. Trace: who spawned them? Is there a way to signal them to stop?
```

### Exception Swallowed by Bare except

```
Symptom: error happens but is silently caught

1. breakpoint at the "except:" line
2. continue()
3. evaluate(expression="exc")   # the caught exception
4. context()                     # find what triggered it
```

### Import Error / Circular Import

```
Symptom: "ImportError: cannot import name X" or "partially initialized module"

1. breakpoint(function="importlib._bootstrap._find_and_load")
2. continue()
3. evaluate(expression="name")   # which module is loading
4. context() to walk the stack — who triggered the import?
```

### Launch hangs with no breakpoint hit

```
Symptom: debugpy starts but program never pauses at breakpoints

1. Did you use --wait-for-client? If so, the program waits at startup.
2. Connect a DAP client, then continue().
3. Check that breakpoints are set in code that actually executes.
4. For Python 3.11+, pydevd may need `-X frozen_modules=off`:
   debug(mode="source", path="/path", args=["-X", "frozen_modules=off", "-m", "pytest", ...])
```

### Program exits before breakpoint hits (early startup breakpoints)

```
Symptom: breakpoints in startup/init code never trigger

1. Use --wait-for-client to pause before any code runs.
2. Set all breakpoints.
3. Continue() to let the program start and hit the first breakpoint.
```

---

## mcp-dap-server Command Reference


| Command | Description |
|---------|-------------|
| `debug(mode="source", path=..., debugger="gdb")` | Start source debug session |
| `debug(mode="binary", path=..., debugger="gdb")` | Start pre-built binary session |
| `debug(mode="core", path=..., coreFilePath=..., debugger="gdb")` | Start core dump session |
| `debug(mode="attach", processId=<PID>, debugger="gdb")` | Attach to running process |
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
| `context(threadId=N)` | Switch to thread N |
| `context(frameId=N)` | Switch to stack frame N |
| `evaluate(expression=...)` | Evaluate Python expression |
| `info(kind="threads")` | List all threads |
| `info(kind="sources")` | List source files |
| `info(kind="modules")` | List loaded modules |
| `set-variable(variablesReference=..., name=..., value=...)` | Modify variable (capability-gated) |
| `restart()` | Restart session (capability-gated) |
| `stop()` | End session and kill debuggee |
| `stop(detach=true)` | End session, leave process running |

---

## How to Present Findings

State clearly:

> **Bug found at** `handler.py:142` in `create_user`.
> **Variable** `user` **is None** when it should be `User(id=42, name="alice")`.
> **Root cause:** `get_user_by_id()` returns `None` on cache miss without raising, but the caller at line 140 doesn't check the return value.
> **Fix:** Add a `None` check (or raise an exception from `get_user_by_id()` before accessing `user.name`).

---

## When Not to Use This Skill

- **Crash dump analysis** — use `references/details.md` for post-mortem via `debug(mode="core")`
- **Attaching to production process** — use [debug-attach.md](debug-attach.md) for careful attach/detach
- **Debugging pytest tests** — use [debug-test.md](debug-test.md) for test-specific workflows
- **Performance profiling** — use `cProfile`, `py-spy`, or `memray` instead