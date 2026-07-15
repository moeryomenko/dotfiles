---
name: python-debugging
description: "Python debugging via mcp-dap-server with debugpy. Use when stepping through Python code, finding bugs, inspecting runtime state, or debugging pytest tests."
invocation_policy: automatic
---

# Python Debugging (mcp-dap-server + debugpy)

This skill provides live, interactive Python debugging through the `mcp-dap-server` MCP tool backed by the `debugpy` DAP adapter. Load automatically when stepping through Python code, diagnosing runtime bugs, inspecting live state, or debugging pytest tests.

## Configuration

- **Debug adapter**: `debugpy` (the standard DAP adapter for Python). Install with `pip install debugpy` or `uv pip install debugpy`.
- **MCP tool**: `mcp-dap-server` exposes the `debug` tool and supporting operations (`breakpoint`, `continue`, `step`, `evaluate`, `context`, `info`, `stop`).
- **Debugger parameter**: pass `debugger="gdb"` to the `debug` tool for Python targets. GDB's DAP mode drives `debugpy`-compatible sessions; for native debugpy adapter workflows use `debugpy --listen` (see debug-attach.md).
- **Virtual environment**: activate the project venv before launching the MCP server so `debugpy` resolves on `PYTHONPATH`.

## Capabilities

Route to the workflow file matching the debugging scenario:

| Scenario | File |
|----------|------|
| Debug a Python program from source (script, module, application) | [debug-source.md](debug-source.md) |
| Attach to an already-running Python process by PID | [debug-attach.md](debug-attach.md) |
| Debug pytest tests (single test, fixtures, async tests) | [debug-test.md](debug-test.md) |
| Advanced techniques (async, C extensions, post-mortem, core dumps, multi-process) | [references/details.md](references/details.md) |

## When to Use This Skill

- A Python test fails and the failure reason is unclear.
- A script produces wrong output and you need to inspect intermediate state.
- A long-running service hangs, leaks, or deadlocks and must be inspected live.
- You need post-mortem analysis of a crash or core dump.
- You need to step into a C extension or native module invoked from Python.

## When Not to Use This Skill

- **Performance profiling** — use `cProfile`, `py-spy`, or `memray` instead.
- **Static type checking** — use `mypy` or `pyright`.
- **Linting/formatting** — use `ruff` or `black`.
- **Race condition detection** — use `pytest-asyncio` with `asyncio` debug mode first, then attach.

---

## Pre-flight Checklist

Before starting any debugging workflow:

1. **Python project root** — the directory containing `pyproject.toml`, `setup.py`, or the script's parent directory
2. **What is the bug or behavior?** — form your hypothesis
3. **Which function/file is most likely involved?** — first breakpoint target
4. **Virtual environment activated?** — `source .venv/bin/activate` or `uv sync` so `debugpy` resolves
5. **debugpy installed?** — `pip install debugpy` or `uv pip install debugpy`; verify with `python -c "import debugpy; print(debugpy.__version__)"`
6. **Program arguments?** — pass via `args=["arg1", "arg2"]` parameter or pytest args
7. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered
8. **In-process vs out-of-process adapter** — debugpy normally spawns a separate adapter process. For single-process debugging without subprocess support, pass `in_process_debug_adapter=True` to `debugpy.listen()`.
9. **Target type** — debugpy supports 4 target kinds: `file`, `module` (`-m`), `code` (`-c`), and `pid` (`--pid`). Choose the right one for your scenario.

---

## debugpy Public API Reference

debugpy exposes a stable public API (defined in `debugpy/__init__.py` and `debugpy/public_api.py`). All members call through to `debugpy.server.api` under the hood via a lazy-import wrapper.

| Function | Description |
|----------|-------------|
| `debugpy.listen(address)` | Start DAP listener on `(host, port)` or port number. Returns actual `(host, port)`. Spawns a child adapter process by default. |
| `debugpy.connect(address, access_token=None, parent_session_pid=None)` | Connect to an existing adapter listening on `address`. |
| `debugpy.wait_for_client()` | Block until a DAP client connects. Cancel from another thread via `wait_for_client.cancel()`. |
| `debugpy.is_client_connected()` | Returns `True` if a client is currently connected. |
| `debugpy.breakpoint()` | Pause execution at the next line, simulating a breakpoint. Skips internal debugpy frames. |
| `debugpy.configure(properties)` | Set debug configuration properties that must be applied early. Accepts dict or kwargs. |
| `debugpy.log_to(path)` | Write detailed debugpy logs to a directory or `sys.stderr`. |
| `debugpy.debug_this_thread()` | Register a thread started outside `threading` (e.g., native C threads) so breakpoints work on it. |
| `debugpy.trace_this_thread(should_trace)` | Enable/disable tracing on the current thread. Disable to improve performance when breakpoints are not expected. |
| `debugpy.get_cli_options()` | Returns frozen `CliOptions` dataclass with parsed CLI args, or `None` if CLI entrypoint was not used. |

### CliOptions Dataclass

Returned by `debugpy.get_cli_options()`:

| Field | Type | Description |
|-------|------|-------------|
| `mode` | `"connect"` or `"listen"` | Which transport mode |
| `target_kind` | `"file"`, `"module"`, `"code"`, `"pid"` | What kind of target |
| `address` | `(host, port)` | The listen/connect address |
| `log_to` | `str or None` | Log directory path |
| `log_to_stderr` | `bool` | Whether logging to stderr |
| `target` | `str or None` | The target filename, module, code, or PID |
| `wait_for_client` | `bool` | Whether --wait-for-client was set |
| `adapter_access_token` | `str or None` | Access token for connect mode |
| `config` | `dict` | Configure properties from --configure-<name> flags |
| `parent_session_pid` | `int or None` | Parent session PID for connect |

