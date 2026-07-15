# Python Error Handling

Agent guidance for building robust Python error handling. Apply these directives when implementing validation, designing exception hierarchies, handling batch failures, or converting external errors to domain errors.

## Fail-Fast Input Validation

Validate all inputs at API boundaries before any processing begins. Raise immediately on invalid input — do not defer validation to a deeper layer where the original source is ambiguous. Report what failed, why, and the offending value.

```python
def process_order(
    order_id: str,
    quantity: int,
    discount_percent: float,
) -> OrderResult:
    """Process an order with fail-fast validation."""
    if not order_id:
        raise ValueError("'order_id' is required")
    if quantity <= 0:
        raise ValueError(f"'quantity' must be positive, got {quantity}")
    if not 0 <= discount_percent <= 100:
        raise ValueError(
            f"'discount_percent' must be 0-100, got {discount_percent}"
        )
    return _process_validated_order(order_id, quantity, discount_percent)
```

Convert external data to typed domain objects at the system boundary. Parse strings to enums, validate ranges, and normalize formats before the value enters the application core. This prevents invalid state from propagating and makes downstream code trust its inputs.

```python
from enum import Enum

class OutputFormat(Enum):
    JSON = "json"
    CSV = "csv"

def parse_output_format(value: str) -> OutputFormat:
    """Parse string to OutputFormat, raising on invalid input."""
    try:
        return OutputFormat(value.lower())
    except ValueError:
        valid = [f.value for f in OutputFormat]
        raise ValueError(
            f"Invalid format '{value}'. Valid options: {', '.join(valid)}"
        )
```

Prefer Pydantic models for structured input validation with multiple fields — they generate detailed, machine-readable error reports automatically. Use plain `ValueError` for single-field checks at function boundaries.

## Exception Hierarchies

Design domain-specific exception hierarchies that inherit from a single base. Callers can catch the base for broad handling or a specific subclass for targeted recovery. Avoid raising built-in exceptions directly from domain logic — wrap them in domain types that carry context.

```python
class AppError(Exception):
    """Base exception for all application errors."""

class ValidationError(AppError):
    """Input failed validation."""

class NotFoundError(AppError):
    """Requested resource does not exist."""

class UserNotFoundError(NotFoundError):
    """Specific: user lookup failed."""

class ProcessingError(AppError):
    """Batch or operation-level failure."""
```

Map built-in exceptions to domain exceptions at boundaries. When a library raises `KeyError` or `FileNotFoundError`, catch it and re-raise as the domain equivalent with added context. Never let raw library exceptions escape the module that owns the integration.

## Exception Chaining

Always chain exceptions with `raise X from Y` to preserve the full error trail. Implicit chaining (bare `raise X` inside an `except` block) loses the original traceback context. Explicit chaining makes debugging possible.

```python
def load_config(path: str) -> Config:
    try:
        raw = Path(path).read_text()
        return Config.from_yaml(raw)
    except FileNotFoundError as e:
        raise ConfigNotFoundError(f"Config file missing: {path}") from e
    except yaml.YAMLError as e:
        raise ConfigParseError(f"Invalid YAML in {path}") from e
```

Use `from None` only when deliberately suppressing context — and document why. Suppressing context without a comment hides the root cause from future debuggers.

## Partial Failure Handling

In batch operations, do not let a single item failure abort the entire batch. Track successes and failures separately, then report a structured result. Decide per-operation whether to stop on first error (transactional) or continue (best-effort) — and make the choice explicit in the function signature or docstring.

```python
@dataclass
class BatchResult[T]:
    succeeded: list[T]
    failed: list[tuple[Any, Exception]]

def process_batch(items: list[Item]) -> BatchResult[ProcessedItem]:
    """Process items, continuing on per-item failures."""
    succeeded: list[ProcessedItem] = []
    failed: list[tuple[Item, Exception]] = []
    for item in items:
        try:
            succeeded.append(process_single(item))
        except Exception as e:
            failed.append((item, e))
    return BatchResult(succeeded=succeeded, failed=failed)
```

Log each failure with enough context to reproduce (item identifier, error type, message). Surface the failure list to the caller so retry logic can target only the failed items. For retry strategies and backoff, see `resilience.md`.

## User-Friendly Error Messages

Write error messages that explain what failed, why, and how to fix it. Include the offending value and the expected range or format. Avoid generic messages like "Invalid input" — they force the user to guess.

```python
# Good: actionable, specific
raise ValueError(
    f"'page_size' must be between 1 and 100, got {page_size}"
)

# Bad: generic, no context
raise ValueError("Invalid parameter")
```

When errors surface to end users via an API, map domain exceptions to HTTP status codes in a single handler at the framework boundary. Do not scatter status code logic across the application core. For structured logging of these errors, see `observability.md`.

## When to Use

Load this feature file when:
- Implementing input validation at API or service boundaries
- Designing a domain exception hierarchy for an application
- Handling partial failures in batch or multi-item operations
- Converting external library errors to domain-specific exceptions
- Writing user-friendly error messages for APIs or CLIs
- Deciding between fail-fast and continue-on-error strategies

## Cross-References

- For retry, backoff, and circuit breaker strategies: load `resilience.md`
- For structured logging of errors and context: load `observability.md`
- For exception type annotations in `Raises` docstring sections: load `type-safety.md`
- For testing error paths and exception assertions: load `testing.md`