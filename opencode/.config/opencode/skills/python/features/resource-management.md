# Python Resource Management

Agent guidance for acquiring and releasing resources deterministically. Apply these directives whenever code opens a file, socket, lock, database connection, or any handle that must be released. The rule is absolute: every resource acquisition pairs with a context manager.

## Context Manager Protocol

Implement `__enter__` and `__exit__` for any class that owns a resource. `__exit__` runs unconditionally — even when an exception fires inside the `with` block — so cleanup is guaranteed. Return `False` (or `None`) from `__exit__` to propagate exceptions; return `True` only when intentionally suppressing.

```python
from types import TracebackType

class DatabaseConnection:
    def __init__(self, dsn: str) -> None:
        self._dsn = dsn
        self._conn: object | None = None

    def __enter__(self) -> "DatabaseConnection":
        self._conn = connect(self._dsn)
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_val: BaseException | None,
        exc_tb: TracebackType | None,
    ) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None
```

Prefer the class-based protocol when the resource has setup, teardown, and reusable methods. Prefer the `@contextmanager` decorator for one-off blocks.

## contextlib Utilities

Use `contextlib` instead of hand-rolling boilerplate. `@contextmanager` turns a generator into a context manager; `suppress` ignores specified exceptions; `ExitStack` manages a dynamic number of resources; `closing` adapts objects with a `close()` method.

```python
from contextlib import contextmanager, ExitStack, suppress

@contextmanager
def timed_block(name: str):
    import time
    start = time.perf_counter()
    try:
        yield
    finally:
        print(f"{name}: {time.perf_counter() - start:.3f}s")

# ExitStack: open a variable number of files cleanly
with ExitStack() as stack:
    files = [stack.enter_context(open(path)) for path in paths]
    process(files)

# suppress: ignore an expected exception without a bare except
with suppress(FileNotFoundError):
    os.remove(temp_path)
```

## Cleanup Patterns: try/finally Versus Context Managers

Prefer context managers over `try/finally`. A `with` block cannot be forgotten the way a `finally` clause can be missed during a refactor. Reserve `try/finally` for cases where the cleanup logic is not a reusable resource (e.g., restoring a global flag in a test). Never pair resource acquisition with a bare `try/except` that lacks a `finally` — the resource leaks on the exception path.

## File Handling

Always open files with `with open(...)`. The block closes the descriptor on every exit path, including exceptions and early returns. Specify the encoding explicitly — relying on the platform default produces files that fail on other systems.

```python
# Correct: explicit encoding, guaranteed close
def read_config(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        return parse(f.read())
```

## Sockets and Connection Pools

Wrap every socket and network connection in a context manager. For database and HTTP clients, use a connection pool managed as a context manager at application scope, and acquire individual connections from the pool inside request-scoped `with` blocks. Never open a raw socket without a guarantee it will be closed.

## Temporary Files

Use the `tempfile` module for scratch files. `NamedTemporaryFile` and `TemporaryDirectory` are themselves context managers that delete on exit, so manual cleanup is unnecessary and error-prone.

```python
import tempfile

with tempfile.TemporaryDirectory() as tmpdir:
    write_intermediate(tmpdir)
    # directory removed automatically on exit
```

## When to Use

Load this feature file when:
- Writing code that opens files, sockets, locks, or database connections
- Implementing a class that owns a resource needing deterministic cleanup
- Building a connection pool or managing nested resources
- Reviewing code for resource leaks or missing cleanup paths
- Creating temporary files or directories safely

## Cross-References

- For anti-patterns involving leaked resources and missing context managers: load `anti-patterns.md`
- For async context managers (`__aenter__`/`__aexit__`): load `async.md`
- For performance impact of prompt resource release: load `performance.md`
- For resilience around connection failures: load `resilience.md`