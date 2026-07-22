# Python Resilience

Agent guidance for building fault-tolerant Python code that survives transient failures. Apply these directives when a system calls external services, networks, or any dependency that can fail temporarily. Resilience is the boundary between "fail fast on bad input" and "retry on transient outage" — see `error-handling.md` for the fail-fast side.

## Transient Versus Permanent Failures

Classify every failure before deciding to retry. Retry only transient failures — network timeouts, connection resets, temporary service unavailability, rate limiting. Never retry permanent failures: invalid credentials, malformed requests, `ValueError`, `TypeError`, or HTTP 4xx (except 429). Retrying a permanent error wastes resources and delays the user's error.

```python
import httpx

TRANSIENT_EXCEPTIONS = (ConnectionError, TimeoutError, httpx.ConnectError, httpx.ReadTimeout)
RETRY_STATUS_CODES = {429, 502, 503, 504}

def is_transient(response: httpx.Response) -> bool:
    return response.status_code in RETRY_STATUS_CODES
```

## Retry Patterns

Centralize retry logic in a decorator or client wrapper. Never scatter ad-hoc retry loops across call sites — duplicated logic drifts and causes double-retry bugs. Bound every retry with both a maximum attempt count and a maximum total duration so a failing dependency cannot trigger an infinite loop.

## Exponential Backoff

Increase the wait between retries exponentially. Linear or constant waits hammer a recovering service and extend outage. Start at a short delay (e.g., 1 second) and double each attempt, capped at a maximum (e.g., 30 seconds). Combine the cap with a total-duration stop so a long tail of retries cannot exceed the caller's own timeout.

## Jitter

Add randomized jitter to every backoff delay. Without jitter, synchronized clients retry in lockstep after a shared outage, producing a thundering herd that re-overloads the service. Jitter spreads retries across a window and lets the dependency recover.

```python
import random
import time

def backoff_with_jitter(attempt: int, base: float = 1.0, cap: float = 30.0) -> float:
    delay = min(base * (2 ** attempt), cap)
    return delay * (0.5 + random.random() * 0.5)
```

## Circuit Breakers

Protect dependencies with a circuit breaker when retrying risks making an outage worse. A breaker has three states: closed (calls flow normally), open (calls fail fast without hitting the dependency), and half-open (a limited probe tests whether the dependency has recovered). Open the breaker after a threshold of consecutive failures; transition to half-open after a cooldown; close it after successful probes. This prevents a cascading failure where every service retries a dead dependency.

## Timeout Strategies

Set a timeout on every network and concurrent operation. An unbounded call can hang forever and exhaust a worker pool. Use `asyncio.wait_for` for async code and `concurrent.futures` timeouts for thread or process pools. Choose the timeout from the caller's budget, not the dependency's default.

```python
import asyncio

async def fetch_with_timeout(url: str, timeout: float = 10.0) -> dict:
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await asyncio.wait_for(client.get(url), timeout=timeout)
            return response.json()
    except asyncio.TimeoutError:
        raise TransientError(f"fetch timed out after {timeout}s")
```

## Tenacity Library Patterns

Prefer the `tenacity` library for production retry logic. It encodes retry classification, backoff, jitter, stop conditions, and logging in a declarative decorator, keeping business logic free of resilience concerns.

```python
from tenacity import retry, stop_after_attempt, stop_after_delay, wait_exponential_jitter, retry_if_exception_type

@retry(
    retry=retry_if_exception_type(TRANSIENT_EXCEPTIONS),
    stop=stop_after_attempt(5) | stop_after_delay(60),
    wait=wait_exponential_jitter(initial=1, max=30),
)
def fetch_data(url: str) -> dict:
    response = httpx.get(url, timeout=10)
    response.raise_for_status()
    return response.json()
```

Log every retry attempt — silent retries hide systemic problems. Monitor retry rates; a rising rate signals a degrading dependency, not a reason to increase attempt counts.

## When to Use

Load this feature file when:
- Adding retry logic to external service or network calls
- Implementing timeouts for concurrent or async operations
- Building circuit breakers to protect downstream dependencies
- Classifying whether a failure is transient or permanent
- Choosing a backoff and jitter strategy for a retrying client

## Cross-References

- For fail-fast validation and exception hierarchies (the non-retry side): load `error-handling.md`
- For centralized retry as the fix for scattered retry anti-patterns: load `anti-patterns.md`
- For async timeout primitives (`asyncio.wait_for`): load `async.md`
- For logging retry attempts and monitoring rates: load `observability.md`