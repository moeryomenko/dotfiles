# Python Technical Deep-dive Patterns

This file is MANDATORY reading. Load it before any feature file in `features/`. It contains the foundational technical knowledge (GIL, memory model, import system, descriptor protocol, version-specific feature guards) that every feature file builds on. Skipping it leads to shallow, incorrect guidance.

## Core instructions for Python code analysis

- Trace the full execution flow. Gather context from the call chain before drawing conclusions about a function's behavior.
- Never make assumptions based on return types, docstrings, comments, or `try`/`except` shapes. Verify by tracing concrete execution paths through the actual bytecode and runtime values.
- Never skip a step just because a bug was already found in a previous step. Independent defects stack; report each one.
- Python documentation and comments are frequently outdated or aspirational. Always read the ACTUAL IMPLEMENTATION, not the docstring. A function whose docstring says "returns None" may raise, return a sentinel, or return a value under specific branches.
- Never report an error without checking whether the error is impossible in the call path. A `KeyError` raised by `dict[key]` is unreachable if every caller guards with `in` first; prove the unguarded path exists before flagging it.
- Do not recommend defensive programming unless it fixes a proven bug. Redundant `None` checks and unnecessary `try`/`except` wrappers around operations that cannot fail add noise and hide real control flow.
- When a feature file references a runtime guarantee (e.g., "dict preserves insertion order"), confirm the Python version that guarantees it before relying on it. Annotate the version in your guidance.

## GIL implications and when it matters

The Global Interpreter Lock (GIL) serializes bytecode execution within a single CPython process. It is released around I/O operations and periodically between bytecode instructions (controlled by `sys.setswitchinterval`, default 5ms).

- CPU-bound work holding the GIL does not parallelize across threads. Use `multiprocessing`, `concurrent.futures.ProcessPoolExecutor`, or a native extension that releases the GIL (NumPy, Cython with `nogil`, C extensions with `Py_BEGIN_ALLOW_THREADS`).
- I/O-bound work (sockets, files, subprocess, network) releases the GIL while waiting. Threads or `asyncio` are appropriate; `multiprocessing` adds unnecessary IPC overhead.
- `threading` is correct for I/O concurrency and for calling GIL-releasing native code. It is the wrong tool for pure-Python CPU parallelism.
- Free-threaded CPython (PEP 703, 3.13t experimental, 3.14+ stable track) removes the GIL. Do not assume GIL behavior unless the target interpreter is pinned. When advising parallelism, state the assumption: "On GIL builds (default 3.13), use multiprocessing for CPU-bound work."

```python
# CPU-bound: threads do NOT help on a GIL build.
# Prefer ProcessPoolExecutor.
from concurrent.futures import ProcessPoolExecutor

def square(x: int) -> int:
    return x * x

with ProcessPoolExecutor() as pool:
    results = list(pool.map(square, range(1_000)))
```

For the I/O-bound counterpart and structured concurrency, see `features/async.md` and `features/performance.md`.

## Memory model: reference counting and the cyclic garbage collector

CPython's primary memory discipline is reference counting. Every object carries a refcount; deallocation runs deterministically when the count hits zero. The cyclic garbage collector (in the `gc` module) handles reference cycles that refcounting alone cannot break.

- Do not assume deterministic destruction in the presence of cycles. An object in a cycle survives until the next GC pass, which may be never if the cycle is not in a tracked container.
- `__del__` is unreliable. It may not run if the object is in a cycle, if it is referenced by a frame local (PEP 558 traceback semantics), or if interpreter shutdown has begun. Never put resource cleanup in `__del__`; use a context manager (`__enter__`/`__exit__`) or `contextlib.closing` instead. See `features/resource-management.md`.
- `__del__` on objects that participate in cycles can resurrect the object (assigning `self` to an external reference inside `__del__`). This is almost always a bug.
- `gc.collect()` can be invoked manually to verify cycle cleanup in tests, but do not call it in production hot paths.
- Weak references (`weakref`) do not increase the target's refcount and are the correct tool for caches and observer registries that must not keep objects alive.

## Import system mechanics

Imports resolve through `sys.modules` (a cache of already-imported modules), the finder/loader machinery (`importlib`), and `sys.meta_path`/`sys.path`. Understanding the cache is essential for diagnosing circular imports and stale state.