### Configuration Properties

Set via `debugpy.configure()` or `--configure-<name> <value>` CLI flags:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `qt` | `str` | `"none"` | Qt event loop support: `"auto"`, `"none"`, `"pyside"`, `"pyside2"`, `"pyqt4"`, `"pyqt5"` |
| `subProcess` | `bool` | `True` | Auto-debug spawned subprocesses |
| `python` | `str` | `sys.executable` | Python interpreter for the adapter process |
| `pythonEnv` | `dict` | `{}` | Environment variables for the adapter process |

### Architecture Overview

debugpy uses a **three-component architecture**:

```
+-------------+     DAP over     +--------------+
|   Client    | <--- stdio/ ---> |   Adapter    |
|  (IDE/UI)   |     socket       |  (daemon)    |
+-------------+                  +------+-------+
                                        |
                    +-------------------+-------------------+
                    |                                       |
              DAP over socket                          DAP over socket
                    |                                       |
         +----------v----------+               +-----------v-----------+
         |     Launcher        |               |  Debug Server (pydevd)|
         |  (launch sessions)  |               |  (attach sessions)    |
         +----------+----------+               +-----------+-----------+
                    |                                       |
         +----------v----------+                             |
         |     Debuggee        |<----------------------------+
         | (user code + pydevd)|
         +---------------------+
```

- **Adapter**: Long-lived daemon managing sessions. Routes DAP messages between client and debug server/launcher.
- **Launcher**: Short-lived process for "launch" mode. Spawns the debuggee and connects it to the adapter. Handles output redirection.
- **Debug Server** (pydevd): Embedded in the debuggee process. Sets breakpoints, traces execution, collects stack frames.

### Modes of Operation

**listen** (`debugpy.listen(address)`):
- Spawns a child adapter process that listens for DAP client connections.
- The debuggee connects back to the adapter via pydevd's internal protocol.
- Default mode for CLI `--listen`.

**connect** (`debugpy.connect(address)`):
- Expects an existing adapter to already be listening.
- The debuggee connects to the adapter address directly.
- Used with `--connect`, `--adapter-access-token`, `--parent-session-pid`.

**in_process_debug_adapter** (`debugpy.listen(address, in_process_debug_adapter=True)`):
- No separate adapter process is spawned.
- Lighter weight, but subprocess debugging is disabled.
- Suitable for embedded Python or constrained environments.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `DEBUGPY_LOG_DIR` | Directory for debugpy log files (`debugpy.*-<pid>.log`) |
| `DEBUGPY_EXTRA_ARGV` | Extra CLI arguments parsed after command-line args. Space-separated. Command-line settings take precedence. |
| `DEBUGPY_RUNNING` | Set to `"true"` after first debug session starts. Prevents re-initialization. |
| `DEBUGPY_ATTACH_BY_PID_DEBUG_INFO` | Set to `"1"` for verbose pydevd attach-by-PID diagnostics. |
| `DEBUGPY_TEST` | When set (debugpy test suite), disables codecov conflicts. |
| `PYTHONUNBUFFERED` | Set to `"1"` by launcher when redirecting output (for real-time output). |
| `PYTHONIOENCODING` | Set to `"utf-8"` by launcher when redirecting output (for UTF-8 output). |

### Stack Dumping Utilities

debugpy includes built-in stack dumping (in `debugpy.common.stacks`):

**Dump all thread stacks at once:**
```python
from debugpy.common import stacks
stacks.dump()  # logs all threads except current
```

**Schedule a delayed dump:**
```python
stacks.dump_after(5)  # dump stacks after 5 seconds
```

Useful for diagnosing hangs: call `dump_after(secs)` just before a known blocking operation.

### Logging Infrastructure

debugpy's logging (`debugpy.common.log`) supports:

- **Per-process log files** named `debugpy.<component>-<pid>.log` in `DEBUGPY_LOG_DIR`
- **Log levels**: `debug`, `info`, `warning`, `error`
- **Component prefixes**: `debugpy.server`, `debugpy.adapter`, `debugpy.launcher`, `debugpy.tests`
- **Timestamps**: configurable precision via `log.timestamp_format` (default `"09.3f"`)
- **Swallow exceptions**: `log.swallow_exception()` for expected/non-fatal errors
- **Reraise exceptions**: `log.reraise_exception()` for unexpected errors with full context

Enable logging via `debugpy.log_to("/path/to/logdir")` or `debugpy.log_to(sys.stderr)`.

---

## Cross-Referencing

- For Python language patterns, type safety, and testing conventions, see the `python` skill (`../python/SKILL.md`) and its `features/testing.md`.
- For pytest fixture and parametrization guidance, see `../python/features/testing.md`.
- For async programming patterns, see `../python/features/async.md`.
- For packaging and project layout, see `../python/features/packaging.md` and the `python-uv` skill (`../python-uv/SKILL.md`).
- For debugpy's DAP messaging layer internals, see `references/details.md`.
- All references in this skill use relative paths. Example command parameters may contain absolute paths (e.g., `path="/abs/path/to/project"`) — those are illustrative, not navigational links.
