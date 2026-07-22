---
name: python-debug-details
description: Advanced Python debugging techniques — async inspection, C extensions, post-mortem analysis, core dump debugging, and multi-process debugging with debugpy and mcp-dap-server.
---

# Advanced Python Debugging Techniques

Deep-dive reference for scenarios beyond basic source and attach debugging. Cross-references: [debug-source.md](../debug-source.md), [debug-attach.md](../debug-attach.md), [debug-test.md](../debug-test.md).

---

## Debugging Async Code (asyncio)

asyncio programs have multiple coroutines suspended on an event loop. Standard stack traces only show the currently-running coroutine; you must inspect the event loop and all tasks to understand the full picture.

### Inspecting the Event Loop

```json
evaluate(expression="asyncio.get_running_loop()")
```

```json
evaluate(expression="asyncio.get_event_loop()")
```

### Listing All Tasks

```json
evaluate(expression="asyncio.all_tasks()")
```

Returns a set of all active `Task` objects. Inspect each:

```json
evaluate(expression="[t for t in asyncio.all_tasks() if not t.done()]")
```

```json
evaluate(expression="[t.get_name() for t in asyncio.all_tasks()]")
```

### Inspecting a Specific Task

```json
evaluate(expression="task.get_coro()")
```

```json
evaluate(expression="task.get_stack()")
```

`get_stack()` returns the list of frame objects for a suspended coroutine — this is how you see where each async function is parked.

### Event Loop Debug Mode

Enable asyncio's built-in debug mode to catch common async bugs (slow callbacks, unawaited coroutines, thread-unsafe loop access):

```python
import asyncio
asyncio.get_event_loop().set_debug(True)
```

Or via environment variable:
```bash
PYTHONASYNCIODEBUG=1 python -m myapp.server
```

Debug mode logs:
- Coroutines that took too long (> 100ms by default)
- Unawaited coroutines (warnings)
- Thread-unsafe event loop access

### Common Async Debugging Patterns

**Coroutine never scheduled:**
```
1. evaluate(expression="asyncio.all_tasks()")  // is the coroutine in the set?
2. If missing → the coroutine was created but never awaited or scheduled
3. Fix: add `await` or `asyncio.create_task(coro)`
```

**Event loop blocked:**
```
1. Enable PYTHONASYNCIODEBUG=1
2. Look for "Executing <Task ...> took X seconds" warnings
3. Set breakpoint in the slow function
4. The blocking call is usually a sync I/O or CPU-bound operation in an async function
```

**Task stuck on await:**
```
1. evaluate(expression="task.get_stack()")  // where is it parked?
2. The top frame shows the await point
3. Is the awaited future ever resolved? Is the producer running?
```

---

## Debugging C Extensions

Python C extensions (CPython native modules, Cython, ctypes, cffi) require GDB with Python support to inspect Python-level state from a native debugger.

### GDB with Python Support

The `mcp-dap-server` `debug` tool with `debugger="gdb"` provides GDB's DAP mode. For C extension debugging, use GDB's Python-specific commands:

```bash
gdb -ex "py-bt" -ex "py-locals" -ex "py-list" /path/to/python
```

GDB Python commands (available when GDB is built with Python scripting):

| Command | Description |
|---------|-------------|
| `py-bt` | Python-level backtrace |
| `py-locals` | Python local variables in current frame |
| `py-list` | Python source listing around current line |
| `py-up` / `py-down` | Navigate Python frames |
| `py-print <expr>` | Evaluate Python expression |
| `info threads` | List all threads (OS-level) |

### Debugging a Crash in a C Extension

```json
debug(mode="source", path="/abs/path/to/project", debugger="gdb")
```

Set a breakpoint at the C extension function:
```json
breakpoint(function="PyInit__mymodule")
```

Or at the C source level (if symbols are available):
```
(gdb) break mymodule.c:142
```

When the extension segfaults, GDB catches the signal. Use `py-bt` to see the Python call chain that led into the C code:

```
(gdb) py-bt
Traceback (most recent call last):
  File "app/native.py", line 10, in process
    mymodule.process_data(data)
  File "build/mymodule.c", line 142, in _process_data
    ...
```

### Cython Modules

Cython generates C code from `.pyx` files. To debug:

```bash
cython --gdb mymodule.pyx   # generate with debug info
gcc -g -shared ...           # compile with debug symbols
```

Then debug with GDB as above — the generated C has line mappings back to the `.pyx` source.

### Post-Mortem of a C-Level Crash