- `sys.modules` caches by fully-qualified name. Re-importing returns the cached object; module-level code runs exactly once. Mutating a module's attributes after import affects all consumers of the cached module.
- Circular imports occur when module A imports B at top level and B imports A at top level. The symptom is `ImportError: cannot import name 'X' from partially initialized module 'A'`. Workarounds: move the import inside the function that needs it (deferred import), restructure so the cycle is broken, or extract the shared dependency into a third module.
- `from package import name` binds `name` at import time to whatever `package.name` pointed to then. Later reassignment of `package.name` is not visible to the importer. Prefer `import package` and access `package.name` at call time when the target may be patched (e.g., in tests).
- `__init__.py` side effects (running code on package import) are a frequent source of import-order bugs and slow startup. Keep `__init__.py` files minimal: re-exports via `__all__`, and that is all.
- Namespace packages (PEP 420, no `__init__.py`) split a single logical package across directories. Use deliberately, not by accident — an empty `__init__.py` is usually what you want.

## Descriptor protocol

Descriptors power `property`, `classmethod`, `staticmethod`, and most ORM field definitions. A descriptor is any object defining `__get__`, `__set__`, or `__delete__`. Data descriptors define `__set__` or `__delete__`; non-data descriptors define only `__get__`.

- `property` is a data descriptor: its `__set__` runs the setter (or raises `AttributeError` if no setter). Instance dict entries cannot shadow a data descriptor.
- `classmethod` and `staticmethod` are non-data descriptors. They can be shadowed by an instance attribute of the same name — a subtle bug when a subclass assigns a classmethod name on an instance.
- When implementing a descriptor, store per-instance state on the instance dict (keyed by a mangled name or via the descriptor object itself), never on the descriptor object — descriptor objects are shared across all instances of the owning class.
- Prefer `property` over bare attribute access when validation or computed semantics are required, but avoid `property` for expensive computation; callers expect attribute access to be cheap.

```python
class PositiveInt:
    """Data descriptor enforcing a positive integer invariant."""
    __slots__ = ("_name",)

    def __set_name__(self, owner: type, name: str) -> None:
        self._name = name

    def __get__(self, instance: object | None, owner: type) -> int:
        if instance is None:
            return self  # type: ignore[return-value]
        return instance.__dict__[self._name]

    def __set__(self, instance: object, value: int) -> None:
        if value <= 0:
            raise ValueError(f"{self._name} must be positive, got {value}")
        instance.__dict__[self._name] = value
```

## Metaclass pitfalls

Metaclasses (the `type` subclass assigned to `__class__`) intercept class creation. They are powerful and frequently overused.

- Metaclass conflicts: a class inheriting from two bases with incompatible metaclasses raises `TypeError` at class creation. This is the most common metaclass failure and is hard to debug in large hierarchies.
- Prefer `__init_subclass__` (3.6+) for class-creation hooks that previously required metaclasses. It runs on the subclass at definition time, requires no metaclass, and composes cleanly across hierarchies.
- Metaclasses affect every subclass. A metaclass added to a base class silently changes behavior for all descendants; review the full hierarchy before introducing one.
- Frameworks (Django, SQLAlchemy, Pydantic v1) use metaclasses for field collection. When integrating with such a framework, your custom metaclass must cooperate with the framework's metaclass — usually by inheriting from it.

```python
# Prefer __init_subclass__ over a metaclass for subclass hooks.
class Plugin:
    registry: list[type] = []

    def __init_subclass__(cls, **kwargs: object) -> None:
        super().__init_subclass__(**kwargs)
        Plugin.registry.append(cls)
```

## Mutable and immutable gotchas

- Mutable default arguments are evaluated once at function definition, not per call. A mutable default (`def f(items=[])`) accumulates state across calls. Use `None` as a sentinel and create the mutable inside the function.
- Mutable class attributes are shared across all instances. `class C: data = []` means every instance sees the same list. Assign in `__init__` for per-instance state.
- `frozenset` is immutable but its elements must be hashable; a `frozenset` containing a mutable (non-hashable) object is impossible to construct, which is the protection. Do not confuse "immutable container" with "deeply immutable contents" — a `tuple` of lists is mutable in effect.
- Small integers and interned strings are cached; `a is b` may be True for unrelated reasons. Use `==` for value equality, `is` only for identity (singletons like `None`, `True`, `False`, and sentinel objects).
- Augmented assignment (`+=`) on a mutable object mutates in place; on an immutable it rebinds. A method that does `self.items += other` on a list mutates the caller's list — usually a bug.

## String interning

CPython interns some strings automatically: identifiers (variable names, attribute names), string literals that look like identifiers, and strings of length 1. `sys.intern` forces interning of an arbitrary string, making identity comparisons (`is`) safe and reducing memory for many duplicate strings.

- Use `sys.intern` for a large, bounded set of repeated strings (e.g., parsed tokens, enum-like category values) where comparison cost dominates. Do not intern unbounded or unique strings — the intern table grows without bound.
- Interned strings are not garbage collected in older CPython versions; on 3.7+ the intern table holds weakrefs, so interned strings can be reclaimed when no strong references remain. Still, do not intern in a hot loop.
- Relying on `is` for string comparison is a bug unless both operands are interned by construction. Use `==`.

