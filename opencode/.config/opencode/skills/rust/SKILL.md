---
name: rust
description: Use for Rust implementation, review, API design, async/concurrency, Cargo, testing, performance, unsafe code, or Rust domain work. Select only the guidance relevant to the target crate and decision.
invocation_policy: automatic
---

# Rust Skill Router

Before proposing Rust code, inspect the target crate's `Cargo.toml`, workspace configuration, `rust-version`, edition, selected toolchain, enabled dependency features, and relevant runtime or framework. Treat local compiler availability as distinct from the crate's MSRV. Mark nightly-only, version-sensitive, and crate-specific guidance explicitly.

Use repository conventions when they are compatible with Rust's safety and correctness requirements. Preserve public API and serialized-data compatibility unless a breaking change is intended. Prefer a small, sound change over a generic abstraction or performance optimization that has not been justified by the workload.

## Load by decision

| Work | Load |
|---|---|
| Ownership, borrowing, interior mutability, `Copy`/`Clone` | `features/ownership.md` |
| `Result`, `Option`, error types, propagation, context | `features/error-handling.md` |
| Resource acquisition, `Drop`, guards, pools, transactions | `features/lifecycle.md` |
| Unsafe, FFI, raw pointers, `MaybeUninit`, `Send`/`Sync` | `features/unsafe.md` |
| Public APIs, builders, compatibility, `#[must_use]` | `features/api-design.md` |
| Traits, generics, dispatch, dyn compatibility | `features/traits.md`, `features/zero-cost.md` |
| Type-state, newtypes, invariants, `PhantomData` | `features/type-safety.md`, `features/type-driven.md` |
| Async runtime, cancellation, channels, spawning | `features/async.md` |
| Threads, locks, atomics, parallelism | `features/concurrency.md` |
| Errors across boundaries, retries, resilience | `features/domain-error.md` |
| Numeric representation, overflow, floats | `features/numeric.md` |
| Serialization and deserialization | `features/serde.md` |
| Tests, property tests, concurrency tests | `features/testing.md` |
| Documentation and doctests | `features/documentation.md` |
| Macros | `features/macros.md` |
| Const evaluation and const generics | `features/const-compiletime.md` |
| Conversions | `features/conversions.md` |
| Pattern matching | `features/patterns.md` |
| Collections and memory layout/allocation | `features/collections.md`, `features/memory.md` |
| Measured runtime or build optimization | `features/performance.md`, `features/optimization.md` |
| Lints, modules, dependencies, Cargo/workspaces | `features/linting.md`, `features/project-structure.md`, `features/ecosystem.md` |
| Logging, tracing, diagnostics | `features/observability.md` |
| Domain models | `features/domain-modeling.md` |
| Common review risks | `features/anti-patterns.md` |

## Domain guidance

Load a domain skill alongside the feature guidance that governs the concrete decision:

| Domain | Load | Also consider |
|---|---|---|
| HTTP services and clients | `domain-web/SKILL.md` | async, concurrency, error handling, observability |
| Command-line applications | `domain-cli/SKILL.md` | error handling, project structure, async when applicable |
| Financial systems | `domain-fintech/SKILL.md` | numeric, domain modeling, error handling, observability |

## Shared boundary model

At external boundaries, validate and convert untrusted data into domain types. Add error context at meaningful semantic or ownership transitions, propagate errors until a deliberate handling boundary, and report or log there without duplicating the same failure at every layer. Select synchronization, representation, dependencies, and optimization from the required semantics and measured workload rather than from a universal default.
