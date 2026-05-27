# OpenCode Multi-Agent Workflow

## Architecture

```
User Request
    ↓
┌───────────────────────────────┐
│  🔍 architector (primary)      │  Spec Architect & Iterative Refiner
│  - Iterates with user on spec  │  Temperature: 0.1
│  - Uses @explorer for unknowns │
│  - Loads create-specification  │
│  - Produces finalized .spec.md │
└───────────────────────────────┘
               ↓ approved spec
┌───────────────────────────────┐
│  📋 plan (primary)             │  Implementation Planner
│  - Decomposes spec into tasks  │  Temperature: 0.2
│  - Assigns skills per task     │
│  - Produces implementation_    │
│    plan.md with task IDs       │
└───────────────────────────────┘
               ↓ implementation_plan.md
┌───────────────────────────────┐
│  👷 build (primary)            │  Staff+ Engineer & Execution Orch.
│  - Delegates with skill list   │  Temperature: 0.3
│  - Enforces quality gates      │
└───────────────────────────────┘
       ↓         ↓           ↓
┌──────────┐ ┌───────┐ ┌──────────┐
│ @engineer│ │@reviewer│ │ @qa     │
│ implement│ │audit  │ │verify   │
│ + skills │ │+ skills│ │+ skills │
└──────────┘ └───────┘ └──────────┘
       ↓
┌─────────────┐
│ @reflector  │
│ feedback    │
└─────────────┘
```

### Skill Loading (Cross-Cutting Phase)

Every agent loads domain-relevant skills BEFORE performing any task. This is a mandatory cross-cutting phase:

- **Detection**: Agent identifies language, framework, and task type from context
- **Loading**: Uses `skill` tool to load 2-4 skills matching detected context
- **Isolation**: Skills are scoped to subagent invocation and auto-clear on exit
- **Reference**: See `prompts/skill_loading_preamble.md` and `prompts/skill_awareness.md`

```
┌─────────────────────────────────────────────────────────┐
│  Skill Loading Flow (Every Agent)                        │
│                                                          │
│  1. Detect context (language, task type, file patterns)  │
│  2. Load 2-4 relevant skills via `skill` tool            │
│  3. Execute task with loaded skill guidance               │
│  4. On exit: skill context auto-clears (subagent isolation)│
└─────────────────────────────────────────────────────────┘
```

## Agent Roles

| Agent | Mode | Role | Temperature | Key Artifact |
|-------|------|------|-------------|--------------|
| **@architector** | primary | Spec Architect & Iterative Refiner — produces finalized .spec.md with user | 0.1 | `.spec.md` (APPROVED) |
| **@plan** | primary | Implementation Planner — decomposes spec into task-ordered plan | 0.2 | `implementation_plan.md` |
| **@build** | primary | Staff+ Engineer — implements or delegates tasks, never plans | 0.3 | Working code + tests |
| @explorer | subagent | Senior Systems Researcher — eliminates unknowns | 0.2 | `research_report.md` |
| @engineer | subagent | Production-grade Software Engineer — implementation specialist | 0.25 | Code changes |
| @reviewer | subagent | Spec Compliance Auditor — verifies against .spec.md contract | 0.1 | Review verdict |
| @qa | subagent | Spec Verifier — tests against Verification Contract | 0.2 | Test results |
| @reflector | subagent | Systems Architect & Meta-Analysis — feedback loop | 0.15 | Optimization proposals |

## Planning vs. Implementing Boundary

| Activity | Responsible Agent | NOT This Agent |
|----------|-------------------|----------------|
| "What should we build and why?" | @architector | @plan, @build |
| "In what order and as which tasks?" | @plan | @architector, @build |
| "Do the work or delegate it" | @build | @plan, @architector |

## Execution Pipeline

### Phase A: Spec Refinement (architector)

1. Analyze user request for completeness
2. Use `@explorer` to resolve unknowns in the codebase
3. Produce a draft `.spec.md` using `specs/templates/spec_template.md`
4. Present draft to user — iterate via `question` tool on ambiguous points
5. Incorporate feedback → revise → re-present (typically 1-2 iterations)
6. Set status to `APPROVED` and signal ready for `@plan`

### Phase B: Task Planning (plan)

1. Read the approved `.spec.md` from `architector`
2. Perform scope analysis (affected files, dependencies, unknowns)
3. Break spec into atomic tasks with:
   - Unique IDs (TASK-001, TASK-002, etc.)
   - Clear acceptance criteria
   - Assigned agent (@engineer or @build self)
   - Required Skills (2-4 skills from skill_awareness.md)
   - Explicit dependency declarations
4. Order tasks by dependency chain
5. Produce `implementation_plan.md`

### Phase C: Execution & Orchestration (build)

1. Read `implementation_plan.md` from `plan`
2. Validate plan is well-formed (tasks have IDs, dependencies, criteria)
3. Execute tasks in dependency order — do NOT reorder without justification
4. For each task:
   - If assigned to @engineer → delegate with exact spec references
   - If assigned to self → implement directly with minimal changes
5. After ALL implementation: route to `@reviewer` for compliance audit
6. If REJECTED → fix and re-submit (max 2 cycles)
7. If APPROVED → route to `@qa` for verification
8. After @qa: invoke `@reflector` for post-mortem, then signal completion

### Phase C-Fallback: Direct Execution (skip plan)

For simple tasks where the user invokes `@build` directly without `@plan`:
1. Perform minimal task decomposition as last resort
2. Note this deviation in output
3. Proceed with execution as normal

## Handoff Rules

