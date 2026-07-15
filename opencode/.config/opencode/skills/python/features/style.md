# Python Style Guide

Agent guidance for enforcing consistent Python style. Apply these directives when writing or reviewing Python code, configuring project tooling, or establishing team conventions.

## Ruff Configuration

Enforce ruff as the single linter and formatter for every Python project. Ruff replaces flake8, isort, and black with one fast tool — do not mix multiple formatters. Configure it in `pyproject.toml` and pin `target-version` to the project's minimum supported Python.

```python
# pyproject.toml excerpt — enforce this baseline
[tool.ruff]
line-length = 120
target-version = "py312"

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort import sorting
    "B",    # flake8-bugbear
    "C4",   # flake8-comprehensions
    "UP",   # pyupgrade
    "SIM",  # flake8-simplify
]
ignore = ["E501"]  # line length handled by the formatter

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

Run `ruff check --fix .` to lint and auto-fix, then `ruff format .` to format. Wire both into pre-commit and CI so style drift cannot land on the main branch. When a rule conflict arises, prefer fixing the code over disabling the rule; reserve `noqa` comments for genuine false positives and document why inline.

## Naming Conventions

Enforce PEP 8 naming with descriptive names — clarity over brevity. Avoid abbreviations that require the reader to guess intent.

```python
# Classes: PascalCase. Keep acronyms uppercase.
class UserRepository: ...
class HTTPClientFactory: ...

# Functions, methods, variables: snake_case
def get_user_by_email(email: str) -> User | None: ...
retry_count = 3
max_connections = 100

# Module-level constants: SCREAMING_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Modules and files: snake_case, no abbreviations
# user_repository.py  (good)
# usr_repo.py         (avoid)
```

Reject names that repeat the type or package context (`user_repository.UserRepository` is redundant — prefer `user_repository.Repository`). Prefix boolean variables and methods with `is_`, `has_`, or `should_` so call sites read naturally.

## Import Organization

Group imports in three blocks separated by blank lines: standard library, third-party, then local application imports. Use absolute imports exclusively — relative imports (`from ..utils import x`) obscure the module hierarchy and break refactoring tools.

```python
# Standard library
import os
from collections.abc import Callable
from pathlib import Path

# Third-party
import httpx
from pydantic import BaseModel

# Local application
from myproject.models import User
from myproject.services import UserService
```

Configure ruff's isort (`I`) to enforce grouping automatically. Never use `import *` — it pollutes the namespace and hides dependencies from static analysis.

## Docstrings

Require Google-style docstrings on every public class, method, and function. Private helpers may omit them when the purpose is obvious from the name. Include `Args`, `Returns`, `Raises`, and `Example` sections only when they add information beyond the signature.

```python
def process_batch(
    items: list[Item],
    max_workers: int = 4,
    on_progress: Callable[[int, int], None] | None = None,
) -> BatchResult:
    """Process items concurrently using a worker pool.

    Args:
        items: The items to process. Must not be empty.
        max_workers: Maximum concurrent workers. Defaults to 4.
        on_progress: Optional callback receiving (completed, total) counts.

    Returns:
        BatchResult containing succeeded items and any failures.

    Raises:
        ValueError: If items is empty.
        ProcessingError: If the batch cannot be processed.

    Example:
        >>> result = process_batch(items, max_workers=8)
    """
    ...
```

Treat docstrings as code: update them in the same commit as the implementation. Stale docstrings are worse than no docstrings because they actively mislead.

## Line Length and Formatting

Set line length to 120 characters. This balances modern display widths against readability. Let the formatter handle wrapping — do not hand-align arguments or break chains arbitrarily. When a method chain grows long, wrap before the leading dot and keep each call on its own line.

```python
# Good: explicit line breaks before the dot
result = (
    db.query(User)
    .filter(User.active.is_(True))
    .order_by(User.created_at.desc())
    .limit(10)
    .all()
)
```

Avoid trailing whitespace and files without a trailing newline — both are formatter responsibilities. Do not exceed two levels of nested parentheses for string formatting; prefer f-strings over `.format()` or `%` formatting.

## When to Use

Load this feature file when:
- Writing new Python code that must conform to project style
- Reviewing a pull request for style compliance
- Configuring ruff, mypy, or pyright for a new or existing project
- Establishing team coding standards or a style guide document
- Writing or auditing docstrings for public APIs

## Cross-References

- For type annotation rules that complement naming and signatures: load `type-safety.md`
- For error message style and exception naming: load `error-handling.md`
- For test file naming and structure conventions: load `testing.md`