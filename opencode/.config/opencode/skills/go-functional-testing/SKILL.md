---
name: go-functional-testing
description: Set up black-box HTTP functional tests with Docker Compose, pytest, and Python. Covers test infrastructure, fixtures, HTTP helpers, and CI integration. Use when adding end-to-end testing to Go services, porting the ble-predictor functional test approach to other services, or setting up Docker-based integration test suites.
---

# Functional Testing with Docker Compose + pytest

A **3-layer architecture** for black-box HTTP testing of Go services:

```
┌─ Layer 1: Infrastructure (Docker Compose) ─┐
│  Data deps → SUT → Test runner              │
├─ Layer 2: Test Code (Python pytest) ────────┤
│  conftest.py → helpers.py → test_*.py       │
├─ Layer 3: Orchestration (Makefile) ─────────┤
│  make functional-tests                      │
└─────────────────────────────────────────────┘
```

## When to Use

- Adding **black-box functional tests** to a Go service
- Porting the `ble-predictor` test pattern to another service
- Setting up **reproducible Docker-based** test environments
- Creating concurrency, SLA, and load tests alongside functional tests

## Directory Structure

```
tests/
├── functional/
│   ├── conftest.py          # Session-scoped fixtures (URLs, payloads)
│   ├── helpers.py           # HTTP wrappers, validators, timing
│   ├── requirements.txt     # pytest + requests only
│   ├── test_core.py         # Happy path, edge cases, error handling
│   └── test_enhanced.py     # Concurrency, SLA, integration
├── docker-compose.test.yml  # Data layer → SUT → test runner
└── validate-setup.sh        # Pre-flight checks
```

## Quick Start: 7 Steps

1. **Create** `tests/functional/` with `requirements.txt` (`pytest>=8.4.2`, `requests>=2.32.5`)
2. **Write** `conftest.py` — `service_base_url` (session fixture, env var with default), `common_headers`, `sample_request_payload`
3. **Write** `helpers.py` — `make_request()`, `wait_for_service()`, `make_business_request()`, `validate_response_structure()`, `analyze_response_times()`
4. **Write** `test_core.py` — `TestCore` (happy path, edge cases, malformed JSON), `TestConcurrency` (ThreadPoolExecutor, SLA), `TestWorkflow` (health → readiness → business action)
5. **Create** `docker-compose.test.yml` with dependency chain: data layer → SUT (healthcheck) → test runner (condition: service_healthy)
6. **Add** `make functional-tests` to `Makefile` using `run-docker-tests` helper (build → wait → run → extract results → cleanup always)
7. **Create** `validate-setup.sh` checking Docker, compose, data files, and compose config

## Key Patterns

| What | Pattern |
|------|---------|
| **Fixtures** | Session-scoped, env vars with defaults, self-documenting |
| **Helpers** | Single `make_request()` entry point with logging; typed wrappers for business endpoints |
| **Tests** | One class per category (core, concurrency, integration); docstrings explain *what* and *why* |
| **Infra** | `service_healthy` condition prevents race conditions; read-only test volume; JUnit XML output |
| **Cleanup** | `down --volumes --remove-orphans` always runs (even on failure) |
| **CI** | Only `docker` + `docker compose` required on host |

## References

- **Test patterns**: See [references/test-patterns.md](references/test-patterns.md) for conftest fixtures, helpers, and test class templates
- **Infrastructure**: See [references/infrastructure.md](references/infrastructure.md) for Docker Compose, Makefile, validate-setup.sh, and CI
- **Porting guide**: See [references/porting-guide.md](references/porting-guide.md) for step-by-step checklist to apply to any new service
