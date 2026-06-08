# Porting Functional Tests to a New Service

## Step-by-Step Checklist

| # | Step | File |
|---|------|------|
| 1 | Create `tests/functional/` directory | — |
| 2 | Copy `requirements.txt` (pytest + requests only) | `requirements.txt` |
| 3 | Create `conftest.py` with URL + header fixtures | `conftest.py` |
| 4 | Create `helpers.py` with `make_request`, `wait_for_service`, `make_business_request`, `validate_response_structure` | `helpers.py` |
| 5 | Write `test_core.py` with happy-path, edge-case, and error-handling tests | `test_core.py` |
| 6 | Write `test_enhanced.py` with concurrency (ThreadPoolExecutor) and SLA tests | `test_enhanced.py` |
| 7 | Create `docker-compose.test.yml` with: data layer → SUT → test runner | `docker-compose.test.yml` |
| 8 | Add `make functional-tests` target to `Makefile` with lifecycle helpers | `Makefile` |
| 9 | Create `validate-setup.sh` for pre-flight checks | `validate-setup.sh` |
| 10 | Add test stage in CI pipeline | CI config |

## What to Change Per Service

### conftest.py
- Rename `service_base_url` to reflect the service (e.g., `ble_base_url`, `api_base_url`)
- Add service-specific payload fixtures (e.g., `sample_android_request`)
- Set appropriate default ports matching the service's Dockerfile

### helpers.py
- Rename `make_business_request` to the service's action (e.g., `make_prediction_request`)
- Update `validate_response_structure` to check service-specific fields
- Customize `wait_for_service` readiness field to match health endpoint JSON

### test_core.py
- Replace payload structure with the service's API contract
- Update endpoint paths to match the service's routing
- Adjust assertion values to match expected response format

### docker-compose.test.yml
- Replace service image/build with the target service's Dockerfile
- Update environment variables to match the service's configuration
- Adjust health check port and endpoint
- Change service hostnames in test runner environment variables

### Makefile
- Update `wait-for-health` service name (e.g., `ble-predictor` → `your-service`)
- Update volume name in `extract-results` to match compose project name
- Add additional targets if needed (load tests, etc.)

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Shared mutable state between tests | Each test creates own payload via fixtures; no module globals |
| Race conditions on service startup | `condition: service_healthy` + `wait_for_service()` polling |
| Hardcoded URLs in every test | Single `service_base_url` fixture in `conftest.py` |
| No timing SLAs | `test_response_time_sla` checks elapsed < threshold |
| Concurrency not tested | `test_concurrent_requests` with `ThreadPoolExecutor` |
| No cleanup on failure | `down --volumes --remove-orphans` in Makefile helper (always runs) |
| Tests depend on host tools | `python:3.11-slim` container has everything; only Docker needed on host |

## Architectural Principles

| Principle | How Achieved |
|-----------|-------------|
| Deterministic | Docker Compose ensures identical environment every run |
| Fast feedback | Python tests start in <1s (no compilation) |
| Self-documenting | Docstrings on every test explain *what* and *why* |
| CI-native | JUnit XML output, exit codes, artifact collection |
| Minimal deps | 2 Python packages (pytest, requests) — no pytest plugins |
| Isolated | Each test run gets fresh containers + volumes |
| Observable | All HTTP calls logged; results extracted to host |
| Portable | Only requires `docker` and `docker compose` on the host |
