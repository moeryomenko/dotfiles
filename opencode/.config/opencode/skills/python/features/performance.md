# Python Performance

Agent guidance for profiling, analyzing, and optimizing Python code. Apply these directives when a workload is too slow, memory is growing unbounded, or a hot path needs tuning. Always measure before optimizing — never edit code for speed without profiling evidence.

## Profiling Tools

Profile before changing anything. Use the right tool for the question being asked.

```python
# cProfile: function-level call graph and cumulative time
import cProfile

def hot_workload(n: int) -> int:
    return sum(i * i for i in range(n))

with cProfile.Profile() as profiler:
    hot_workload(1_000_000)
profiler.print_stats(sort="cumulative")
```

- `cProfile` — built-in, function-level cumulative and per-call timing. Start here for an overview.
- `line_profiler` — line-by-line timing inside a specific function. Use when `cProfile` points at a function but not the offending line.
- `memory_profiler` — per-line memory allocation. Use when memory grows unexpectedly.
- `py-spy` — sampling profiler for production processes. Attaches without code changes or restarts.

Record the profile output as evidence before and after the optimization so the speedup is verifiable.

## Algorithmic Optimization

Choose the right data structure before micro-optimizing expressions. A `list` membership check is O(n); a `set` or `dict` lookup is O(1). Replacing a list scan with a set membership test is the single highest-impact change available.

```python
# Anti-pattern: O(n) membership test repeated in a loop
valid_ids: list[int] = [...]
results = [item for item in items if item.id in valid_ids]

# Correct: O(1) lookup
valid_ids_set: set[int] = set(valid_ids)
results = [item for item in items if item.id in valid_ids_set]
```

Prefer built-ins implemented in C (`sum`, `min`, `max`, `sorted`) over hand-rolled loops. Push work into comprehensions and generator expressions instead of explicit `for` loops with `append`.

## GIL Implications

The Global Interpreter Lock serializes bytecode execution within a single CPython process. CPU-bound work in threads does not parallelize — threads contend for the GIL and may run slower than serial code. Use `multiprocessing` or native extensions that release the GIL for CPU-bound workloads. I/O-bound work (network, disk) releases the GIL while waiting, so threads and asyncio are effective there.

```python
# CPU-bound: use processes, not threads
from multiprocessing import Pool

def square(x: int) -> int:
    return x * x

with Pool() as pool:
    results = pool.map(square, range(1_000_000))
```

## Caching Strategies

Cache the results of pure, expensive functions. `functools.lru_cache` is the default for bounded memoization; use a manual dict cache when the key is not hashable by `lru_cache` or when invalidation must be explicit.

```python
from functools import lru_cache

@lru_cache(maxsize=512)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)
```

Document cache invalidation requirements. A cache that never invalidates is a memory leak; a cache that invalidates too eagerly defeats its purpose.

## Generators Versus Lists

Use generators for large or unbounded datasets. A generator yields one item at a time and holds no full materialized list, so peak memory stays flat. Use a list only when the consumer needs random access, repeated iteration, or `len()`.

```python
# Generator: constant memory regardless of dataset size
def read_records(path: str):
    with open(path) as f:
        for line in f:
            yield parse_record(line)

# List: materializes everything in memory at once
records = [parse_record(line) for line in open(path)]
```

## Memory and __slots__

For classes with a fixed set of fields and many instances, define `__slots__` to skip the per-instance `__dict__`. This cuts memory per instance and speeds attribute access.

```python
class Point:
    __slots__ = ("x", "y")

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y
```

## When to Use

Load this feature file when:
- A workload is too slow and needs profiling before optimization
- Memory usage is growing unbounded or a memory leak is suspected
- A hot loop or data pipeline needs tuning
- Choosing between threads, processes, and asyncio for a parallel workload
- Deciding whether to cache, and how to invalidate the cache

## Cross-References

- For context managers that release resources promptly: load `resource-management.md`
- For retry and timeout behavior around slow calls: load `resilience.md`
- For async versus sync decision guidance: load `async.md`
- For anti-patterns that degrade performance (string concatenation, blocking in async): load `anti-patterns.md`