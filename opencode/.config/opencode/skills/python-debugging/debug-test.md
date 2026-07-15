---
name: python-debug-test
description: Debugging pytest tests via mcp-dap-server with debugpy. Use when a pytest test fails and the failure reason is unclear, stepping through test logic, inspecting fixture state, or investigating flaky tests.
---

# Python Test Debugging (mcp-dap-server + debugpy)

## Pre-flight Checklist

Before starting:
1. **Test file path** — e.g., `tests/test_handler.py`
2. **Test function name** — e.g., `test_create_user` (or a `-k` pattern)
3. **Project root** — the directory containing `pyproject.toml` or `pytest.ini`
4. **Virtual environment activated?** — `source .venv/bin/activate` or `uv sync` so `pytest` and `debugpy` resolve
5. **debugpy installed?** — `pip install debugpy` or `uv pip install debugpy`
6. **pytest plugins needed?** — `pytest-asyncio`, `pytest-xdist`, etc. must be installed in the venv
7. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

---

## Step-by-Step Workflow

### 1. Start the Test Debug Session

**Recommended: Debug a single test via source mode with pytest args:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["-m", "pytest", "tests/test_handler.py::test_create_user"],
  debugger="gdb"
)
```

**With verbose output and no cache:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["-m", "pytest", "tests/test_handler.py::test_create_user", "-v", "--cache-clear", "-s"],
  debugger="gdb"
)
```

**Debug a test by keyword pattern:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["-m", "pytest", "tests/test_handler.py", "-k", "create_user"],
  debugger="gdb"
)
```

**Debug the whole test file:**
```json
debug(
  mode="source",
  path="/abs/path/to/project",
  args=["-m", "pytest", "tests/test_handler.py"],
  debugger="gdb"
)
```

Expected: Debugger starts, runs pytest, and pauses at the first executable line or breakpoint.

If start fails:
- Ensure the absolute `path` points at the project root (directory with `pyproject.toml`)
- Verify `pytest` is installed in the venv (`python -m pytest --version`)
- Check the test file compiles: `python -m py_compile tests/test_handler.py`
- For module mode: ensure `pytest` is importable (`python -c "import pytest"`)

### 2. Set Breakpoints in the Test

```json
breakpoint(function="test_create_user")
```

```json
breakpoint(file="/abs/path/to/tests/test_handler.py", line=42)
```

```json
breakpoint(function="app.handlers.create_user")
```

```json
breakpoint(function="app.handlers.UserRepository.save")
```

Set breakpoints in both the **test function** and the **code under test** — the test function breakpoint confirms the test runs, and the code-under-test breakpoint is where you investigate.


### Breakpoint Condition and Hit Condition

debugpy supports both `condition` (expression breakpoint) and `hitCondition`
(break after N hits) on breakpoints, directly from the DAP protocol.

Supported hit conditions (from debugpy test suite):

| Hit Condition | Behavior |
|---------------|----------|
| `"5"` | Break when hit count == 5 |
| `"==5"` | Break when hit count == 5 |
| `">5"` | Break when hit count > 5 |
| `">=5"` | Break when hit count >= 5 |
| `"<5"` | Break when hit count < 5 |
| `"<=5"` | Break when hit count <= 5 |
| `"%3"` | Break when hit count is a multiple of 3 |
| (no condition) | Break every time |

Thread-safe breakpoints also work in multi-threaded code -- each thread
has its own hit counter.

### Exception Breakpoints

Configure exception breakpoints with fine-grained control:

```python
# Stop on all exceptions (raised and unhandled):
session.request("setExceptionBreakpoints", {"filters": ["raised", "uncaught"]})

# Stop only on unhandled exceptions:
session.request("setExceptionBreakpoints", {"filters": ["uncaught"]})

# Stop only on raised exceptions (even if caught):
session.request("setExceptionBreakpoints", {"filters": ["raised"]})
```

The response to a stopped-on-exception includes detailed exception info:

```python
stop = session.wait_for_stop("exception")
exc_info = session.request("exceptionInfo", {"threadId": stop.thread_id})
# exc_info contains:
#   exceptionId: str (e.g., "ArithmeticError")
#   description: str (e.g., "bad code")
#   breakMode: "always" | "unhandled"
#   details: {
#       typeName: str,
#       message: str,
#       source: path,
#       stackTrace: str (optional)
#   }
```

### JustMyCode (JMC) Configuration

debugpy supports filtering stack frames to "just my code":

```python
# In code:
debugpy.configure(justMyCode=True)  # filter out stdlib frames

# In test session:
session.config["justMyCode"] = True
```

JMC effects:
- Only frames from user code appear in the stack trace
- Step-into skips over stdlib functions (steps out immediately)
- Useful for focusing on application code
- When disabled, full stack traces including stdlib are shown

### Multi-Threaded Test Patterns

Set breakpoints and inspect thread state:

```python
# After stopping, list all threads:
threads = session.request("threads")
assert len(threads["threads"]) == count  # verify expected thread count

