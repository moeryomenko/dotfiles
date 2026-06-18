# OpenCode Multi-Agent Workflow

## Architecture

```
User Request
    |
+-------------------------------+
|  architector (primary)         |  Spec Architect & Iterative Refiner
|  - Iterates with user on spec  |  Temperature: 0.1
|  - Uses @explorer for unknowns |  Skills: dynamically discovered
|  - Produces .specs/<name>.spec.md  |
+-------------------------------+
               | approved spec (.specs/)
+-------------------------------+
|  plan (primary)                |  Implementation Planner
|  - Decomposes spec into tasks  |  Temperature: 0.2
|  - Assigns skills per task     |  Skills: dynamically discovered
|  - Produces .plans/<feature>/plan.md  |
+-------------------------------+
               | .plans/<feature>/plan.md
+-------------------------------+
|  build (primary)               |  Execution Orchestrator (TDD)
|  - Delegates with skill list   |  Temperature: 0.3
|  - TDD: tests first, then impl |  Skills: dynamically discovered
|  - Enforces quality gates      |
|  - Coordinator lifecycle       |
+-------------------------------+
   |         |          |          |          |
   v         v          v          |          v
+---------+ +--------+ +------+   |     +----------+
| explorer| |engineer| |review|   |     |   qa     |
|research | |implement| |audit |   |     | test     |
|read-only| |+skills | |+skills|   |     | design   |
|dyn disc | |dyn disc| |dyn disc|   |     | (grill-me)|
+---------+ +--------+ +------+   |     +----------+
   |         |          |          |         | (test-first, then)
   |         |          |          |         v
   |         |          |          |     +---------+
   |         |          |          |     |   qa    |
   |         |          |          |     | verify  |
   |         |          |          |     |+skills  |
   |         |          |          |     +---------+
   |         |          |          |         | (fail)
   |         |          |          |         v
   |         |          |          |     +----------+
   |         |          |          |     |  fixer   |
   |         |          |          |     |  repair  |
   |         |          |          |     +----------+
   |         |          |          |         | (fix complete)
   |         |          |          |         v
   |         |          |          |     (re-verify)
   |
   v
+----------+     +------------+
| commiter |     | reflector  |
| commit   |     | feedback   |
|+skills   |     |+skills     |
|dyn disc  |     |dyn disc    |
+----------+     +------------+
```

## Agent Roles

| Agent | Mode | Role | Temp |
|-------|------|------|------|
| **@architector** | primary | Spec Architect & Iterative Refiner | 0.1 |
| **@plan** | primary | Implementation Planner | 0.2 |
| **@build** | primary | Execution Orchestrator | 0.3 |
| @explorer | subagent | Senior Systems Researcher | 0.2 |
| @engineer | subagent | Implementation specialist | 0.25 |
| @reviewer | subagent | Spec Compliance Auditor | 0.1 |
| @qa | subagent | Test Designer (grill-me) & Spec Verifier (TDD) | 0.2 |
| @fixer | subagent | Targeted Repair Agent | 0.2 |
| @reflector | subagent | Systems Architect & Meta-Analysis | 0.15 |
| @commiter | subagent | Conventional Commits Specialist | 0.1 |

## Skill Loading (Cross-Cutting Phase)

Every agent loads domain-relevant skills BEFORE performing any task. Skills are **dynamically discovered** — no static mapping exists:

- **Detection**: Agent scans its system prompt's `<available_skills>` list and selects 2-4 skills matching the task's language, domain, and type
- **Loading**: Uses `skill` tool to load selected skills by exact name
- **Isolation**: Skills are scoped to subagent invocation and auto-clear on exit
- **Resolution Chain**: Custom rules loaded via `resolve-rules.sh` (project -> user -> default)
- **Reference**: See `prompts/skill_loading_preamble.md`

```
+-----------------------------------------------------------+
|  Skill Loading Flow (Every Agent)                          |
|                                                            |
|  1. Scan <available_skills> from system prompt             |
|  2. Select 2-4 skills matching task context                |
|  3. Load selected skills via `skill` tool                  |
|  4. Check custom rules via resolve-rules.sh (if applicable)|
|  5. Execute task with loaded skill guidance                |
|  6. On exit: skill context auto-clears (subagent isolation)|
+-----------------------------------------------------------+
```

## Execution Pipeline

### Phase A: Spec Refinement (architector)

