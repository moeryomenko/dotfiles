---
name: complexity-optimizer
description: Analyze a software codebase for algorithmic complexity and performance hotspots, then propose or implement safe optimizations without breaking behavior. Use when asked to scan many files, find inefficient loops, nested iteration, repeated scans, costly rendering/recomputation, N+1 queries, avoidable O(n^2) or O(n) operations, or reduce complexity such as O(n^2) to O(n log n) / O(n), while preserving tests, APIs, outputs, and maintainability.
when_to_use: "When asked to analyze codebase complexity, find performance hotspots, optimize code, or audit for N+1 queries, nested loops, or O(n^2) patterns. NOT for writing new features or fixing bugs."
allowed-tools: Read, Bash, Grep, Glob, Write, Edit
effort: high
---

# Complexity Optimizer

## Core Rule

Optimize only when the current behavior is understood and can be preserved. Prefer a small, proven improvement with tests over a broad rewrite with unclear correctness.

## Default Behavior

When asked to analyze, scan, audit, review, or "give me a report" for a codebase, produce the full complexity report automatically. Do not require the user to specify report fields.

Default report contents:

- Scope analyzed and detected stack/test commands.
- Top findings ranked by likely impact.
- File and line for each finding.
- Current pattern and why it may be costly.
- Estimated current complexity.
- Recommended change.
- Estimated complexity after the change.
- Risk level.
- Tests, benchmarks, or manual checks needed.
- Clear statement that no files were modified, unless the user explicitly requested implementation.

Only edit files when the user asks to implement, fix, optimize, apply, change, refactor, or otherwise clearly requests code modification. If the user only asks for analysis or a report, do not modify files.

## Workflow

1. Establish the baseline:
   - Identify the language, framework, test command, build command, and performance-sensitive paths.
   - Inspect existing tests before touching code.

2. Rank opportunities:
   - Prioritize code on hot paths, large input paths, rendering loops, database/API loops, and shared utilities.
   - Separate algorithmic complexity from constant-factor cleanup.
   - For report-only requests, inspect enough surrounding code to estimate current and proposed complexity.

3. Prove behavior:
   - Locate or add focused tests for the function/component being changed.
   - Capture edge cases: empty input, duplicates, ordering stability, null/missing values, errors, permissions, pagination, time zones, and mutation side effects.
   - If tests are absent and behavior is ambiguous, make the smallest refactor or ask for expected behavior before changing semantics.

4. Optimize conservatively:
   - Replace repeated linear lookup with maps/sets when key equality is stable.
   - Replace nested scans with indexing, grouping, two-pointer scans, sweep-line logic, binary search, memoization, batching, or precomputation only when the data shape supports it.
   - In UI code, reduce unnecessary renders with stable props, memoized derived data, virtualization, debounced work, and moving expensive work out of render paths.
   - In data access code, remove N+1 behavior with bulk fetches, joins, preloading, caching, or batching while preserving authorization and filtering.

5. Verify:
   - Run relevant tests and type/lint/build commands.
   - Add a micro-benchmark or measurement when the complexity improvement is non-obvious or performance-critical.
   - Report the original complexity, new complexity, changed files, tests run, and any residual risk.

## Manual Analysis Approach

Without an automated scanner, perform manual inspection for these patterns:

| Pattern | What to Look For | Typical Complexity |
|---------|-----------------|-------------------|
| Nested loops | Loop inside loop iterating over related data | O(n*m) or O(n^2) |
| Repeated linear search | `.find()`, `.filter()`, `.indexOf()` inside a loop | O(n^2) |
| N+1 queries | DB/API call inside a loop | O(n) queries |
| Large array copies | Spread/`concat`/`slice` in loops | O(n^2) memory |
| Repeated re-renders | Unmemoized computations in render paths | O(n) per render |
| Unbounded list rendering | Rendering all items without virtualization | O(n) DOM nodes |

## Optimization Safety Checklist

Before editing:

- [ ] Confirm the data sizes are large enough for complexity to matter.
- [ ] Confirm the optimization preserves output ordering where callers may rely on it.
- [ ] Confirm object identity, mutability, and reference sharing are not part of the public behavior.
- [ ] Confirm caches have a valid invalidation strategy.
- [ ] Confirm deduplication does not collapse distinct records that share a display label.
- [ ] Confirm database batching preserves tenant, permission, soft-delete, pagination, and sorting constraints.

After editing:

- [ ] Run the narrow test first, then the broadest relevant test/build command.
- [ ] Compare before/after benchmark numbers when a benchmark exists or was added.
- [ ] Keep the patch localized. Avoid formatting churn in unrelated files.