```bash
gdb /path/to/python /path/to/core
(gdb) py-bt
(gdb) py-locals
(gdb) bt      # native backtrace
```

---

## Post-Mortem Analysis

Post-mortem debugging inspects program state **after** an exception or crash, without re-running the program.

### debugpy Post-Mortem (Live Process)

If the process is still alive but crashed into an exception handler:

```python
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()  # block until debugger attaches
```

Place this in an `except` block to pause on failure:
```python
try:
    result = risky_operation()
except Exception:
    import debugpy
    debugpy.listen(5678)
    debugpy.wait_for_client()
    raise
```

Then attach via `mcp-dap-server`:
```json
debug(mode="attach", processId=<PID>, debugger="gdb")
```

### faulthandler Module

The `faulthandler` standard library module dumps tracebacks on crashes without a debugger:

```python
import faulthandler
faulthandler.enable()                        # dump on SIGSEGV/SIGFPE
faulthandler.dump_traceback_later(30)         # dump after 30s hang
faulthandler.register(SIGUSR1)               # dump on SIGUSR1
```

Enable at startup:
```bash
python -X faulthandler -m myapp.server
# or
PYTHONFAULTHANDLER=1 python -m myapp.server
```

Dump stacks of a running process:
```bash
kill -SIGUSR1 <PID>   # if faulthandler.register(SIGUSR1) was called
```

### pdb Post-Mortem (Fallback, Not DAP-Integrated)

For quick terminal post-mortem without `mcp-dap-server`:
```bash
python -m pdb -c continue script.py
# on exception, drops into (Pdb) at the failure point
```

Note: `pdb` is the standard library debugger and does **not** support the DAP protocol. Use `pdb` only for quick interactive post-mortem in a terminal; use `debugpy` + `mcp-dap-server` for structured stepping and variable inspection.

---

## Core Dump Debugging

When a Python process crashes with a core dump (segfault, typically from a C extension), analyze the core file with GDB.

### Enable Core Dumps

```bash
ulimit -c unlimited           # current shell
# or persist:
echo '* soft core unlimited' | sudo tee -a /etc/security/limits.conf
```

### Debug a Core Dump via mcp-dap-server

```json
debug(mode="core", path="/path/to/python", coreFilePath="/path/to/core", debugger="gdb")
```

`path` is the Python interpreter binary that produced the core; `coreFilePath` is the core dump file.

### Manual GDB Core Analysis

```bash
gdb /path/to/python /path/to/core
(gdb) py-bt        # Python backtrace
(gdb) py-locals    # Python locals
(gdb) bt           # native backtrace
(gdb) info threads # all threads
```

### Core Dump from a Container

```bash
# In the container, enable core dumps and note the interpreter path
docker exec <container> python -c "import sys; print(sys.executable)"
# Copy the core out
docker cp <container>:/path/to/core /tmp/core
# Debug on host with the matching interpreter
gdb /path/to/interpreter /tmp/core
```

---

## Multi-Process Debugging

Python programs often spawn subprocesses (`multiprocessing`, `subprocess`, `concurrent.futures.ProcessPoolExecutor`). Each subprocess has its own interpreter and needs its own debug session.

### debugpy Multi-Process

`debugpy` supports child-process debugging via the `--listen` flag with `subprocess` configuration:

```python
# Parent process
import debugpy
debugpy.listen(5678)
# Configure children to connect back
debugpy.configure(subprocesses=True)
```

Or via environment:
```bash
PYTHONDEBUGPY=1 python -m myapp.server
```

### Attaching to a Specific Subprocess

Find the subprocess PID:
```bash
pgrep -P <parent_pid>   # direct children
pgrep -f "python.*worker"  # by command pattern
```

Attach to each subprocess individually:
```json
debug(mode="attach", processId=<child_pid>, debugger="gdb")
```

### multiprocessing Debugging

`multiprocessing` forks or spawns new interpreters. To debug a worker:

```python
# In the worker function
import debugpy
debugpy.listen(0)  # auto-assign port
port = debugpy.listen(None)  # get the port
print(f"Worker listening on {port}")
debugpy.wait_for_client()
```

Then attach to the worker's port from `mcp-dap-server`.

### subprocess Debugging

For `subprocess.Popen` children, inject `debugpy` at launch:

```python
import subprocess, debugpy
proc = subprocess.Popen([
    sys.executable, "-m", "debugpy", "--listen", "5679",
    "--wait-for-client", "-m", "child_module"
])
# Attach to port 5679
```

### Common Multi-Process Patterns

