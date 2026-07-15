# Python Type Safety

Agent guidance for applying Python's type system to catch errors at static analysis time. Type annotations are enforced documentation — tooling validates them automatically. Use these directives when annotating code, designing generics or protocols, or configuring strict type checkers.

## Type Annotations for Public APIs

Require type annotations on every public function, method, and class attribute. Private helpers may omit annotations only when the signature is trivially obvious. Annotate return types even when the function returns `None` — explicit `-> None` signals intent.

```python
class UserRepository:
    def __init__(self, db: Database) -> None:
        self._db = db

    async def find_by_id(self, user_id: str) -> User | None:
        """Return User if found, None otherwise."""
        ...

    async def save(self, user: User) -> User:
        """Save and return user with generated ID."""
        ...
```

Prefer Python 3.10+ union syntax (`X | None`) over `Optional[X]` and `Union[X, Y]`. The pipe syntax is shorter, renders better in editors, and is the forward-looking standard. Reserve `typing.Optional` for code that must support Python 3.9.

```python
# Preferred (3.10+)
def find_user(user_id: str) -> User | None: ...
def parse_value(v: str) -> int | float | str: ...

# Legacy (3.9 and earlier only)
from typing import Optional
def find_user(user_id: str) -> Optional[User]: ...
```

Minimize `Any`. Use specific types, generics, or `object` with runtime checks. When interfacing with untyped third-party code, wrap the boundary in a typed adapter rather than letting `Any` propagate.

## Generics and Protocols

Use `TypeVar` and `Generic` to preserve type information across reusable containers and functions. Bound type variables to meaningful constraints so the type checker rejects nonsensical instantiations.

```python
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E", bound=Exception)

class Result(Generic[T, E]):
    """Represents either a success value or an error."""

    def __init__(self, value: T | None = None, error: E | None = None) -> None:
        if (value is None) == (error is None):
            raise ValueError("Exactly one of value or error must be set")
        self._value = value
        self._error = error

    def unwrap(self) -> T:
        """Return the value or raise the stored error."""
        if self._error is not None:
            raise self._error
        return self._value  # type: ignore[return-value]
```

Prefer `Protocol` over ABCs for structural typing. Protocols define interfaces without forcing inheritance — callers depend on shape, not lineage. This enables duck typing with static guarantees.

```python
from typing import Protocol

class SupportsClose(Protocol):
    def close(self) -> None: ...

def release(resource: SupportsClose) -> None:
    resource.close()  # Any object with close() works, no inheritance required
```

Use `ParamSpec` when forwarding callable signatures (decorators, wrappers). Avoid `Callable[..., Any]` — it discards the signature and defeats the type checker.

## Type Narrowing

Use `isinstance` guards, `None` checks, and `match` statements to narrow types within code blocks. The type checker tracks these branches and refines the type automatically.

```python
def process_items(items: list[Item | None]) -> list[ProcessedItem]:
    # Filter narrows list[Item | None] to list[Item]
    valid = [item for item in items if item is not None]
    return [process(item) for item in valid]

def handle_command(cmd: Command) -> str:
    # match-based narrowing (3.10+)
    match cmd:
        case Read(path=p):
            return read_file(p)
        case Write(path=p, data=d):
            return write_file(p, d)
        case _:
            raise ValueError(f"Unknown command: {cmd!r}")
```

Use `TypeGuard` for custom narrowing functions when a predicate is too complex for a simple `isinstance` check. The guard tells the checker that a `True` return narrows the argument type.

```python
from typing import TypeGuard

def is_str_list(val: list[object]) -> TypeGuard[list[str]]:
    return all(isinstance(x, str) for x in val)

def join_all(items: list[object]) -> str:
    if is_str_list(items):
        return ",".join(items)  # items narrowed to list[str]
    raise TypeError("Expected list of strings")
```

Avoid `cast()` unless interfacing with untyped code that the checker cannot follow. Prefer restructuring the code so the type flows naturally.

## Strict Checker Configuration

Enforce strict mypy or pyright in CI. Start with `strict = true` and relax specific modules via overrides rather than weakening the global config. For existing codebases, enable strict mode incrementally — annotate one module at a time and gate the strict check behind a per-module override until each is ready.

```python
# pyproject.toml — mypy strict baseline
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true
disallow_incomplete_defs = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false

# pyright strict baseline
[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"
```

Run the type checker in pre-commit and CI. Treat type errors as build failures — do not merge code that does not pass strict checks. When a third-party library lacks stubs, install `types-*` packages or provide a local stub rather than ignoring the module.

## When to Use

Load this feature file when:
- Adding type annotations to existing untyped code
- Designing generic classes or functions that must preserve type information
- Defining structural interfaces with `Protocol` instead of ABCs
- Configuring mypy or pyright for strict type checking
- Implementing type narrowing via `isinstance`, `match`, or `TypeGuard`
- Building type-safe public APIs and libraries

## Cross-References

- For naming and docstring conventions on typed signatures: load `style.md`
- For testing type stubs and typed interfaces: load `testing.md`
- For exception types used in `Raises` sections: load `error-handling.md`