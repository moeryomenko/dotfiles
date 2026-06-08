---
name: coordinator-mode
description: Advanced multi-agent orchestration with parallel workers, synthesis protocols, and coordinator lifecycle. Use when complex tasks require multiple agents working in parallel with intelligent result synthesis.
when_to_use: "When the user needs multi-agent coordination, parallel task execution, complex multi-domain work, or when /coordinate or /orchestrate is invoked. NOT for single-domain tasks."
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Task
effort: high
---

# Coordinator Mode — Multi-Agent Orchestration

> Distilled from production-proven coordinator patterns. Transforms sequential agent chains into intelligent parallel orchestration.

## Overview

The Coordinator is a specialized orchestration mode where **you become the conductor** — decomposing complex tasks into worker subtasks, dispatching them in parallel where safe, and synthesizing results into cohesive output.

**You are NOT a worker. You are the coordinator.** Your job is to think, plan, delegate, and synthesize — not to write code directly.

---

## Coordinator Lifecycle

```
User Request
    ↓
1. DECOMPOSE — Break task into worker subtasks
    ↓
2. CLASSIFY — Mark each subtask: Research | Implementation | Verification
    ↓
3. DISPATCH — Launch workers (parallel for reads, sequential for writes)
    ↓
4. MONITOR — Track worker completion notifications
    ↓
5. SYNTHESIZE — Combine results into unified response
    ↓
6. VERIFY — Ensure completeness before reporting to user
```

---

## Phase-Based Workflow

| Phase | Purpose | Concurrency | Worker Type |
|-------|---------|-------------|-------------|
| **Research** | Gather information, explore codebase | Fully parallel | Read-only agents |
| **Synthesis** | Analyze findings, plan approach | Coordinator only | No workers |
| **Implementation** | Make changes to code/files | Sequential per file set | Write-capable agents |
| **Verification** | Test, lint, validate changes | Parallel (independent) | Test/security agents |

> **Rule:** NEVER skip the Synthesis phase. Research -> direct Implementation = poor results.

---

## Concurrency Rules

### Safe to Parallelize
- Multiple agents reading different files
- Security audit + performance audit (read-only)
- Test runner + linter (independent)
- Exploring different directories

### Must Be Sequential
- Two agents writing to the same file
- Implementation that depends on another agent's output
- Database migration + code that uses the new schema
- API change + frontend that consumes the API

---

## Worker Prompt Writing Guide

### The Golden Rule: Never Delegate Understanding

```
WRONG: "Based on your findings, fix the bug"
WRONG: "Based on the research, implement it"
WRONG: "Look at the code and do what's needed"

RIGHT: "The bug is in src/auth/jwt.ts line 45 — the token expiry
        check uses `<` instead of `<=`, causing off-by-one failures
        for tokens expiring exactly at the boundary. Change line 45
        to use `<=` and add a test for the boundary case."
```

### Worker Prompt Template

```
Task: [one-line task name]
Scope: [which files, which concerns]
Context: [what the worker needs to know]
Output: [what the worker must produce]
Constraints: [time, style, quality bars]
Dependencies: [what inputs the worker needs]
```

---

## Synthesis Protocol

After all workers complete:

1. **Collect** all worker outputs
2. **Identify conflicts** between worker results
3. **Resolve conflicts** by applying coordinator judgment
4. **Unify** into a single coherent response
5. **Verify** completeness against the original task

---

## Verification Markers

> Each phase transition must include a verification step:

- After Research: `[Check] All research questions answered?`
- After Synthesis: `[Check] Plan covers all requirements?`
- After Implementation: `[Check] All acceptance criteria met?`
- After Verification: `[Check] No regressions introduced?`
