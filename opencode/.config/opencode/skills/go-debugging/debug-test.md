---
name: go-debug-test
description: Debugging Go tests via mcp-dap-server with Delve. Use when a Go test fails and the failure reason is unclear, stepping through test logic, inspecting test setup, or investigating flaky tests.
---

# Go Test Debugging (mcp-dap-server + Delve)

## Pre-flight Checklist

Before starting:
1. **Test name** or pattern to debug — `TestFoo`, `TestSomething`
2. **Package path** — where the test lives (e.g., `./internal/handler`)
3. **Test timeout** — tests may time out while you debug; pass `-test.timeout=0`
4. **Test flags needed?** — `-count=1` (disable cache), `-test.v`, etc.
5. **Flaky test?** — run with `-count=5 -failfast` to reproduce before debugging
6. **mcp-dap-server running?** — ensure the MCP server is connected and tools are registered

---

## Step-by-Step Workflow

### 1. Start the Test Debug Session

**Recommended: Debug test via source mode with test flags:**
```json
debug(
  mode="source",
  path="/abs/path/to/go/module/root",
  programArgs=["-test.run", "TestCreateUser"],
  debugger="delve"
)
```

**With verbose output and disabled timeout:**
```json
debug(
  mode="source",
  path="/abs/path/to/go/module/root",
  programArgs=["-test.run", "TestCreateUser", "-test.v", "-test.timeout=0", "-test.count=1"],
  debugger="delve"
)
```

**Alternative: Pre-compiled test binary (avoids recompilation delay):**
```bash
go test -c -o /tmp/handler.test ./internal/handler
```
```json
debug(
  mode="binary",
  path="/tmp/handler.test",
  programArgs=["-test.run", "TestCreateUser", "-test.v"],
  debugger="delve"
)
```

**Benchmark debugging (runs benchmark once):**
```bash
go test -c -o /tmp/bench.test ./
```
```json
debug(
  mode="binary",
  path="/tmp/bench.test",
  programArgs=["-test.run=^$", "-test.bench=BenchmarkFoo", "-test.benchtime=1x"],
  debugger="delve"
)
```

Expected: Debugger starts, compiles the test (or loads binary), and pauses at the first executable line.

If start fails:
- Ensure the absolute path points to the module root (directory with `go.mod`)
- For compiled binary mode: verify `go test -c` succeeded first
- Check package compiles cleanly: `go test -run ^$ ./...`

### 2. Set Breakpoints in the Test

```json
breakpoint(function="TestCreateUser")
```

```json
breakpoint(file="/abs/path/to/handler_test.go", line=42)
```

```json
breakpoint(function="package.FunctionBeingTested")
```

```json
breakpoint(function="package.NewServer")
```

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

**For table-driven tests, inspect specific fields:**
```json
evaluate(expression="tt")
evaluate(expression="tt.give")
evaluate(expression="tt.want")
```

**Inspect expected vs actual values:**
```json
evaluate(expression="req")
evaluate(expression="want")
evaluate(expression="got")
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

### 6. For Flaky Tests — Loop Multiple Times

Set a breakpoint that persists across iterations:

```json
breakpoint(file="/abs/path/to/handler_test.go", line=50)
continue()              // first iteration
evaluate(expression="seed")   // is the random seed different?
continue()              // second iteration
evaluate(expression="seed")   // check again
```

Repeat until the failure occurs. When it does, you're at the failing state.

### 7. Test Helper Functions

If the test uses helpers, set a breakpoint in the helper:
```json
breakpoint(function="mustSetupServer")
continue()
context()
```

Check that helpers are setting up state correctly — test failures often come from incorrect setup, not the production code.

### 8. Check Goroutines in Tests

Tests can leak goroutines too:
```json
info(kind="threads")
```

If you see leftover goroutines after a test, the test may cause a goroutine leak (`go.uber.org/goleak` would catch this).

### 9. Clean Up

```json
stop()
```

---

## Common Test Debugging Scenarios

### Table-Driven Test: Wrong Expected Value

```
1. breakpoint(function="TestFunction")
2. continue()
3. evaluate(expression="tt")       // which test case?
4. evaluate(expression="tt.give")  // input
5. evaluate(expression="tt.want")  // expected value
6. step(mode="over") through to see actual computation
7. Is want wrong, or is the code wrong?
```

### Flaky Test That Passes Locally

```
1. Add a loop around the failing assertion:
     for i := 0; i < 100; i++ {
         t.Run(fmt.Sprintf("attempt_%d", i), func(t *testing.T) { ... })
     }
2. Rebuild test binary: go test -c -o /tmp/flaky.test ./
3. debug(mode="binary", path="/tmp/flaky.test", programArgs=["-test.run", "TestFlaky", "-test.count=1"])
4. breakpoint(file="<assertion-file>", line=<assertion-line>)
5. continue() 50 times, inspect state on failing iteration
```

### Test Panics Instead of Failing

```
1. breakpoint(function="runtime.gopanic")
2. continue()
3. evaluate(expression="err")   // the panic value
4. context()                    // find what triggered the panic
```

### Race Detected in Tests

```
1. Build with race: go test -c -race -o /tmp/race.test ./
2. debug(mode="binary", path="/tmp/race.test", programArgs=["-test.run", "TestRace"])
3. Set breakpoints at all sites accessing the shared variable
4. continue() between them, noting thread IDs
5. Identify unsynchronized access pattern
```

---

## Test Debugging Quick Reference

| Command | Purpose |
|---------|---------|
| `debug(mode="source", path=..., programArgs=["-test.run", "TestFoo"])` | Debug test from source |
| `go test -c -o /tmp/pkg.test ./pkg` + `debug(mode="binary", path="/tmp/pkg.test", programArgs=[...])` | Debug compiled test binary |
| `debug(mode="source", path=..., programArgs=["-test.run", "TestFoo", "-test.timeout=0"])` | Disable test timeout |
| `debug(mode="source", path=..., programArgs=["-test.run", "TestFoo", "-test.count=1"])` | Disable test caching |
| `go test -c && debug(mode="binary", path="/tmp/bench.test", programArgs=["-test.run=^$", "-test.bench=BenchFoo"])` | Debug a benchmark |
| `breakpoint(function="TestFoo")` | Pause at test function entry |
| `breakpoint(file="<file>", line=<N>)` | Pause at specific line |
| `breakpoint(function="runtime.gopanic")` | Catch panics |
| `step(mode="over\|in\|out")` | Navigate through code |
| `evaluate(expression=...)` | Inspect variable values |
| `info(kind="threads")` | Check for leaked goroutines |
| `stop()` | End session |

---

## How to Present Findings

> **Test failure in** `TestCreateUser` **at** `handler_test.go:84`.
> **Expected** `got.Status == http.StatusCreated`, **got** `http.StatusInternalServerError`.
> **Root cause:** `CreateUser` at `handler.go:42` calls `db.InsertUser()` which returns an error because the test database has a unique constraint on `email`, but the test fixture inserts two users with the same email.
> **Fix:** Update test fixture data to use unique emails, or add `t.Cleanup` to reset the database between test cases.