1. Analyze user request for completeness
2. Use `@explorer` to resolve unknowns in the codebase
3. Load relevant skills from `<available_skills>` (e.g., spec-writing skills)
4. Write spec draft to `.specs/<feature-name>.spec.md` using template from `specs/templates/spec_template.md`
5. Present draft to user -- iterate via `question` tool on ambiguous points
6. Incorporate feedback -> revise -> re-present (typically 1-2 iterations)
7. Set status to `APPROVED` and signal ready for `@plan`

### Phase B: Task Planning (plan)

1. Read the approved `.spec.md` from `architector`
2. Load relevant skills from `<available_skills>` matching the planning domain
3. Load custom planning rules via `resolve-rules.sh planning-rules.md`
4. Perform scope analysis (affected files, dependencies, unknowns)
5. Break spec into atomic tasks with:
   - Unique IDs (TASK-001, TASK-002, etc.)
   - Clear acceptance criteria
   - Assigned agent (@engineer or @build self)
   - Required Skills (2-4 skills from `<available_skills>` matching task context)
   - Explicit dependency declarations
6. Order tasks by dependency chain
7. Produce `.plans/<feature-name>/plan.md` with task decomposition

### Phase C: Execution & Orchestration (build, TDD)

Uses coordinator lifecycle:

```
1. DECOMPOSE -- Break implementation plan into individual task delegations
2. CLASSIFY -- Each task: Research | Test Design | Implementation | Verification
3. DISPATCH -- Launch subagents (test design first, then implementation sequentially)
4. MONITOR -- Track subagent completion
5. SYNTHESIZE -- Combine results, check against spec
6. VERIFY -- Ensure quality gates passed before commit
```

#### Per-Task Execution (TDD)

Every task follows Test-Driven Development: test-first, then implement, then verify.

**Step 0 — QA Test Design:** Delegate to @qa with `design-tests` mode. @qa uses the `grill-me` skill to stress-test the spec and write comprehensive tests before any implementation exists. Tests MUST fail initially (red phase).

**Step 1 — Engineer:** Delegate to @engineer with the pre-written tests as primary acceptance criteria. Engineer makes ALL tests pass (green phase).

**Step 2 — Reviewer Gate:** @reviewer audits spec compliance
   - REJECTED -> @engineer revises (max 2 cycles)
   - After engineer revision, re-run tests (Step 1 tests must still pass)

**Step 3 — QA Gate:** @qa re-verifies using pre-written tests in fresh session
   - FAILED -> @fixer repairs -> re-verify (max 2 cycles)

**Step 4 — Commit:** @commiter commits with scoped message and git safety

#### Ambiguity Handling (Parallel)

During any phase, if @engineer, @reviewer, or @qa encounter spec ambiguity:
1. Report to **@build** (not directly to @reflector)
2. @build forwards to @reflector for collection and categorization
3. @reflector forwards to @architector for resolution
4. @build evaluates if affected tasks need re-planning via @plan

### Phase D: Post-Mortem (reflector)

After all tasks complete:
1. Invoke @reflector for post-implementation analysis
2. Analyze failure patterns, agent interactions, prompt effectiveness
3. Produce optimization proposals for the workflow

## Evidence-Based Completion Protocol

Every implemented task MUST produce evidence artifacts:

```
.agent/tasks/<TASK_ID>/
  tests-manifest.md -- (TDD) Test coverage documentation from grill-me (test-first phase)
  test-*.ext        -- (TDD) Pre-written test files (written before implementation)
  evidence.md       -- Human-readable proof (per-AC status)
  evidence.json     -- Machine-readable proof (schema-validated)
  verdict.json      -- QA verification result (PASS/FAIL per VC)
  problems.md       -- (on FAIL only) Reproduction steps
  raw/              -- Raw command outputs
```

