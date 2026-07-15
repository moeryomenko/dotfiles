# Python — Deep Implementation Notes

This file is the progressive disclosure layer. Load it only when the navigation tier (`SKILL.md` plus the relevant `features/*.md`) is insufficient for the task at hand. It covers advanced patterns that cross multiple feature boundaries or require runtime-version awareness.

For the foundational technical knowledge (GIL, memory model, import system, descriptor protocol), read `../technical-patterns.md` first.

## Advanced async patterns

For basic asyncio usage (event loop, coroutines, `gather`, common pitfalls), see `../features/async.md`. This section covers the structured-concurrency primitives added in 3.11+.

### TaskGroup and structured concurrency

`asyncio.TaskGroup` (3.11+, PEP 654) scopes concurrent tasks to a block. Any exception inside the group cancels the siblings and propagates after the group exits. This replaces manual `gather` + cancellation bookkeeping and makes cleanup deterministic.

```python
import asyncio

async def fetch(url: str) -> str:
    async with asyncio.timeout(2):  # 3.11+ timeout
        # ... network call ...
        return url

async def main() -> None:
    async with asyncio.TaskGroup() as tg:
        t1 = tg.create_task(fetch("https://a"))
        t2 = tg.create_task(fetch("https://b"))
    # Both tasks are guaranteed complete (or cancelled) here.
    print(t1.result(), t2.result())
```

- A task raising inside the group triggers an `ExceptionGroup` (3.11+, PEP 654) wrapping the original. Catch with `except*` to handle by type, or `except ExceptionGroup` to handle the group as a whole.
- `asyncio.timeout(seconds)` (3.11+) is a context manager that cancels the enclosing task on expiry. Prefer it over `asyncio.wait_for` for new code; `wait_for` swallows `CancelledError` semantics in subtle ways.
- `asyncio.Runner` (3.11+) runs a top-level coroutine with a single event loop and supports inter-loop task groups, signal handling, and consistent exception grouping. Use it instead of `asyncio.run` when you need a custom loop policy or interactive debugging.
- Cancellation is cooperative: a cancelled task receives `CancelledError` at its next `await`. A task that never awaits cannot be cancelled — flag long CPU-bound sections inside async code; they block the loop and defeat cancellation. See `../features/async.md` for the blocking-loop pitfall checklist.

### Cancellation scopes and shielding

`asyncio.shield(coro)` protects a coroutine from outer cancellation, but the outer task still observes `CancelledError`. The shielded work continues; only the waiter is cancelled. This is the correct pattern for "cancel the wait, not the work" semantics (e.g., a heartbeat that must complete even if the caller times out). Combine with `TaskGroup` for structured cleanup; do not use `shield` to paper over missing cancellation handling.

## Advanced type system features

For basic annotations, generics, and protocols, see `../features/type-safety.md`. This section covers the features needed for library-grade type safety.

### Overloads

`@typing.overload` lets a function advertise multiple signatures for different argument shapes. The overloads are erased at runtime; only the final non-`@overload` implementation runs. Use overloads when the return type depends on argument values or types in a way a single signature cannot express.

```python
from typing import overload, Literal

@overload
def parse(value: int) -> int: ...
@overload
def parse(value: str) -> str: ...
@overload
def parse(value: None) -> None: ...
def parse(value: int | str | None) -> int | str | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    return value.strip()
```

- Every `@overload` must be followed by a non-overload implementation with a compatible signature. A missing or mismatched implementation is a type-checker error.
- `Literal` types narrow string/int/bool/enum/None arguments to specific values. Combine with overloads to express "if you pass `mode="r"`, you get `TextIO`; if `mode="rb"`, you get `BinaryIO`".
- Recursive types (e.g., a JSON tree) require forward references as strings or `from __future__ import annotations` (3.7+, default behavior in 3.14 per PEP 649). Define `JSONValue = Union[None, bool, int, float, str, list["JSONValue"], dict[str, "JSONValue"]]`.
- `TypedDict` (3.8+, `Required`/`NotRequired` in 3.11+) types dict keys and value types. It is structural: a function accepting `TypedDict` accepts any dict with matching keys. Use it for JSON payloads and config schemas; prefer `pydantic.BaseModel` when runtime validation is also needed.

### ParamSpec and TypeVarTuple

`ParamSpec` (3.10+, PEP 612) captures a callable's parameter signature for forwarding in decorators. `TypeVarTuple` (3.11+, PEP 646) captures a variadic parameter list. Use `ParamSpec` for decorator type preservation; use `TypeVarTuple` for array-shaped generics (Tensor libraries, homogeneous variadic APIs).

