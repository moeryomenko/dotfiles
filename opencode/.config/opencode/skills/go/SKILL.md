---
name: go
description: Complete Go development skill — style, idioms, error handling, testing, modern features, linter configuration, and optimization. Load automatically when working on Go projects.
invocation_policy: automatic
---

# Go Skill Assembly

Unified Go knowledge base organized by domain features. Route to the correct feature file based on the task.

## Configuration

The Go skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Style Guide
When writing new Go code or reviewing code for style compliance:
1. Load `features/style.md` for naming, formatting, imports, and core conventions
2. Load `features/idioms.md` for slices, maps, defer, channels, goroutines, and struct patterns

### Error Handling
When designing error strategies, wrapping errors, or handling panics:
1. Load `features/error-handling.md`

### Testing
When writing tests or setting up test infrastructure:
1. Load `features/testing.md` for table-driven tests, helpers, and test patterns
2. For Docker-based functional test infrastructure: the testing feature covers it

### Modern Go Features
When working with specific Go versions or modernizing code:
1. Load `features/modern-features.md` for version-organized feature reference

### Linter Configuration
When setting up golangci-lint, selecting linters, or configuring CI gates:
1. Load `features/linter-guide.md`

### Performance Optimization
When profiling, optimizing memory, writing benchmarks, or tuning GC:
1. Load `features/optimization.md`

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.
