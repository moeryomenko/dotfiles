# OpenCode Multi-Agent Workflow

## Architecture

```
User Request
    ↓
┌───────────────────────────────┐
│  🧭 plan (primary)             │  Spec Architect
│  - Writes .spec.md contract    │  Temperature: 0.1
│  - Uses @explorer for unknowns │
│  - NEVER writes code           │
└───────────────────────────────┘
              ↓ approved spec
┌───────────────────────────────┐
│  👷 build (primary)            │  Staff+ Engineer & Orchestrator
│  - Decomposes spec into tasks  │  Temperature: 0.3
│  - Delegates to subagents      │
│  - Owns quality gates          │
│  - Reviews subagent output     │
└───────────────────────────────┘
       ↓         ↓           ↓
┌──────────┐ ┌───────┐ ┌──────────┐
│ @explorer│ │@engineer│ │@reviewer │
│ research │ │implement│ │compliance│
└──────────┘ └───────┘ └──────────┘
       ↓
┌─────────────┐
│    @qa      │
│  verification│
└─────────────┘
       ↓
┌─────────────┐
│  @reflector │
│  feedback   │
└─────────────┘
```

## Agent Roles

| Agent | Mode | Role | Temperature |
|-------|------|------|-------------|
| plan | primary | Spec Architect — writes .spec.md contracts | 0.1 |
| build | primary | Staff+ Engineer & Execution Orchestrator | 0.3 |
| explorer | subagent | Senior Systems Researcher — eliminates unknowns | 0.2 |
| engineer | subagent | Production-grade Software Engineer — implementation | 0.25 |
| reviewer | subagent | Spec Compliance Auditor — verifies against .spec.md | 0.1 |
| qa | subagent | Spec Verifier — tests against Verification Contract | 0.2 |
| reflector | subagent | Systems Architect & Meta-Analysis — feedback loop | 0.15 |

## Execution Pipeline

### Phase 1: Spec Ingestion (plan)
1. Analyze user request
2. Use `@explorer` to resolve unknowns in the codebase
3. Write `.spec.md` following `specs/templates/spec_template.md`
4. Define Verification Contract (acceptance criteria)
5. Submit spec for approval

### Phase 2: Task Decomposition (build)
1. Read approved `.spec.md`
2. Perform scope analysis (affected files, dependencies, unknowns)
3. Break spec into atomic tasks with acceptance criteria
4. Assign each task to `@engineer` or keep for self-execution

### Phase 3: Execution & Delegation (build → subagents)
1. For each task assigned to `@engineer`:
   - Provide exact spec section reference
   - Specify file paths, function signatures, constraints
   - Wait for completion before proceeding
2. For tasks build handles itself:
   - Read existing code in affected area
   - Implement with minimal, precise changes
   - Self-review before passing to `@reviewer`

### Phase 4: Quality Gates (build → reviewer → qa)
1. Send implementation to `@reviewer` for spec compliance audit
2. If `@reviewer` REJECTS → fix issues and re-submit (max 2 re-submissions)
3. If `@reviewer` APPROVES → send to `@qa`

### Phase 5: Verification (build → qa → reflector)
1. Review `@qa` test results
2. If tests FAIL → analyze root cause, fix in `@engineer`, re-run from Phase 4
3. If tests PASS → mark implementation complete
4. `@reflector` analyzes the full execution for systemic improvements

### Phase 6: Closure (build)
1. Summarize all changes made
2. Map each change back to spec requirements
3. Note any deviations or technical debt introduced
4. Signal completion to user

## Handoff Rules

| Agent | Must Do | Must NOT Do |
|-------|---------|-------------|
| plan | Write .spec.md, use @explorer for research | Write implementation code |
| build | Decompose tasks, delegate, review subagent output | Skip @reviewer gate before @qa |
| explorer | Research unknowns, provide evidence-based findings | Modify any files |
| engineer | Implement tasks per spec, self-verify | Add features not in the spec |
| reviewer | Audit spec compliance, verify signatures/types | Implement fixes for found issues |
| qa | Test against Verification Contract | Modify production code |
| reflector | Analyze failures, suggest improvements | Directly modify code or specs |

## Iteration Control

- **Max refinement cycles**: 3 (build → reviewer → build loop)
- **Stop when**: `@reviewer` = APPROVED AND `@qa` = PASSED
- **Anti-loop guard**: `subtask_timeout: 300s` per subtask (see `subtask2.jsonc`)

## Delegation Protocol

When delegating tasks, use this structured format:

```
@engineer implement task: [task-id]
Context: [spec section reference]
Files to modify: [list of files]
Requirements: [specific, actionable instructions]
Acceptance criteria: [checklist]
Constraints: [what NOT to do, performance requirements, etc.]
```

When calling `@reviewer`:
```
@reviewer audit implementation for task: [task-id]
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
