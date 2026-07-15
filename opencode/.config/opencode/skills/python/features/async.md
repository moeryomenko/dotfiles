# Async Programming

Directives for writing, reviewing, and debugging asyncio-based Python code. Apply these rules when the task involves coroutines, concurrent I/O, or non-blocking workflows.

## Event Loop and Coroutines

The asyncio event loop is a single-threaded cooperative scheduler. Coroutines defined with `async def` yield control at every `await` point; nothing preempts them. Enforce this model: any coroutine that blocks the loop starves every other task.

- Start the loop with `asyncio.run(main())` at the program entry point. Never instantiate `asyncio.get_event_loop()` manually in new code.
- Define coroutines with `async def`. Await the result at the call site — omitting `await` returns a coroutine object, not the value.
- Keep coroutines short and focused. A coroutine that runs for hundreds of lines without an `await` starves the loop.

```python
import asyncio


async def fetch_resource(url: str) -> dict:
    """Fetch a resource without blocking the event loop."""
    await asyncio.sleep(0.1)  # stand-in for non-blocking I/O
    return {"url": url}


async def main() -> None:
    result = await fetch_resource("https://example.com")
    print(result)


asyncio.run(main())
```

## Tasks and Concurrent Execution

Schedule independent coroutines concurrently with `asyncio.create_task` and collect their results with `asyncio.gather`. Prefer `gather` over manual task bookkeeping when the set of coroutines is known up front.

- Wrap each independent coroutine in `asyncio.create_task` so the loop schedules it immediately.
- Use `asyncio.gather(*coros)` to await a batch of tasks concurrently.
- Pass `return_exceptions=True` to `gather` when partial success is acceptable; otherwise the first exception cancels the remaining tasks.

```python
import asyncio


async def fetch_item(item_id: int) -> dict:
    await asyncio.sleep(0.1)
    return {"id": item_id}


async def fetch_all(item_ids: list[int]) -> list[dict]:
    tasks = [asyncio.create_task(fetch_item(i)) for i in item_ids]
    return await asyncio.gather(*tasks, return_exceptions=True)
```

## Error Handling, Timeouts, and Cancellation

Wrap awaited operations in `try/except` to localize failures. Bound every external call with `asyncio.wait_for` to prevent indefinite hangs. Handle `asyncio.CancelledError` explicitly in long-running tasks and re-raise it after cleanup so cancellation propagates correctly.

- Catch specific exceptions inside coroutines; never swallow `CancelledError` without re-raising.
- Use `asyncio.wait_for(coro, timeout=...)` to enforce deadlines. `TimeoutError` (or `asyncio.TimeoutError` on older versions) signals the deadline elapsed.
- Clean up resources in a `finally` block or via an async context manager.

```python
import asyncio


async def with_deadline() -> str:
    try:
        return await asyncio.wait_for(slow_call(), timeout=2.0)
    except asyncio.TimeoutError:
        return "timed out"


async def slow_call() -> str:
    await asyncio.sleep(5)
    return "done"
```

## Common Pitfalls

Audit asyncio code for these recurring mistakes:

- **Blocking the loop**: calling `time.sleep`, synchronous `requests.get`, or CPU-bound work inside a coroutine freezes every other task. Offload blocking calls with `asyncio.to_thread` and CPU work with a process pool.
- **Forgetting `await`**: `result = coro()` returns a coroutine object, not the result. Lint with `ruff` rule `ASYNC100`/`ASYNC200` families to catch this.
- **Swallowing `CancelledError`**: catching `BaseException` or bare `except` hides cancellation. Always re-raise `CancelledError`.
- **Mixing sync and async**: a synchronous function cannot `await`. Bridge the boundary with `asyncio.run` at the top level, not inside an existing loop.

## Sync vs Async Decision Guide

Choose the concurrency model by workload profile, not by fashion.

| Workload | Use |
|----------|-----|
| Many concurrent I/O calls (network, DB, disk) | `asyncio` |
| CPU-bound computation (parsing, hashing, ML) | `multiprocessing` or `concurrent.futures.ProcessPoolExecutor` |
| Mixed I/O + CPU | `asyncio` for I/O, offload CPU via `asyncio.to_thread` or process pool |
| Simple script, few connections | Synchronous code — simpler to debug |

## When to Use

- Writing or reviewing code that uses `async def`, `await`, `asyncio.gather`, or async web frameworks (FastAPI, aiohttp).
- Diagnosing a hung event loop, a forgotten `await`, or a `CancelledError` swallowed by a bare `except`.
- Deciding whether a new service should be sync or async.

## Cross-References

- See `testing.md` for async test patterns with `pytest-asyncio` and `anyio`.
- See `resilience.md` for retry, backoff, and circuit-breaker patterns layered over async calls.
- See `resource-management.md` for async context managers and async cleanup protocols.
- See `performance.md` for GIL implications and when async does not improve throughput.