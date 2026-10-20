---
name: go
description: Routes Go work to focused guidance for style, design, errors, testing, language-version features, linting, and performance.
invocation_policy: automatic
---

# Go Skill

Load only the feature documents that materially affect the current task. Before using version-specific advice, inspect the module's `go` directive and selected toolchain.

## Routes

### Style and API design
Load `features/style.md` when writing or reviewing naming, formatting, imports, documentation, exported APIs, or package structure.

Load `features/idioms.md` when a design involves interfaces, ownership of slices or maps, synchronization, goroutines, channels, `defer`, type assertions, or process lifecycle.

### Error policy
Load `features/error-handling.md` when defining errors, choosing wrapping semantics, reporting errors, or considering panic and recovery boundaries.

### Testing
Load `features/testing.md` when writing unit, integration, or end-to-end tests; choosing test doubles; or working with test concurrency and contexts.

### Language-version features
Load `features/modern-features.md` when the task targets a specific Go release or considers adopting newer standard-library or language features.

### Linting
Load `features/linter-guide.md` when introducing, configuring, or interpreting `golangci-lint` and CI quality gates.

### Performance
Load `features/optimization.md` when profiling, benchmarking, investigating allocations or GC, or considering concurrency and compiler-oriented changes.
