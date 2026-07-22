# Python Anti-Patterns Checklist

Agent guidance for reviewing Python code against a checklist of common mistakes. Treat this file as a review gate: run every code change through these entries before considering it complete. Each entry pairs the anti-pattern with the corrective action an agent must apply.

## Mutable Default Arguments

Never use mutable objects (`list`, `dict`, `set`) as default argument values. The default is constructed once at function definition time and shared across all calls that omit the argument, so mutations persist and leak between invocations.

```python
# Anti-pattern: shared default list
def add_item(item, items=[]):
    items.append(item)
    return items

# Correct: sentinel default, construct inside
def add_item(item, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items
```

## Bare Except Clauses

Reject `except:` and `except Exception:` blocks that swallow errors silently. They hide bugs, mask `KeyboardInterrupt`, and make failures invisible. Catch only the specific exception types the code intends to handle, and log or re-raise when the error is not recoverable.

## Global State Abuse

Avoid module-level mutable state shared across functions. Globals make code untestable, break concurrency, and introduce hidden coupling. Inject dependencies through function arguments or class constructors instead of reading from module scope.

## God Classes

Reject classes that accumulate unrelated responsibilities. A class with more than a handful of public methods handling persistence, business logic, and I/O violates the Single Responsibility Principle. Split into focused collaborators and compose them. See `design-patterns.md` for composition guidance.

## Scattered Timeout and Retry Logic

Do not sprinkle `timeout=` and ad-hoc retry loops across every call site. Duplicated retry logic leads to inconsistent behavior and double-retry bugs. Centralize it in a decorator, client wrapper, or middleware. See `resilience.md` for the canonical retry and backoff patterns.

## Using == for None

Use `is` and `is not` for `None` comparisons, never `==`. The `==` operator invokes `__eq__`, which subclasses can override to return surprising results. Identity comparison is faster, unambiguous, and the only correct check for sentinel singletons like `None`.

## Missing Context Managers for Resources

Never acquire a file, socket, lock, or database connection without a `with` block. Raw `open()` calls leak the handle when an exception fires between acquisition and explicit close. See `resource-management.md` for the context manager protocol and `contextlib` utilities.

## String Concatenation in Loops

Avoid `s += chunk` inside a hot loop. Repeated concatenation rebuilds the entire string each iteration, giving O(n^2) behavior. Accumulate fragments in a list and call `"".join(fragments)` once. See `performance.md` for string-building benchmarks.

## Type Checking with type() Instead of isinstance or Protocol

Reject `type(x) is list` checks. They break on subclasses and ignore structural typing. Use `isinstance` for runtime checks, or define a `Protocol` and rely on duck typing. See `type-safety.md` for Protocol-based structural typing.

## Importing Inside Functions Without Cause

Top-level imports are the default. Function-level imports are acceptable only to break circular import cycles or to defer an expensive optional dependency. Unjustified inline imports hide dependencies, slow repeated calls, and defeat static analysis tools.

## print Instead of Logging

Replace `print` with the `logging` module in any code that runs in production. `print` cannot be filtered, leveled, routed, or correlated. Configure a named logger per module and emit structured records. See `observability.md` for structured logging guidance.

## Mutable Class Attributes Shared Across Instances

Class-level mutable attributes (`tags: list = []`) are shared by every instance. One mutation leaks to all objects. Define them as instance attributes in `__init__`, or use `None` sentinels and construct per instance.

## Hardcoded Configuration and Secrets

Never embed hosts, credentials, or tunable values in source. Read them from environment variables or a typed settings object. See `configuration.md` for pydantic-settings and 12-factor config patterns.

## Blocking Calls in Async Code

Reject `time.sleep`, `requests.get`, and any synchronous I/O inside `async def` functions. They block the event loop and stall every coroutine. Use `asyncio.sleep` and async-native clients. See `async.md` for the blocking-call pitfall and its fixes.

## Ignored Return Values

Do not discard return values from functions that signal failure through their result (e.g., `dict.get`, `list.sort` returning `None`, subprocess exit codes). Check the result or use a form that raises on failure. Silent drops hide bugs.

## When to Use

Load this feature file when:
- Reviewing a pull request or patch for common Python mistakes
- Auditing a legacy codebase before a refactor
- Debugging a mysterious failure that may stem from a known bad practice
- Establishing team coding standards or a pre-merge checklist

## Cross-References

- For the positive patterns that correct these anti-patterns: load `design-patterns.md`
- For retry and timeout centralization: load `resilience.md`
- For context manager cleanup patterns: load `resource-management.md`
- For structured logging replacing print: load `observability.md`
- For type-safe alternatives to runtime type checks: load `type-safety.md`