## Dict ordering guarantees

Since Python 3.7 (and as an implementation detail of CPython 3.6), `dict` preserves insertion order. `collections.OrderedDict` is only needed when order matters AND you need equality to be order-sensitive (two `OrderedDict`s with the same keys in different order compare unequal; two `dict`s do not).

- Iteration order is insertion order, not sorted order. Do not assume sorted output from a dict.
- Deletion and re-insertion move the key to the end. Updating an existing key keeps its position.
- `**kwargs` preserves order since 3.6; keyword arguments arrive in call order. This matters for serializers and signature-preserving decorators.
- Performance: ordered dicts are slightly slower than the pre-3.6 unordered implementation for some workloads, but the difference is negligible. Do not micro-optimize by avoiding dicts.

## Walrus operator patterns

The walrus operator `:=` (PEP 572, 3.8+) binds a name as part of an expression. Use it to avoid recomputing a value or to capture a loop condition.

- Use in `while` to capture the loop value: `while (chunk := f.read(8192)): ...`.
- Use in list comprehensions to filter and project without recomputing: `[y := f(x) for x in data if y := f(x) > 0]` is wrong (the walrus in the filter does not bind for the projection); use `[y for x in data if (y := f(x)) > 0]`.
- Do not use the walrus to cram multiple statements into one line for brevity. It harms readability when the binding is not reused.
- The walrus cannot assign to an attribute or subscript: `obj.attr := x` is a syntax error. It binds a bare name only.

## Pattern matching

`match`/`case` (PEP 634, 3.10+) provides structural pattern matching. It is not a switch statement; it destructures and binds.

- Guards (`case Point(x, y) if x > 0:`) refine a match. A failing guard falls through to the next case, not to no-match.
- Capture patterns bind names; wildcard `_` matches anything without binding. Do not reuse a captured name as a wildcard — `_` is the convention.
- Literal patterns match constants; `case 200:` matches the int 200. To match against a variable's value, use a guard: `case status if status == EXPECTED:`.
- Mapping patterns (`case {"type": "error", "msg": msg}:`) match dict structure without requiring a dataclass. Sequence patterns (`case [a, *rest]:`) match lists and tuples, not arbitrary iterables.
- Destructuring classes requires `__match_args__` (dataclasses set this automatically) or keyword patterns: `case Point(x=0, y=y):`.

```python
# 3.10+ structural pattern matching with a guard.
from dataclasses import dataclass

@dataclass
class Command:
    name: str
    args: list[str]

def handle(cmd: object) -> str:
    match cmd:
        case Command(name="quit"):
            return "bye"
        case Command(name="echo", args=[msg, *_]):
            return msg
        case Command(name=name, args=args) if len(args) > 3:
            return f"{name}: too many args"
        case _:
            return "unknown"
```

## Version-specific feature guards

Annotate the minimum Python version for every feature you recommend. Recommending a feature unavailable on the target interpreter is a correctness bug. Use the table below as the canonical reference; cross-check against `sys.version_info` in code when the runtime is not pinned.

| Feature | Minimum version | PEP |
|---|---|---|
| f-strings | 3.6 | PEP 498 |
| `__init_subclass__` | 3.6 | PEP 487 |
| dict insertion order guaranteed | 3.7 | — |
| `dataclasses` | 3.7 | PEP 557 |
| Walrus operator `:=` | 3.8 | PEP 572 |
| Positional-only params `/` | 3.8 | PEP 570 |
| `dict` merge operator `\|` | 3.9 | PEP 584 |
| `list`/`dict`/`set` builtins as generic (`list[int]`) | 3.9 | PEP 585 |
| `match`/`case` pattern matching | 3.10 | PEP 634 |
| Union types `X \| Y` in annotations | 3.10 | PEP 604 |
| `ParamSpec`, `TypeAlias` | 3.10 | PEP 612, PEP 613 |
| `ExceptionGroup`, `except*` | 3.11 | PEP 654 |
| `TaskGroup`, `Runner` | 3.11 | PEP 654 |
| `TypeVarTuple` | 3.11 | PEP 646 |
| `Self` type | 3.11 | PEP 673 |
| `Required`/`NotRequired` in `TypedDict` | 3.11 | PEP 655 |
| `tomllib` in stdlib | 3.11 | PEP 680 |
| `override` decorator | 3.12 | PEP 698 |
| `type` statement (generic syntax) | 3.12 | PEP 695 |
| Free-threaded build (no GIL) | 3.13t (experimental) | PEP 703 |

When a feature file recommends a feature, it must state the minimum version. When the target interpreter is unknown, prefer the lowest-version idiom that works, or guard with `sys.version_info`. For deeper type-system and async material keyed to version, see `references/details.md`.