---
name: rust
description: Comprehensive Rust development skill — ownership, error handling, async patterns, unsafe code, API design, memory optimization, performance, testing, and idiomatic Rust. Load automatically when working on Rust projects.
invocation_policy: automatic
---

# Rust Skill Assembly

Unified Rust knowledge base organized by domain features. Contains 320+ rules across 32 categories, synthesized from the Rust API Guidelines, Rust Performance Book, The Rustonomicon, Rust Design Patterns, and patterns from production codebases (tokio, serde, ripgrep, axum, etc.). Current for Rust 1.96 (2024 edition).

## Configuration

The Rust skill directory is the directory containing this file. Feature files are in the `features/` subdirectory. Domain skills are in `domain-*/` subdirectories.

## Rule Priority

When applying rules, prioritize by impact:
- **CRITICAL**: Ownership, Error Handling, Memory, Unsafe, Resource Lifecycle
- **HIGH**: API Design, Async, Concurrency, Optimization, Numeric Safety, Zero-Cost Abstractions, Domain Error Strategy
- **MEDIUM**: Types, Traits, Conversions, Const, Serde, Patterns, Macros, Closures, Collections, Naming, Testing, Documentation, Observability, Performance, Domain Modeling, Type-Driven Design, Ecosystem Integration
- **LOW**: Project Structure, Linting
- **REFERENCE**: Anti-patterns

## Capabilities

### Ownership & Borrowing (CRITICAL)
When working with ownership, borrowing, or lifetime issues:
1. Load `features/ownership.md` for borrowing guidelines, Cow patterns, Arc/Rc/RefCell/Mutex choice, Copy vs Clone, lifetime elision

### Error Handling (CRITICAL)
When designing error strategies, implementing fallible operations, or handling Result/Option:
1. Load `features/error-handling.md` for thiserror/anyhow selection, Result over panic, ? operator, error chaining, context

### Memory Optimization (CRITICAL)
When optimizing memory usage, reducing allocations, or working with collections:
1. Load `features/memory.md` for capacity planning, SmallVec, Box strategies, arena allocators, zero-copy, compact types

### Unsafe Code (CRITICAL)
When writing or reviewing unsafe blocks, FFI, or raw pointer manipulation:
1. Load `features/unsafe.md` for SAFETY comments, scope minimization, Miri CI, MaybeUninit, Send/Sync, extern blocks

### Resource Lifecycle (CRITICAL)
When managing resource lifetimes, implementing Drop, designing cleanup, or using pools:
1. Load `features/lifecycle.md` for RAII, Drop, guard patterns, lazy init, pooling, error path cleanup

### API Design (HIGH)
When designing public APIs, builder patterns, or library interfaces:
1. Load `features/api-design.md` for builders, newtypes, typestate, sealed traits, error handling, trait implementations

### Async/Await (HIGH)
When writing async code with Tokio or other runtimes:
1. Load `features/async.md` for runtime configuration, cancellation, channels, JoinSet, cancellation safety, async fn in traits

### Concurrency (HIGH)
When writing multi-threaded or parallel code:
1. Load `features/concurrency.md` for rayon, scoped threads, atomics, thread-local storage

### Compiler Optimization (HIGH)
When optimizing hot paths or configuring release builds:
1. Load `features/optimization.md` for inline attributes, LTO, codegen units, PGO, target-cpu, SIMD

### Numeric & Arithmetic Safety (HIGH)
When working with numbers, arithmetic, or type conversions:
1. Load `features/numeric.md` for overflow handling, casting, float comparison, saturating arithmetic, NonZero

### Domain Error Strategy (HIGH)
When designing error categorization, retry logic, circuit breakers, or recovery strategies:
1. Load `features/domain-error.md` for error categorization, retryable vs permanent errors, backoff, circuit breaker, fallback

### Zero-Cost Abstractions (HIGH)
When choosing between generics and trait objects, or designing polymorphic APIs:
1. Load `features/zero-cost.md` for static vs dynamic dispatch, impl Trait, dyn Trait, object safety, enum dispatch

### Type Safety (MEDIUM)
When designing types, newtypes, or leveraging the type system:
1. Load `features/type-safety.md` for newtype patterns, enum states, PhantomData, never type, repr attributes

### Type-Driven Design (MEDIUM)
When making invalid states unrepresentable or using type-level state machines:
1. Load `features/type-driven.md` for type state pattern, PhantomData variance, sealed traits, compile-time invariants

### Domain Modeling (MEDIUM)
When designing domain models with DDD patterns in Rust:
1. Load `features/domain-modeling.md` for Entity, Value Object, Aggregate, Repository, Domain Service patterns

### Trait & Generics Design (MEDIUM)
When designing traits or generic abstractions:
1. Load `features/traits.md` for associated types vs generics, blanket impls, dyn vs impl Trait, object safety

### Conversions (MEDIUM)
When implementing From/TryFrom/FromStr or conversion traits:
1. Load `features/conversions.md` for TryFrom, FromStr, AsMut patterns

### Const & Compile-Time (MEDIUM)
When working with compile-time evaluation or const generics:
1. Load `features/const-compiletime.md` for const blocks, const fn, const generics, const vs static

### Serde (MEDIUM)
When implementing serialization or deserialization:
1. Load `features/serde.md` for rename, default, flatten, enum representation, validation

