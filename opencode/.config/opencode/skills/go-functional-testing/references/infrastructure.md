# Functional Test Infrastructure

## 1. Docker Compose (docker-compose.test.yml)

### Service Dependency Chain

```
minio (data layer) → minio-setup → data-upload → SUT → functional-tests (test runner)
```

Each service waits for `condition: service_healthy` or `condition: service_completed_successfully` on its dependency.

### Template Structure

```yaml
name: your-service-tests

services:
  # ── Data Layer ──
  minio:
    image: minio/minio:RELEASE.2024-11-07T00-52-20Z
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 5s; timeout: 3s; retries: 10; start_period: 10s

  # ── Service Under Test ──
  your-service:
    build:
      context: ..
      dockerfile: Dockerfile
    ports:
      - "8080:8080"   # Service port
      - "9090:9090"   # Admin/health port
    depends_on:
      minio:
        condition: service_healthy
    environment:
      - SERVICE_PORT=8080
      - ADMIN_PORT=9090
      - STORAGE_ENDPOINT=http://minio:9000
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "9090"]
      interval: 5s; timeout: 3s; retries: 10; start_period: 20s

  # ── Test Runner ──
  functional-tests:
    image: python:3.11-slim
    working_dir: /tests
    depends_on:
      your-service:
        condition: service_healthy
    environment:
      - SERVICE_BASE_URL=http://your-service:8080
      - ADMIN_URL=http://your-service:9090
      - PYTHONUNBUFFERED=1
    volumes:
      - ./functional:/tests:ro
      - test-results:/results
    command: >
      sh -c "
        pip install --no-cache-dir -r requirements.txt &&
        pytest -v --tb=short --junitxml=/results/junit.xml
      "

networks:
  test-network:
    driver: bridge

volumes:
  test-results:
  minio-data:
```

**Non-negotiable:**
- `condition: service_healthy` prevents race conditions
- Read-only volume `./functional:/tests:ro` prevents test code modification
- JUnit XML output via `--junitxml=` for CI integration
- Dedicated bridge network with hostname-based service discovery
- Resource limits (`deploy.resources`) to prevent CI hogging

## 2. Makefile Targets

```makefile
DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null || echo "docker compose")
HEALTH_TIMEOUT := 60

.PHONY: functional-tests
functional-tests: ## Run functional tests in Docker
	@$(call run-docker-tests,tests/docker-compose.test.yml,functional-tests,test-results,junit.xml)

# ── Helper: Wait for service health ──
define wait-for-health
	SECONDS=0; \
	while [ $$SECONDS -lt $(HEALTH_TIMEOUT) ]; do \
		HEALTH_STATUS=$$(docker inspect -f {{.State.Health.Status}} \
			$$($(DOCKER_COMPOSE) -f $(1) ps -q your-service 2>/dev/null) 2>/dev/null); \
		if [ "$$HEALTH_STATUS" = "healthy" ]; then echo "Service is healthy"; break; fi; \
		sleep 2; \
	done; \
	if [ $$SECONDS -ge $(HEALTH_TIMEOUT) ]; then \
		echo "Service failed to become healthy"; \
		$(DOCKER_COMPOSE) -f $(1) logs your-service; \
		$(DOCKER_COMPOSE) -f $(1) down --volumes; \
		exit 1; \
	fi
endef

# ── Helper: Extract test results from Docker volume ──
define extract-results
	mkdir -p $(2); \
	docker run --rm -v $(1):/source:ro -v $$(pwd)/$(2):/dest \
		alpine sh -c "cp -r /source/* /dest/ 2>/dev/null || true"
endef

# ── Helper: Run Docker-based tests with lifecycle management ──
define run-docker-tests
	$(DOCKER_COMPOSE) -f $(1) up --build -d your-service; \
	$(call wait-for-health,$(1)); \
	$(DOCKER_COMPOSE) -f $(1) run --rm $(2); \
	TEST_EXIT_CODE=$$?; \
	$(call extract-results,ble-predictor-tests_test-results,$(3)); \
	$(DOCKER_COMPOSE) -f $(1) down --volumes --remove-orphans; \
	exit $$TEST_EXIT_CODE
endef
```

**Guarantees:**
1. Always builds latest code (`up --build`)
2. Waits for `healthy` before testing
3. Always cleans up containers and volumes (even on failure)
4. Propagates exit code to CI
5. Extracts JUnit XML results to host

## 3. validate-setup.sh

Pre-flight checks before running tests. Checks:
- Docker and Docker Compose are installed
- Required data files exist
- Docker Compose config is valid
- Test files exist

Pattern:
```bash
#!/bin/bash
set -e
for cmd in docker docker compose; do
    command -v $cmd &> /dev/null || { echo "❌ $cmd missing"; exit 1; }
done
docker compose -f tests/docker-compose.test.yml config > /dev/null
```

## 4. CI Integration

- Only requires `docker` and `docker compose` on the CI runner
- JUnit XML report extracted from `test-results` volume for artifact collection
- Exit code propagates: 0 = pass, non-zero = fail
- Cleanup guaranteed via `down --volumes --remove-orphans`
- No host toolchain dependencies (Go, Python, etc.)