```python
from typing import Callable, ParamSpec, TypeVar, Awaitable
import functools

P = ParamSpec("P")
R = TypeVar("R")

def log_calls(func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        # ... log ...
        return func(*args, **kwargs)
    return wrapper
```

For strict mypy/pyright configuration that enforces these features, see `../features/type-safety.md`.

## Advanced testing patterns

For pytest fixtures, parametrization, mocking, and markers, see `../features/testing.md`. This section covers patterns that scale test suites beyond the basics.

### Property-based testing with hypothesis

`hypothesis` generates test cases from a strategy, shrinking failures to minimal reproductions. Use it for invariants over a large input space (parsers, serializers, state machines) where hand-written cases miss edge inputs.

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers(min_value=0, max_value=1000)))
def test_sort_idempotent(values: list[int]) -> None:
    once = sorted(values)
    twice = sorted(once)
    assert once == twice
```

- Keep strategies tight: bound integers, constrain string alphabets. Overly broad strategies generate inputs that exercise error paths unrelated to the invariant under test.
- Use `@example` to pin known edge cases alongside generated ones; generated cases alone are non-deterministic across runs.
- Compose strategies with `st.builds`, `st.one_of`, and `st.recursive` for nested structures. Avoid `st.just` for anything but constants.

### Snapshot testing and fixture composition

- Snapshot testing (`syrupy`, `pytest-snapshot`) records the expected output on first run and compares on subsequent runs. Use it for large stable outputs (rendered HTML, serialized JSON, error messages) where hand-maintaining expected values is unsustainable. Regenerate snapshots deliberately; a diff in the snapshot file is the review artifact.
- Fixture composition: prefer fixture dependencies (a fixture requesting another fixture) over fixture factories returning closures. Composed fixtures are reused across the session by default; scope them (`scope="session"`, `scope="module"`) to avoid repeated expensive setup.
- Parametrize stacking: stack `@pytest.mark.parametrize` decorators to generate the cross product of parameter sets. Use `pytest.param(..., marks=...)` to attach markers (e.g., `pytest.mark.slow`) to specific cases. For async parametrized tests, see `../features/testing.md` and `../features/async.md`.

## Advanced packaging

For `pyproject.toml` basics, build backends, src layout, and PyPI publishing, see `../features/packaging.md`. For uv-based packaging workflows, see the `python-uv` skill. This section covers the patterns that surface in larger or non-standard distributions.

### Namespace packages

PEP 420 namespace packages split one logical package across multiple directories without an `__init__.py` at the namespace root. Use them for plugin ecosystems where multiple distributions contribute to one importable namespace (e.g., `mycompany.tools.*` shipped by several wheels). Avoid them for single-distribution projects — a regular package with an `__init__.py` is simpler and avoids the import-order sensitivity of namespace packages.

- Do not mix namespace and regular packages at the same path. A namespace package whose root later gains an `__init__.py` silently changes import semantics.
- Tools (`mypy`, `pyright`, `pytest`) need configuration to resolve namespace packages correctly; verify the tool sees all contributing directories.

### Editable installs and custom build backends

PEP 660 (3.11+ tooling support) defines editable installs (`pip install -e .`) via the build backend's `build_editable` hook. Modern backends (hatchling, setuptools >= 64, flit) support it; legacy `setup.py develop` is deprecated.

- Editable installs should not copy source into site-packages. If your editable install breaks, check that the backend is current and that `src` layout is configured correctly (see `../features/project-structure.md`).
- Custom build backends implement the PEP 517 hooks (`build_wheel`, `build_sdist`, `build_editable`, `prepare_metadata_for_build_wheel`). Use a custom backend only when code generation, C extension compilation, or vendoring requires it; otherwise prefer hatchling or setuptools. Document the backend in `pyproject.toml` `[build-system]`.
- Build hooks (hatchling's `build-hook`, setuptools `cmdclass`) run at build time for code generation or asset compilation. Keep hooks deterministic and hermetic — a build that depends on network or mutable state produces unreproducible wheels.

## Cross-references

- Foundational technical knowledge (GIL, memory model, import system, descriptor protocol, version table): `../technical-patterns.md`
- Basic async, event loop, coroutines, pitfalls: `../features/async.md`
- Type annotations, generics, protocols, strict checker config: `../features/type-safety.md`
- pytest fixtures, parametrization, mocking, markers: `../features/testing.md`
- pyproject.toml, build backends, src layout, PyPI: `../features/packaging.md`
- Module cohesion, `__all__`, flat vs nested layouts: `../features/project-structure.md`
- uv-based project setup, dependency management, migration: `python-uv` skill (sibling skill directory)