**Child process crashes silently:**
```
1. Set debugpy.listen in the child entry point
2. Attach to the child PID/port
3. Set breakpoint in the child's main function
4. continue() and reproduce
```

**Deadlock between parent and child (Pipe/Queue):**
```
1. Attach to parent → evaluate(expression="pipe.poll()")  // is data available?
2. Attach to child  → evaluate(expression="pipe.poll()")  // is data available?
3. If both blocked on read → no producer; check who should write
```

---


---

## DAP Messaging Layer

debugpy implements the DAP base protocol in `debugpy.common.messaging`:

### JsonIOStream

Wraps a byte-level reader/writer pair and speaks the DAP wire format:

```
Content-Length: <bytes>\r\n\r\n<JSON payload>
```

Key methods:
```python
stream = JsonIOStream.from_stdio()              # stdio-based channel
stream = JsonIOStream.from_socket(sock)         # socket-based channel
stream = JsonIOStream.from_process(process)     # subprocess stdin/stdout

value = stream.read_json()                      # read one DAP message
stream.write_json({"seq": 1, "type": "request", ...})  # write one DAP message
```

### JsonMessageChannel

Higher-level message channel on top of JsonIOStream. Handles
request/response correlation, event dispatch, and handler routing:

```python
channel = JsonMessageChannel(stream, handlers=my_handler_obj)
channel.start()  # begins message processing on a background thread

# Sending requests:
response = channel.request("someCommand", {"arg": "value"})

# Sending events:
channel.send_event("someEvent", {"data": "..."})
```

### DAP Protocol Implementation

The adapter (`debugpy.adapter`) implements the full DAP protocol:

- **clients.py**: `Client` component -- handles the client side of DAP.
  Receives `initialize`, `launch`, `attach`, `setBreakpoints`,
  `configurationDone`, `continue`, `next`, `stepIn`, `stepOut`, `pause`,
  `evaluate`, `variables`, `scopes`, `stackTrace`, `threads`, `goto`,
  `gotoTargets`, `setExceptionBreakpoints`, `exceptionInfo`, `disconnect`.

- **servers.py**: `Server` component -- talks to pydevd in the debuggee.
  Handles breakpoint setting, thread events, module events, output events.

- **launchers.py**: `Launcher` component -- manages the debuggee process in
  launch mode. Handles process events, output events, exit/terminated events.

- **sessions.py**: `Session` -- owns the lifecycle of one debug session.
  Synchronizes access via `threading.RLock`. Components notify the session
  of state changes via the Observable pattern.

## Session Lifecycle

A debug session goes through these states:

```
Client connects (stdio or socket)
  -> Session created (sessions.Session)
     -> Client component registered (clients.Client)
        -> "initialize" request received
           -> capabilities exchanged
              -> "launch" or "attach" request
                 -> Launcher spawned (launch) or Server connected (attach)
                    -> "initialized" event sent
                       -> Client sends "setBreakpoints", etc.
                          -> "configurationDone" request
                             -> Debuggee starts running
                                -> ... breakpoints, stepping, evaluation ...
                                   -> "disconnect" or "terminated"
                                      -> Session finalized
                                         -> Components disconnected
                                            -> Session removed from global set
```

Session synchronization:
- All message handlers acquire `session.lock` (a `threading.RLock`)
- Only one handler runs at a time across all components in the session
- `session.wait_for(predicate)` releases the lock temporarily while waiting
- Components use `util.Observable` to notify Session of attribute changes

## Logging Infrastructure Details

debugpy's `debugpy.common.log` module provides structured logging:

```python
from debugpy.common import log

# Direct logging:
log.debug("message {0}", arg)
log.info("message {0}", arg)
log.warning("message {0}", arg)
log.error("message {0}", arg)

# Exception handling:
log.swallow_exception("Optional context: {0}", arg)   # log+continue
log.reraise_exception("Fatal context: {0}", arg)       # log+raise

# Environment description:
log.describe_environment("Header:")  # logs platform, Python, debugpy version

# Log file management:
log.to_file(prefix="debugpy.server")  # creates debugpy.server-<pid>.log
```

Log files are named `debugpy.<component>-<pid>.log` and written to
`DEBUGPY_LOG_DIR` (or `log.log_dir`).

## Socket Utilities

debugpy's `debugpy.common.sockets` provides robust socket handling:

```python
from debugpy.common import sockets

# Server socket:
server = sockets.create_server(host, port, timeout=30)
host, port = sockets.get_address(server)

# Client socket:
client = sockets.create_client(ipv6=False)
client.connect((host, port))

# Localhost resolution:
host = sockets.get_default_localhost()  # prefers IPv4, falls back to ::1

# Socket cleanup:
sockets.close_socket(sock)
```

Key behaviors:
- `create_server` uses `SO_REUSEADDR` on POSIX, `SO_EXCLUSIVEADDRUSE` on Windows
- `get_default_localhost` tries IPv4 first, falls back to IPv6

## Stack Dumping Utilities

`debugpy.common.stacks` provides process-wide stack dumps:

```python
from debugpy.common import stacks

# Dump all thread stacks (except current thread):
stacks.dump()

# Schedule a delayed dump (for hang detection):
stacks.dump_after(5)
```

The dump iterates `sys._current_frames()`, maps thread IDs to names via
`threading.enumerate()`, and logs formatted stack traces via `log.info()`.

## Observable Property Pattern

Components use `util.Observable` to notify sessions of state changes:

```python
from debugpy.common.util import Observable

class MyComponent(Observable):
    def __init__(self):
        super().__init__()
        self.observers = []

    def __setattr__(self, name, value):
        try:
            return super().__setattr__(name, value)
        finally:
            for ob in self.observers:
                ob(self, name)
```

The session registers an observer on each component; when any attribute
changes, the session's condition variable is notified, waking up any
thread waiting in `session.wait_for()`.

## JSON Serialization

debugpy's `debugpy.common.json` extends the standard library:

```python
from debugpy.common import json

# JsonEncoder -- supports __getstate__ protocol:
class MyObject:
    def __getstate__(self):
        return {"custom": "representation"}
# Objects with __getstate__ are serialized via their state

# JsonObject -- pretty-print wrapper:
obj = json.JsonObject({"key": "value"})
print(obj)           # formatted JSON with indent=4
print(f"{obj}")      # same
print(f"{obj:indent=2,sort_keys=True}")  # custom encoder args

# Type validators (for DAP message validation):
# json.array(type), json.object((key_type, value_type)), json.enum(...)
```

## Launcher Process Management

The launcher (`debugpy.launcher`) manages the debuggee process lifecycle:

```python
# Spawning the debuggee:
debuggee.spawn(process_name, cmdline, env, redirect_output)

# The launcher:
# 1. Creates pipes for stdout/stderr capture (if redirect_output=True)
# 2. On POSIX: sets up a new process group, foreground terminal
# 3. On Windows: assigns to a job object for tree-kill support
# 4. Sends DAP "process" event with PID
# 5. Starts output capture threads
# 6. Waits for exit in a background thread

# Killing the process tree:
# - POSIX: os.killpg(pid, SIGKILL)
# - Windows: TerminateJobObject(job_handle)

# Wait-on-exit predicates:
debuggee.wait_on_exit_predicates.append(lambda code: code != 0)
# If any predicate returns True, launcher pauses for user input before exiting
```

### Output Capture

The `debugpy.launcher.output.CaptureOutput` class:
- Reads from a pipe FD in a background thread
- Decodes UTF-8 with surrogateescape
- Sends DAP "output" events with the captured text
- Tees to the original stream for terminal viewing
- Handles encoding fallback if the terminal encoding is unsupported

## Common Utilities Reference

| Module | Utility | Purpose |
|--------|---------|---------|
| `util.evaluate(code)` | Evaluate Python code in caller's context | Safe expression evaluation |
| `util.force_str(s, encoding)` | Convert bytes to str | Cross-version string coercion |
| `util.force_bytes(s, encoding)` | Convert str to bytes | Cross-version byte coercion |
| `util.nameof(obj)` | Get qualified name of any object | Debug logging |
| `util.hide_debugpy_internals()` | Check if debugpy frames should be hidden | Stack filtering |
| `util.hide_thread_from_debugger(thread)` | Exclude a thread from debugger visibility | Internal thread management |
| `timestamp.reset()` | Reset timestamp counter | Log synchronisation |
| `singleton.Singleton` | Thread-safe singleton base class | Component lifecycle |

## Cross-References
- [debug-source.md](../debug-source.md) — source-level debugging workflow
- [debug-attach.md](../debug-attach.md) — attach to running process
- [debug-test.md](../debug-test.md) — pytest test debugging
- [../python/features/async.md](../python/features/async.md) — async programming patterns
- [../python/features/testing.md](../python/features/testing.md) — pytest fixtures and patterns
- [../python/features/performance.md](../python/features/performance.md) — profiling (cProfile, py-spy, memray)