| Agent | Must Do | Must NOT Do |
|-------|---------|-------------|
| **@architector** | Write .spec.md, iterate with user via `question`, use @explorer for research, load create-specification skill | Execute tasks, implement code, plan task decomposition |
| **@plan** | Decompose spec into atomic tasks, assign Required Skills, produce implementation_plan.md | Write specs, implement code, modify production files |
| **@build** | Implement tasks directly OR delegate to @engineer with skill list; orchestrate @reviewer/@qa gates | Plan or decompose tasks (this is @plan's job); skip quality gates |
| @explorer | Research unknowns, provide evidence-based findings, load domain skills | Modify any files (except research_report.md) |
| @engineer | Load skills before work, implement tasks per spec, self-verify | Add features not in the spec |
| @reviewer | Load skills before audit, audit spec compliance, verify signatures/types via LSP | Implement fixes for found issues |
| @qa | Load skills before testing, test against Verification Contract | Modify production code |
| @reflector | Analyze failures, suggest improvements | Directly modify code or specs |

## Artifact Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│  User Request                                           │
│       ↓                                                 │
│  ┌─────────────────┐                                   │
│  │ DRAFT .spec.md  │ ← architector writes initial draft │
│  └────────┬────────┘                                   │
│           ↓ iterative refinement                        │
│  ┌─────────────────┐                                   │
│  │ APPROVED        │ ← user approves, status set to     │
│  │ .spec.md        │   APPROVED                         │
│  └────────┬────────┘                                   │
│           ↓                                             │
│  ┌─────────────────────────────┐                       │
│  │ implementation_plan.md      │ ← plan decomposes spec │
│  │ (TASK-001..N, ordered)      │   into tasks           │
│  └────────┬────────────────────┘                       │
│           ↓                                             │
│  ┌─────────────────────────────┐                       │
│  │ Working code + tests        │ ← build executes       │
│  │                          ← reviewer approves         │
│  │                          ← qa verifies               │
│  └────────┬────────────────────┘                       │
│           ↓                                             │
│  ┌─────────────────────────────┐                       │
│  │ reflector.md                │ ← post-mortem analysis │
│  └─────────────────────────────┘                       │
└─────────────────────────────────────────────────────────┘
```

### Artifact Ownership

| Artifact | Created By | Consumed By | Format |
|----------|-----------|-------------|--------|
| `.spec.md` | @architector | @plan, @build (reference) | Markdown (template) |
| `implementation_plan.md` | @plan | @build | Markdown (structured task list) |
| `research_report.md` | @explorer | @architector, @plan | Markdown |
| Review verdict | @reviewer | @build (quality gate) | Structured report |
| Verification report | @qa | @build (quality gate) | Structured report |
| `reflector.md` | @reflector | User, config (prompt evolution) | Markdown |

## User Interaction Patterns

### Pattern 1: Full Pipeline (All Three Primaries) — Recommended for Complex Work
```bash
# Step 1: Iterative spec refinement
@architector Implement user authentication with JWT tokens

# → architector iterates with user, produces .spec.md
# → User approves spec

# Step 2: Task decomposition planning
@plan Decompose the approved spec at specs/SPEC-001.md

# → plan produces implementation_plan.md

# Step 3: Implementation & execution
@build Execute the implementation plan at implementation_plan.md

# → build implements/delegates tasks, orchestrates quality gates
```

### Pattern 2: Direct Execution (Skip Planning) — For Simple Tasks
```bash
@build Execute the spec at specs/SPEC-001.md

# → build does minimal decomposition itself as last resort
# → Implements or delegates to subagents directly
```

### Pattern 3: Spec Only — For Design Review
```bash
@architector Analyze the current database migration system and produce a spec for adding soft deletes

# → architector produces .spec.md, user reviews
# → User may stop here or continue with @plan + @build
```

## Iteration Control

- **Max refinement cycles**: 3 (build → reviewer → build loop)
- **Stop when**: `@reviewer` = APPROVED AND `@qa` = PASSED
- **Anti-loop guard**: `subtask_timeout: 300s` per subtask (see `subtask2.jsonc`)

## Delegation Protocol

When delegating tasks, use this structured format:

```
@engineer implement task: [task-id from plan]
Context: [spec section reference]
Files to modify: [list of files]
Skills to load: [from Required Skills field in plan]
Requirements: [specific, actionable instructions]
Acceptance criteria: [checklist]
Constraints: [what NOT to do, performance requirements, etc.]
```

> **Skill Isolation**: Skills loaded for a task are scoped to the subagent invocation and auto-clear on exit. This prevents cross-task skill interference.

When calling `@reviewer`:
```
@reviewer audit implementation for task: [task-id from plan]
Spec reference: [path to .spec.md and section]
Diff/changes: [description of what was implemented]
```

## Quality Standards (Enforced by Build Agent)

### Code Quality
- Interfaces first — define contracts before implementations
- Error handling — no swallowed errors; use `%w` wrapping for error chains
- Context propagation — all blocking operations accept `context.Context`
- Minimal diffs — small, reviewable changes > large refactors
- Read before write — always understand existing patterns before modifying

### Cross-Cutting Concerns
- Testability — every new function must have a clear path to testing
- Logging — structured logs at key decision points
- Observability — metrics for hot paths and error rates
- Security — input validation, auth checks, no secret leakage
- Documentation — exported symbols must have godoc comments

### Skill Ecology (Mandatory)
- All agents MUST load skills before working (see `prompts/skill_loading_preamble.md`)
- Skills must be ecological: no trigger words ("MUST", "CRITICAL"), specific descriptions, exit conditions
- Skill ecology compliance is a review criterion (see `prompts/skill_ecology_checklist.md`)
- Subagent isolation prevents cross-task skill interference
