---
name: python
description: Complete Python development skill — style, type safety, error handling, testing, async, packaging, and performance. Load automatically when working on Python projects.
invocation_policy: automatic
---

# Python Skill Assembly

Unified Python knowledge base organized by domain features. Route to the correct feature file based on the task.

## ALWAYS READ

1. Load `technical-patterns.md` before loading any feature file.

This file is MANDATORY. It contains the foundational technical knowledge (GIL, memory model, import system, descriptor protocol, version-specific feature guards) that every feature file builds on. Skipping it leads to shallow, incorrect guidance.

## Configuration

The Python skill directory is the directory containing this file. Feature files are in the `features/` subdirectory. Deep implementation notes live in `references/details.md`.

## Capabilities

### Style Guide
When writing new Python code, reviewing code for style compliance, or configuring ruff:
1. Load `features/style.md` for naming, formatting, imports, docstrings, and ruff configuration

### Type Safety
When adding type annotations, designing generics/protocols, or configuring mypy/pyright:
1. Load `features/type-safety.md` for type hints, generics, protocols, type narrowing, and strict checker configuration

### Error Handling
When designing exception hierarchies, handling partial failure, or writing validation logic:
1. Load `features/error-handling.md` for fail-fast validation, exception chaining, and user-friendly errors

### Testing
When writing tests, setting up pytest fixtures, or establishing test infrastructure:
1. Load `features/testing.md` for pytest fixtures, parametrization, mocking, markers, coverage, and async testing

### Async Programming
When writing asyncio code, managing tasks, or deciding sync vs async:
1. Load `features/async.md` for the event loop, coroutines, gather, timeouts, and common pitfalls

### Packaging
When authoring pyproject.toml, building wheels, or publishing to PyPI:
1. Load `features/packaging.md` for PEP 517/518/621/660, build backends, src layout, and CLI entry points
2. Cross-reference the `python-uv` skill for uv-based packaging workflows

### Project Structure
When designing module layout, defining public APIs, or organizing a repository:
1. Load `features/project-structure.md` for module cohesion, `__all__`, flat vs nested layouts, and test placement

### Design Patterns
When deciding when to abstract vs duplicate, or applying SOLID principles in Python:
1. Load `features/design-patterns.md` for KISS, SRP, composition over inheritance, and separation of concerns

### Anti-Patterns
When reviewing code for common mistakes or auditing a codebase for quality:
1. Load `features/anti-patterns.md` for a checklist of mistakes to avoid (mutable defaults, bare except, global state, God classes)

### Performance
When profiling, optimizing memory, or tuning hot loops:
1. Load `features/performance.md` for cProfile, line_profiler, memory_profiler, GIL implications, and caching strategies

### Resource Management
When writing context managers, handling files/sockets, or managing connection pools:
1. Load `features/resource-management.md` for `__enter__`/`__exit__`, contextlib, and cleanup patterns

### Resilience
When implementing retry logic, circuit breakers, or timeout strategies:
1. Load `features/resilience.md` for exponential backoff, jitter, and transient vs permanent failure handling

### Observability
When adding structured logging, metrics, or distributed tracing:
1. Load `features/observability.md` for structlog, Prometheus, OpenTelemetry, and correlation IDs

### Configuration
When managing settings, environment variables, or secrets:
1. Load `features/configuration.md` for pydantic-settings, .env files, config hierarchies, and 12-factor app config

### Background Jobs
When working with task queues, Celery, RQ, or arq:
1. Load `features/background-jobs.md` for task queue patterns, worker management, retry in queues, and dead letter queues

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics. For deep implementation details beyond a feature file, consult `references/details.md`.