# Functional Test Patterns

## 1. Fixtures (conftest.py)

Centralize all configuration in session-scoped fixtures. Env vars with defaults enable CI and local runs without changes.

```python
import pytest
import os

@pytest.fixture(scope="session")
def service_base_url():
    """Base URL for the service under test."""
    return os.getenv("SERVICE_BASE_URL", "http://localhost:8080")

@pytest.fixture(scope="session")
def admin_url():
    """Base URL for admin/health endpoints."""
    return os.getenv("ADMIN_URL", "http://localhost:9090")

@pytest.fixture
def common_headers():
    """Common HTTP headers for all requests."""
    return {"Content-Type": "application/json"}

@pytest.fixture
def sample_request_payload():
    """Standard request payload used by multiple tests."""
    return {
        "session_id": "test-session-001",
        "requestId": "test-request-001",
        "data": [{"key": "value1"}, {"key": "value2"}],
    }
```

**Rules:**
- Every fixture has a name, docstring, and env var default
- Session scope = loaded once per run, not per test
- Fixtures are the *only* place raw strings live

## 2. Helpers (helpers.py)

### Core: `make_request()` — Single HTTP Entry Point

```python
def make_request(method, url, timeout=10, **kwargs):
    """Universal HTTP wrapper with logging."""
    try:
        response = requests.request(method, url, timeout=timeout, **kwargs)
        logger.info(f"{method} {url} -> {response.status_code}")
        return response
    except requests.exceptions.RequestException as e:
        logger.error(f"Request failed: {method} {url} - {str(e)}")
        raise
```

### Health: `wait_for_service()` — Eliminate Race Conditions

```python
def wait_for_service(base_url, endpoint="/health", timeout=30, readiness_field="ready"):
    """Poll health endpoint until service is ready."""
    start_time = time.time()
    url = f"{base_url.rstrip('/')}{endpoint}"
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200 and response.json().get(readiness_field, True):
                return True
        except requests.exceptions.RequestException:
            pass
        time.sleep(2)
    return False
```

### Business: Typed Endpoint Wrappers

```python
def make_business_request(base_url, payload, endpoint="/api/v1/resource/action",
                          headers=None, timeout=10):
    """Typed wrapper for your service's main POST endpoint."""
    if headers is None:
        headers = {"Content-Type": "application/json"}
    url = f"{base_url.rstrip('/')}{endpoint}"
    return make_request("POST", url, json=payload, headers=headers, timeout=timeout)
```

### Validation: Non-Blocking Checks

```python
def validate_response_structure(data):
    """Return dict of bool checks. Caller decides severity."""
    return {
        "has_request_id": "requestId" in data,
        "has_status": "status" in data,
        "has_data": "data" in data,
        "valid_status": data.get("status") in ("ok", "success"),
    }
```

### Timing: Performance Analysis

```python
def analyze_response_times(responses):
    """Timing stats for concurrency/SLA tests."""
    times = [r.elapsed.total_seconds() for r in responses if hasattr(r, "elapsed")]
    return {
        "count": len(times), "min": min(times), "max": max(times),
        "avg": sum(times) / len(times), "total": sum(times),
    } if times else {"error": "No timing data available"}
```

## 3. Test Class Organization

### Core Functionality (test_core.py)

| Class | Tests |
|-------|-------|
| `TestCoreFunctionality` | Happy path, empty data, missing fields, malformed JSON |
| `TestConcurrency` | N concurrent requests, response time SLA, sustained load |
| `TestWorkflow` (pytest.mark.integration) | Health → readiness → business action → validate |

### Good Test Method Template

```python
def test_standard_request(self, service_base_url, common_headers, sample_request_payload):
    """
    Test standard request processing. (Explain WHAT and WHY)

    This test validates: (Checklist of behaviors)
    1. Sends a valid request to the main endpoint
    2. Verifies HTTP 200 response
    3. Validates response structure
    """
    response = make_business_request(service_base_url, sample_request_payload)
    assert response.status_code == 200
    data = response.json()
    validation = validate_response_structure(data)
    assert validation["has_request_id"]
```

## 4. Concurrency Pattern

```python
def test_concurrent_requests(self, service_base_url, common_headers, sample_request_payload):
    N = 10
    with concurrent.futures.ThreadPoolExecutor(max_workers=N) as executor:
        futures = [executor.submit(make_concurrent_request, i) for i in range(N)]
        responses = [f.result() for f in concurrent.futures.as_completed(futures)]
    assert len(responses) == N
    assert sum(1 for r in responses if r.status_code == 200) == N
```

## 5. Integration Workflow Pattern

```python
@pytest.mark.integration
class TestWorkflow:
    def test_complete_workflow(self, service_base_url, admin_url, common_headers):
        # Step 1: Health check
        assert requests.get(f"{admin_url}/health", timeout=10).status_code == 200
        # Step 2: Readiness check
        assert requests.get(f"{admin_url}/readiness", timeout=10).status_code == 200
        # Step 3: Business action
        response = make_business_request(service_base_url, payload)
        assert response.status_code == 200
        # Step 4: Validate
        validation = validate_response_structure(response.json())
        assert validation["has_request_id"]
```
