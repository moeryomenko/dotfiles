# Python Testing

Agent guidance for implementing robust Python test suites with pytest. Apply these directives when writing tests, setting up fixtures, mocking dependencies, or establishing test infrastructure.

## pytest Fixtures

Use fixtures for setup, dependency injection, and teardown. Declare fixtures in `conftest.py` when shared across multiple test files; keep file-local fixtures in the test module. Choose the narrowest scope that satisfies the test — function scope by default, escalating only when setup is expensive.

```python
import pytest

@pytest.fixture
def db_session():
    """Function-scoped: fresh session per test."""
    session = Session()
    yield session
    session.close()

@pytest.fixture(scope="module")
def expensive_dataset():
    """Module-scoped: loaded once per test module."""
    return load_large_dataset()

@pytest.fixture(scope="session")
def app_server():
    """Session-scoped: shared across the entire test run."""
    server = start_test_server()
    yield server
    server.stop()
```

Prefer fixture composition over manual setup duplication. Fixtures can depend on other fixtures by naming them as parameters. Use `yield` fixtures for teardown — code after `yield` runs even if the test fails. Avoid `scope="session"` for stateful resources unless the resource is genuinely immutable across tests.

## Parametrization

Use `@pytest.mark.parametrize` to express multiple test cases in a single function. Parametrize on inputs and expected outputs together — never assert the same outcome across parameter rows when the inputs should produce different results. Name each case with `ids` so failures point to the exact scenario.

```python
@pytest.mark.parametrize(
    ("email", "expected_valid"),
    [
        ("user@example.com", True),
        ("no-at-sign.com", False),
        ("", False),
        ("user@.com", False),
    ],
    ids=["valid", "missing_at", "empty", "bad_domain"],
)
def test_email_validation(email: str, expected_valid: bool) -> None:
    assert is_valid_email(email) is expected_valid
```

Prefer parametrization over writing near-identical test functions. When a test needs both parametrized inputs and fixture injection, combine them — pytest resolves fixtures and parameters independently.

## Mocking

Use `unittest.mock.Mock` and `patch` to isolate the unit under test from external dependencies. Mock at the boundary closest to the unit — patch where the dependency is looked up, not where it is defined. Prefer `patch.object` over `patch` with string paths when the target is a class attribute.

```python
from unittest.mock import Mock, patch

def test_retries_on_transient_error() -> None:
    client = Mock()
    client.request.side_effect = [
        ConnectionError("Failed"),
        ConnectionError("Failed"),
        {"status": "ok"},
    ]
    service = ServiceWithRetry(client, max_retries=3)
    result = service.fetch()
    assert result == {"status": "ok"}
    assert client.request.call_count == 3
```

Avoid mocking the unit under test itself — if you need to, the unit is too large. Prefer real fakes or stubs over mocks for value objects. Use `side_effect` for sequences of behaviors and `return_value` for static responses. Assert on interactions (`call_count`, `assert_called_with`) only when the interaction is part of the contract — do not over-specify.

## Test Markers

Mark tests with `@pytest.mark.slow`, `@pytest.mark.integration`, `@pytest.mark.skip`, or `@pytest.mark.xfail` to control execution. Register custom markers in `pyproject.toml` to avoid warnings. Use markers to separate fast unit tests from slow integration tests in CI pipelines.

```python
@pytest.mark.slow
def test_large_dataset_processing() -> None:
    ...

@pytest.mark.integration
def test_database_round_trip() -> None:
    ...

@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug() -> None:
    assert False
```

Run subsets with `pytest -m "not slow"` in fast feedback loops and `pytest -m integration` in full CI. Reserve `xfail` for known bugs with a tracking issue — remove the marker once the bug is fixed. Do not use `skip` as a permanent gate; either fix the test or delete it.

## Coverage and Async Testing

Measure coverage with `pytest-cov` but treat the number as a signal, not a target. Aim for meaningful coverage of critical paths — 100% coverage of trivial getters adds no value. Fail CI below a threshold only after the suite is mature.

```python
# pyproject.toml
[tool.pytest.ini_options]
addopts = "--cov=myapp --cov-report=term-missing --cov-fail-under=80"
```

For async tests, use `pytest-asyncio` with explicit `asyncio` mode. Mark async tests with `@pytest.mark.asyncio` or enable auto mode in config. Avoid mixing sync and async fixtures in the same test — the event loop lifecycle differs.

```python
import pytest

@pytest.mark.asyncio
async def test_async_fetch() -> None:
    result = await async_client.fetch("https://example.com")
    assert result.status == 200
```

## TDD Patterns

Follow the Arrange-Act-Assert (AAA) pattern. Separate the three phases with blank lines so the structure is visible. One test, one assertion focus — multiple assertions are acceptable when they verify the same logical outcome.

```python
def test_create_user_with_valid_data_returns_user() -> None:
    # Arrange
    input_data = CreateUserInput(email="user@example.com", name="Alice")

    # Act
    user = create_user(input_data)

    # Assert
    assert user.email == "user@example.com"
    assert user.id is not None
```

Name tests as `test_<unit>_<scenario>_<expected_outcome>`. Write the test before the implementation (red), make it pass (green), then refactor. When fixing a bug, write a failing test that reproduces it first — this prevents regressions and confirms the fix.

## When to Use

Load this feature file when:
- Writing unit, integration, or functional tests with pytest
- Setting up shared fixtures in `conftest.py`
- Parametrizing tests across multiple input scenarios
- Mocking external dependencies with `unittest.mock`
- Configuring test markers and coverage thresholds
- Testing async code with `pytest-asyncio`
- Following TDD (Arrange-Act-Assert) patterns

## Cross-References

- For async test patterns and event loop pitfalls: load `async.md`
- For type stubs and typed interface testing: load `type-safety.md`
- For exception assertions and error path testing: load `error-handling.md`
- For retry logic testing patterns: load `resilience.md`