# Switch to a specific thread:
context(threadId=thread_id)

# Step with thread control:
# - "resume_all": stepping resumes all threads (default)
# - "resume_one": stepping only resumes the selected thread
```

### Subprocess Debugging in Tests

When debugging multiprocessing- or subprocess-based tests:

```python
session.config["subProcess"] = True  # auto-attach to children
```

Enable `subProcess` to auto-debug spawned processes. The adapter creates
a separate connection for each subprocess.

### Set Next Statement (GoToTargets)

To skip or repeat code by setting the next statement:

```python
# First, query valid targets:
targets = session.request("gotoTargets", {
    "source": {"path": code_to_debug},
    "line": target_line
})

# Set next statement:
session.request("goto", {
    "threadId": stop.thread_id,
    "targetId": targets[0]["id"]
})
```

Note: You can only jump within the current function (not between functions).

### 3. Run to the First Breakpoint
```json
continue()
```

The test runs until your first breakpoint. You're now in the test code.

### 4. Inspect Test State

```json
context()
```

Returns all local variables including test case data.

**For parametrized tests, inspect specific fixture values:**
```json
evaluate(expression="request")
evaluate(expression="request.param")
```

**Inspect fixture values by name:**
```json
evaluate(expression="db_session")
evaluate(expression="test_client")
evaluate(expression="sample_user")
```

**Inspect expected vs actual values:**
```json
evaluate(expression="expected")
evaluate(expression="result")
evaluate(expression="actual")
```

**Inspect the pytest `request` fixture for fixture chain introspection:**
```json
evaluate(expression="request.fixturenames")
evaluate(expression="request.node")
```

### 5. Step Through the Code Under Test

Step into the code being tested:
```json
step(mode="in")
```

Inspect its internal variables:
```json
context()
```

Step through lines:
```json
step(mode="over")
```

Compare actual values to expectations at each step.

### 6. Inspect Fixture State

pytest fixtures are constructed lazily and cached in the `request` object. To inspect fixture state:

```json
evaluate(expression="db_session")
```

```json
evaluate(expression="type(db_session)")
```

```json
evaluate(expression="db_session.execute('SELECT 1').fetchall()")
```

If a fixture is misbehaving, set a breakpoint inside the fixture function itself:
```json
breakpoint(function="db_session")
continue()
context()
```

Check that fixtures set up state correctly — test failures often come from incorrect fixture setup, not the production code.

### 7. For Flaky Tests — Loop Multiple Times

Set a breakpoint that persists across iterations:

```json
breakpoint(file="/abs/path/to/tests/test_handler.py", line=50)
continue()              // first iteration
evaluate(expression="random_seed")   // is the seed different?
continue()              // second iteration
evaluate(expression="random_seed")   // check again
```

Repeat until the failure occurs. When it does, you're at the failing state.

For parametrized tests, inspect which parametrization is running:
```json
evaluate(expression="request.node.callspec.params")
```

### 8. Debug Async Tests (pytest-asyncio)

For `async def test_...` functions, `pytest-asyncio` runs them on an event loop. Debugging works the same way — set a breakpoint in the async test:

```json
breakpoint(function="test_async_fetch")
continue()
```

To inspect the running event loop and tasks:
```json
evaluate(expression="asyncio.get_running_loop()")
```

```json
evaluate(expression="asyncio.all_tasks(asyncio.get_running_loop())")
```

Step through `await` points with `step(mode="over")` — each `await` may suspend and resume the coroutine. See [references/details.md](references/details.md) for advanced async debugging techniques.

### 9. Using pytest --pdb for Post-Mortem

When a test fails and you want quick post-mortem without a full debug session, use pytest's built-in `--pdb`:

```bash
python -m pytest tests/test_handler.py::test_create_user --pdb
```

This drops into the `pdb` prompt at the point of failure. Note: `--pdb` uses the standard library `pdb`, **not** `debugpy` — it does not integrate with `mcp-dap-server`. Use `--pdb` for quick interactive post-mortem in a terminal; use `mcp-dap-server` + `debugpy` for structured stepping and variable inspection.

For `debugpy`-based post-mortem, see [references/details.md](references/details.md).

### 10. Check for Leaked Threads / Tasks in Tests

Tests can leak threads or asyncio tasks:
```json
info(kind="threads")
```

```json
evaluate(expression="asyncio.all_tasks()")
```

If you see leftover threads or tasks after a test, the test may cause a leak. Use `pytest` plugins like `pytest-check` or explicit cleanup in fixtures to catch this.

### 11. Clean Up

```json
stop()
```

---

## Common Test Debugging Scenarios

### Parametrized Test: Wrong Expected Value

```
1. breakpoint(function="test_function")
2. continue()
3. evaluate(expression="request.node.callspec.params")  // which parametrization?
4. evaluate(expression="input_value")                   // input
5. evaluate(expression="expected")                      // expected value
6. step(mode="over") through to see actual computation
7. Is expected wrong, or is the code wrong?
```

### Flaky Test That Passes Locally

```
1. Run repeatedly to reproduce: python -m pytest tests/test_flaky.py -k test_flaky --count=5
2. debug(mode="source", path="/abs/path/to/project", args=["-m", "pytest", "tests/test_flaky.py::test_flaky", "-v"])
3. breakpoint(file="<assertion-file>", line=<assertion-line>)
4. continue() multiple times, inspect state on failing iteration
5. Look for: time-dependent values, random seeds, shared mutable state, ordering dependence
```

### Test Raises Unexpected Exception

```
1. breakpoint at the line that raises
2. continue()
3. evaluate(expression="exc")   // the exception value
4. context()                     // find what triggered it
```

Or catch the exception in the test and inspect:
```python
try:
    result = handler.process(req)