### Rules
- **TDD rule**: Tests MUST be written and confirmed failing BEFORE any implementation code
- No task is complete unless every acceptance criterion is PASS
- Verifiers judge current code and current command results, not prior chat claims
- Every QA verification uses a FRESH subagent session (ID differs from engineer's)
- If QA fails, @fixer makes the smallest safe diff, refreshes evidence, re-verifies

## Multi-Agent Git Safety

All agents follow these git rules (see `AGENTS.md` Section 4):

### Committing
- Only commit files YOU changed in THIS session
- Stage explicit paths (`git add <path1> <path2>`); never `git add -A` or `git add .`
- Before committing, run `git status` and verify only your files are staged

### Never Run
- `git reset --hard`, `git checkout .`, `git clean -fd`, `git stash`
- `git add -A`, `git add .`
- `git commit --no-verify`

### Rebase Conflicts
- Resolve only in files you modified
- If conflict in a file you did not modify, abort and ask the user
- Never force push

## Resolution Chain

Configuration resolution uses a three-layer override chain:

```
1. <cwd>/.opencode/<file>              # Project-level override
2. ~/.config/opencode/<file>           # User-level override
3. <skill-root>/references/<file>      # Bundled default
```

First-found-wins, never merge. Empty files treated as absent.

## Artifact Lifecycle

```
+-----------------------------------------------------------+
|  User Request                                              |
|       |                                                    |
|  +----------------------------------+                     |
|  | .specs/<name>.spec.md (DRAFT)    | <- architector       |
|  |                                  |    writes initial    |
|  +---------------+------------------+    draft             |
|                  | iterative refinement                    |
|  +----------------------------------+                     |
|  | .specs/<name>.spec.md (APPROVED) | <- user approves     |
|  +---------------+------------------+                     |
|                  |                                         |
|  +----------------------------------+                     |
|  | .plans/<feature>/plan.md         | <- plan decomposes   |
|  | (TASK-001..N, ordered)           |    spec into tasks   |
|  +---------------+------------------+                     |
|                  |                                         |
|  +----------------------------------+  (TDD RED PHASE)     |
|  | .agent/tasks/<TASK_ID>/          | <- qa writes tests   |
|  |   tests-manifest.md              |    using grill-me    |
|  |   test-*.ext (test files)        |    BEFORE any code   |
|  +---------------+------------------+                     |
|                  |                                         |
|  +----------------------------------+  (TDD GREEN PHASE)   |
|  | .agent/tasks/<TASK_ID>/          | <- engineer          |
|  |   evidence.md + evidence.json    |    implements to     |
|  +---------------+------------------+    make tests pass   |
|                  |                                         |
|  +----------------------------------+                     |
|  | reviewer: APPROVED/REJECTED      | <- reviewer audits   |
|  +---------------+------------------+                     |
|                  |                                         |
|  +----------------------------------+  (TDD VERIFY PHASE)  |
|  | .agent/tasks/<TASK_ID>/          | <- qa verifies in    |
|  |   verdict.json                   |    fresh session     |
|  +---------------+------------------+    using test-first   |
|                  |                     tests               |
|                  | (if FAIL)                               |
|                  v                                         |
|  +----------------------------------+                     |
|  | @fixer repairs                   | <- minimal fix       |
|  +---------------+------------------+                     |
|                  | (re-verify)                             |
|                  v                                         |
|  +----------------------------------+                     |
|  | @commiter commits                | <- scoped commit    |
|  +---------------+------------------+                     |
|                  |                                         |
|  +----------------------------------+                     |
|  | reflector — post-mortem analysis | <- feedback loop     |
|  +----------------------------------+                     |
+-----------------------------------------------------------+
```

## Handoff Rules

| Agent | Must Do | Must NOT Do |
|-------|---------|-------------|
| **@architector** | Write .spec.md, iterate with user via `question`, use @explorer for research; load relevant skills from `<available_skills>` | Execute tasks, implement code, plan task decomposition |
| **@plan** | Decompose spec into atomic tasks, assign Required Skills, produce `.plans/<feature-name>/plan.md`; load relevant skills from `<available_skills>` | Write specs, implement code, modify production files |
| **@build** | Delegate test-first to @qa (grill-me), then delegate to @engineer with tests as criteria; orchestrate @reviewer/@qa/@fixer gates; load relevant skills from `<available_skills>` | Plan or decompose tasks; skip test-first phase; skip quality gates |
| @explorer | Research unknowns, provide evidence-based findings; load relevant skills from `<available_skills>` | Modify any files (except research_report.md) |
| @engineer | Load relevant skills from `<available_skills>` before work; implement tasks per spec, self-verify, produce evidence artifacts | Add features not in the spec; skip evidence packing |
| @reviewer | Load relevant skills from `<available_skills>` before audit; audit spec compliance, verify signatures/types via LSP, follow output contract format | Implement fixes for found issues |
| @qa | Load `grill-me` skill + testing skills for test-first design; write tests before implementation; verify against Verification Contract; use FRESH session; produce tests-manifest.md + verdict.json | Modify production code; reuse engineer's session; skip grill-me during test-first phase |
| @fixer | Load relevant skills from `<available_skills>` before fixing; make smallest safe fix, refresh evidence artifacts | Refactor or improve unrelated code; change scope |
| @reflector | Load relevant skills from `<available_skills>` for analysis; analyze failures, categorize spec ambiguities (received from @build), suggest improvements | Directly modify code or specs |
| @commiter | Load relevant skills from `<available_skills>` before committing; stage explicit paths, produce conventional commit messages | Stage with `git add -A`; commit --no-verify; modify production code |

## Delegation Protocol (TDD)

When delegating tasks, always follow TDD order: test-first → implement → verify.

### Phase 1: Test Design (to @qa)

```
@qa design-tests for task: [task-id from plan]
Spec reference: [path to .spec.md, Verification Contract section]
Skill to load: grill-me (mandatory — for spec stress-testing)
Mode: test-first (no implementation exists yet)
VCs to cover: [list of Verification Contract IDs]
Test output path: [where to write tests]
```

### Phase 2: Implementation (to @engineer)

```
@engineer implement task: [task-id from plan]
Context: [spec section reference]
Files to modify: [list of files]
Skills to load: [from Required Skills field in plan]
Tests to satisfy: [path to test files from Phase 1]
Requirements: [specific, actionable instructions]
Acceptance criteria: [checklist — MUST include "all pre-written tests pass"]
Constraints: [what NOT to do, performance requirements, etc.]
```

### Phase 3: Verification (to @qa)

```
@qa verify task: [task-id from plan]
Spec reference: [path to .spec.md, Verification Contract section]
Test files: [paths to tests from Phase 1]
Implementation summary: [what the engineer implemented]
```

> **Skill Isolation**: Skills loaded for a task are scoped to the subagent invocation and auto-clear on exit.

## Quality Standards (Enforced by Build Agent)

### TDD Discipline
- **Tests first**: No implementation code is written before tests exist and are confirmed failing (red phase)
- **grill-me required**: Test design MUST use the `grill-me` skill to stress-test the spec and uncover edge cases
- **Test failure proof**: The test-first phase MUST produce evidence that tests fail against no implementation
- **Tests as spec**: Pre-written tests are the primary acceptance criteria for implementation

### Code Quality
- Interfaces first -- define contracts before implementations
- Error handling -- no swallowed errors; use `%w` wrapping for error chains
- Context propagation -- all blocking operations accept `context.Context`
- Minimal diffs -- small, reviewable changes > large refactors
- Read before write -- always understand existing patterns before modifying

### Cross-Cutting Concerns
- Testability -- every new function must have a clear path to testing
- Logging -- structured logs at key decision points
- Observability -- metrics for hot paths and error rates
- Security -- input validation, auth checks, no secret leakage
- Documentation -- exported symbols must have godoc comments

### Evidence Requirements
- Every AC must have PASS/FAIL with supporting evidence
- QA must judge current code and current command results, not prior chat claims
- Every verify uses a fresh subagent session

## Commands

| Command | Purpose | File |
|---------|---------|------|
| `/plan` | Generate implementation plan from spec | `commands/plan.md` |
| `/review` | Quick or full code review | `commands/review.md` |
| `/verify` | Run verification gate (lint -> typecheck -> test -> evidence) | `commands/verify.md` |
| `/skillify` | Create skill from repetitive workflow | `commands/skillify.md` |
| `/revdiff` | Interactive diff review for plan annotation | `commands/revdiff.md` |

## Scripts

| Script | Purpose | File |
|--------|---------|------|
| `resolve-file.sh` | Three-layer config resolution | `scripts/resolve-file.sh` |
| `resolve-rules.sh` | Two-layer custom rules loading | `scripts/resolve-rules.sh` |
| `verify.sh` | CI pre-push gate | `scripts/verify.sh` |
| `committer` | Conventional commit helper | `scripts/committer` |
| `validate-skills` | SKILL.md frontmatter validator | `scripts/validate-skills` |

## Shared Hard Rules

See `AGENTS.md` for the complete shared rules that all agents must follow:
1. Communication style (concise, no emojis, technical prose)
2. Code quality (read before write, no `any`, no inline imports)
3. Skill protocol (load before work, 2-4 skills, auto-clear on exit)
4. Multi-agent git safety (explicit paths, no destructive commands)
5. Evidence-based completion (per-AC PASS, fresh verifier, spec discipline)