### Pattern Matching (MEDIUM)
When destructuring or pattern matching:
1. Load `features/patterns.md` for let-else, matches!, if-let chains, exhaustive matching, @ bindings

### Macros (MEDIUM)
When writing declarative or procedural macros:
1. Load `features/macros.md` for macro_rules hygiene, proc macro setup, fragment specifiers, error reporting

### Closures (MEDIUM)
When working with closures or callbacks:
1. Load `features/closures.md` for Fn trait bounds, impl Fn return, move capture, static vs dyn dispatch

### Collections (MEDIUM)
When choosing collection types:
1. Load `features/collections.md` for map choice, sequence choice, set membership, BinaryHeap

### Naming Conventions (MEDIUM)
When naming types, functions, methods, or variables:
1. Load `features/naming.md` for casing conventions, prefix conventions, iterator naming, acronyms

### Testing (MEDIUM)
When writing tests or setting up test infrastructure:
1. Load `features/testing.md` for unit test modules, integration tests, property-based testing, mocking, benchmarks

### Documentation (MEDIUM)
When writing doc comments or crate documentation:
1. Load `features/documentation.md` for doc sections, intra-doc links, module docs, examples, crate metadata

### Observability (MEDIUM)
When adding logging, tracing, or structured diagnostics:
1. Load `features/observability.md` for tracing over log, structured fields, instrument spans, level filtering

### Performance Patterns (MEDIUM)
When optimizing runtime performance:
1. Load `features/performance.md` for iterators, entry API, drain/reuse, batch operations, profiling, IO buffering

### Ecosystem Integration (MEDIUM)
When choosing crates, managing dependencies, or integrating with other languages:
1. Load `features/ecosystem.md` for crate selection, feature flags, workspace layout, FFI, bindgen, PyO3

### Project Structure (LOW)
When organizing crate structure or workspace layout:
1. Load `features/project-structure.md` for module organization, visibility, workspaces, features, MSRV

### Clippy & Linting (LOW)
When configuring lints or CI checks:
1. Load `features/linting.md` for clippy configuration, rustfmt, CI integration, workspace lint setup

### Anti-patterns (REFERENCE)
When reviewing code for common mistakes:
1. Load `features/anti-patterns.md` for unwrap abuse, excessive cloning, stringly-typed APIs, over-abstraction, premature optimization

## Domain Skills

Domain-specific Rust patterns and constraints. Load these alongside feature files when working in a specific application domain:

| Domain | Load | When |
|--------|------|------|
| Web Services | `domain-web/SKILL.md` | Building HTTP APIs, REST services, web servers |
| FinTech | `domain-fintech/SKILL.md` | Financial applications, trading, payments |
| CLI Tools | `domain-cli/SKILL.md` | Command-line tools, terminal applications |

## Cross-Referencing

When a task spans multiple domains, load the primary domain feature first, then load additional features as needed. Features reference each other for cross-cutting topics.

### Common Task-to-Feature Mapping

| Task | Primary Features |
|------|-----------------|
| New function | `ownership`, `error-handling`, `naming`, `patterns` |
| New struct/API | `api-design`, `type-safety`, `conversions`, `documentation` |
| Async code | `async`, `ownership` |
| Concurrency / parallelism | `concurrency`, `async`, `ownership` |
| Unsafe code | `unsafe`, `type-safety`, `testing` |
| Error handling | `error-handling`, `domain-error`, `api-design`, `patterns` |
| Type conversions | `conversions`, `api-design` |
| Serialization (serde) | `serde`, `type-safety`, `api-design` |
| Numeric / arithmetic | `numeric`, `type-safety` |
| Macros / code generation | `macros`, `anti-patterns` |
| Closures / callbacks | `closures`, `type-safety` |
| Logging / observability | `observability`, `error-handling` |
| Memory optimization | `memory`, `ownership`, `performance` |
| Performance tuning | `optimization`, `memory`, `performance`, `zero-cost` |
| Code review | `anti-patterns`, `linting` |
| Domain modeling (DDD) | `domain-modeling`, `type-safety`, `api-design` |
| Resource cleanup | `lifecycle`, `ownership` |
| RAII / Drop | `lifecycle`, `ownership` |
| Error recovery / retry | `domain-error`, `error-handling` |
| Static vs dynamic dispatch | `zero-cost`, `traits`, `closures` |
| Type-state / invariants | `type-driven`, `type-safety` |
| Crate / dependency choice | `ecosystem`, `project-structure` |
| Web development | `domain-web/SKILL.md`, `async`, `concurrency` |
| FinTech / financial | `domain-fintech/SKILL.md`, `numeric`, `type-safety` |
| CLI development | `domain-cli/SKILL.md`, `error-handling`, `project-structure` |

## Sources & Attribution

This skill synthesizes official Rust guidance, well-known books, and patterns from widely-used crates. It is not affiliated with or endorsed by the Rust project or any crate author.

**Official documentation**: The Rust Reference, Rust API Guidelines, The Rustonomicon, Rust 2024 Edition Guide, The Cargo Book

**Books & guides**: The Rust Performance Book (Nethercote), Rust Design Patterns (rust-unofficial), Rust Atomics and Locks (Bos), Effective Rust (Drysdale)

**Real-world codebases**: ripgrep, tokio, serde, clap, polars, axum, cargo, hyper, bevy, rayon, dtolnay's crates

**Enriched from**: actionbook/rust-skills (domain patterns, layer architecture, error categorization, type-driven design, lifecycle management)