except Exception as exc:
    import debugpy; debugpy.breakpoint()  # pause here
    raise
```

### Fixture Setup Failure

```
1. breakpoint(function="db_session")   // the fixture function
2. continue()
3. context()                            // what's the fixture building?
4. step(mode="over") through fixture setup
5. Is the fixture producing the expected object?
```

### Async Test Hangs / Never Completes

```
1. breakpoint(function="test_async_fetch")
2. continue()
3. step(mode="over") to the await point
4. evaluate(expression="asyncio.all_tasks()")  // what tasks exist?
5. Is the awaited coroutine ever scheduled? Is the event loop blocked?
```

---


### Multi-Threaded Test Hangs

```
Symptom: test hangs, multiple threads created

1. info(kind="threads") -- list all threads
2. Look for threads blocked on threading.Event.wait or Lock.acquire
3. context(threadId=<N>) -- inspect each blocked thread
4. Check event signaling: is the event ever set?
5. Common: test creates threads but doesn't join them, or forgets to set stop event
```

### Conditional Breakpoint Not Triggering

```
Symptom: breakpoint with condition never pauses

1. Verify the condition expression is valid Python
2. Test with a simpler condition first (e.g., condition="True")
3. Check that the variable in the condition actually exists at that scope
4. Hit condition vs expression condition: hitCondition counts hits, condition evaluates a Python expression
```

### Exception Test Fails Unexpectedly

```
Symptom: exception breakpoints not stopping where expected

1. Check raised vs uncaught filters:
   - "raised": stops even for caught exceptions
   - "uncaught": only stops for exceptions that propagate to top level
2. For caught exceptions, both filters may cause multiple stops (one for raise, one for propagation)
3. Use exceptionInfo to get full exception details
```

---

## Test Debugging Quick Reference
| Concept | Command / Pattern | Description |
|---------|---------|-------------|
| Single test | `debug(mode="source", path=..., args=["-m", "pytest", "tests/test_x.py::test_y"])` | Debug a single test |
| Keyword pattern | `debug(mode="source", path=..., args=["-m", "pytest", "tests/test_x.py", "-k", "pattern"])` | Debug by keyword |
| Verbose | `debug(mode="source", path=..., args=["-m", "pytest", "tests/", "-v", "--cache-clear", "-s"])` | Verbose, no cache, no capture |
| Breakpoint function | `breakpoint(function="test_foo")` | Pause at test function entry |
| Breakpoint line | `breakpoint(file="<file>", line=<N>)` | Pause at specific line |
| Breakpoint condition | `"condition": "i==5"` | Pause when expression is true |
| Hit condition | `"hitCondition": "%3"` | Pause every N hits |
| Exception filters | `["raised", "uncaught"]` | Which exceptions to break on |
| JMC | `session.config["justMyCode"] = True` | Filter stdlib frames |
| Threads | `session.request("threads")` | List all threads |
| Subprocess | `session.config["subProcess"] = True` | Auto-attach to subprocess children |
| GoToTargets | `session.request("gotoTargets", ...)` | Find valid jump targets |
| GoTo | `session.request("goto", ...)` | Set next statement |
| Exception info | `session.request("exceptionInfo", ...)` | Get exception details |
| Step | `step(mode="over|in|out")` | Navigate through code |
| Evaluate | `evaluate(expression=...)` | Inspect variable values |
| Fixtures | `evaluate(expression="request.fixturenames")` | List active fixtures |
| Params | `evaluate(expression="request.node.callspec.params")` | Parametrized test params |
| Async tasks | `evaluate(expression="asyncio.all_tasks()")` | Inspect async tasks |
| Thread check | `info(kind="threads")` | Check for leaked threads |
| Post-mortem | `python -m pytest ... --pdb` | Quick post-mortem (pdb, not debugpy) |
| Stop | `stop()` | End session |

---

## How to Present Findings

> **Test failure in** `test_create_user` **at** `tests/test_handler.py:84`.
> **Expected** `result.status == 201`, **got** `500`.
> **Root cause:** `create_user` at `app/handlers.py:42` calls `db.insert_user()` which raises `IntegrityError` because the test fixture inserts two users with the same email, violating a unique constraint.
> **Fix:** Update test fixture data to use unique emails, or add a `db_session.rollback()` cleanup in the fixture to reset state between test cases.