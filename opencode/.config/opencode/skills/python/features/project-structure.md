# Project Structure

Directives for organizing Python modules, defining public APIs, and laying out test trees. Apply these rules when starting a new project, reorganizing an existing one, or reviewing module boundaries.

## Module Cohesion

Group code that changes together into the same module. A module should have one reason to change; if a file accumulates unrelated responsibilities, split it. Cohesion is the primary organizing principle — directory shape follows from it.

- Keep one concept per file. `user_service.py` (business logic), `user_repository.py` (data access), and `user_models.py` (data structures) are three cohesive files; a single `user.py` holding all three is not.
- Split a module when it exceeds roughly 300-500 lines or when its classes change for unrelated reasons.
- Name files after their concept: `snake_case` matching the primary class or function. `UserService` belongs in `user_service.py`.

```python
# user_service.py — cohesive: only user business logic.
from .models import User
from .repository import UserRepository


class UserService:
    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo

    def get_user(self, user_id: int) -> User:
        return self._repo.fetch(user_id)
```

## Explicit Public APIs with `__all__`

Define the public surface of every package via `__all__`. Anything not listed is an internal implementation detail that consumers must not import. This makes refactoring safe: unlisted names can change or disappear without a breaking change.

- Populate `__all__` in every package `__init__.py` that re-exports symbols.
- Prefix internal helpers with a single underscore and omit them from `__all__`.
- Keep `__all__` sorted and explicit — do not use `import *` to populate it.

```python
# mypkg/services/__init__.py
from .user_service import UserService
from .order_service import OrderService
from .exceptions import ServiceError

__all__ = [
    "OrderService",
    "ServiceError",
    "UserService",
]
```

## Flat vs Nested Layouts and the src Layout

Prefer shallow directory trees. Add a sub-package only when a genuine sub-domain requires isolation; deep nesting (`core/internal/services/impl/user/`) makes imports verbose and navigation painful.

Use the src layout (`src/<package>/`) for any project intended for installation or distribution. The src layout prevents accidental imports from the working directory: tests must install the package (editable or otherwise) before importing it, which catches packaging bugs early. See `packaging.md` for the build-backend configuration that pairs with the src layout.

```python
# src/mypkg/__init__.py — public re-exports live here.
from .core import Core
from .exceptions import MyError

__all__ = ["Core", "MyError"]
__version__ = "1.0.0"
```

## Test File Placement and Namespace Packages

Place tests in a top-level `tests/` directory mirroring the source tree. Use `conftest.py` for shared fixtures so they are discovered by pytest without explicit imports. Colocated tests (`test_foo.py` next to `foo.py`) are acceptable for small libraries but do not scale to multi-package repositories.

- Put shared fixtures in `tests/conftest.py`; pytest auto-discovers them.
- Mirror the source layout under `tests/` so a failing test points to the right module.
- Use namespace packages (omit `__init__.py`) only when splitting one logical package across multiple distributions. For ordinary projects, regular packages with `__init__.py` are clearer.

```python
# tests/conftest.py — shared fixture available to every test.
import pytest

from mypkg.core import Core


@pytest.fixture
def core_instance() -> Core:
    return Core()
```

## When to Use

- Starting a new Python project and deciding the directory layout.
- Reorganizing a codebase that has grown tangled or has unclear module boundaries.
- Defining or auditing the public API surface of a package.
- Deciding test placement strategy for a multi-package repository.

## Cross-References

- See `packaging.md` for build-backend configuration that pairs with the src layout.
- See `design-patterns.md` for cohesion and single-responsibility principles applied to module boundaries.
- See `testing.md` for `conftest.py` fixture scope, parametrization, and test markers.
- See `anti-patterns.md` for structural mistakes to avoid (God classes, circular imports).