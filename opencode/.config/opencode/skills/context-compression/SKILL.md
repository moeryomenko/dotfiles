---
name: context-compression
description: Manage and compress conversation context in long sessions. Detect when context is growing large, summarize completed work phases, archive old findings while preserving key decisions. Prevents context degradation.
when_to_use: "When a session has 20+ turns, when context feels repetitive, when the agent is losing track of earlier work, or when the user says 'summarize what we've done'. NOT for short sessions."
allowed-tools: Read, Write, Grep
effort: low
---

# Context Compression — Long Session Management

> Keep sessions productive by compressing completed work while preserving key decisions.

## Overview

Long sessions (30+ turns) cause context degradation — the AI loses track of earlier work, repeats itself, or forgets decisions. Context compression proactively summarizes completed phases so the context window stays focused on active work.

**Token Impact:** Recovers 5,000-15,000 tokens in long sessions by replacing verbose tool outputs with semantic summaries.

---

## When to Compress

| Signal | Action |
|---|---|
| Session has 20+ turns | Consider proactive compression |
| Agent repeats earlier suggestions | Context is saturated — compress now |
| User says "we already discussed this" | Compress immediately |
| Switching to a new phase of work | Compress the completed phase |
| Large tool output (500+ lines) | Micro-compact the output |

---

## Compression Levels

### Level 1: Micro-Compact (Tool Output)

Compress individual tool outputs while retaining semantic content:

```
Raw grep output (200 lines, ~4,000 tokens):
src/auth/jwt.ts:15: import { verify } from 'jsonwebtoken'
src/auth/jwt.ts:23: export function validateToken(token: string) {
... (195 more lines)

Micro-compact (5 lines, ~100 tokens):
Grep results for "jwt": Found 8 files, 42 matches.
Key files: src/auth/jwt.ts (main JWT logic), src/middleware/auth.ts (middleware),
src/api/login.ts (token creation). Token validation at jwt.ts:23-40.
Error handling at jwt.ts:42-55. Secret loaded from env at jwt.ts:8.
```

### Level 2: Phase Summary

Replace a completed work phase with a summary:

```
Full research transcript (~3,000 tokens):
[turn 1] Read package.json...
[turn 2] Grep for auth patterns...
[turn 3] Read middleware...
...

Phase summary (~200 tokens):
Research phase complete: Found JWT auth pattern in src/auth/jwt.ts.
Token validation uses jsonwebtoken library. Middleware checks auth at
src/middleware/auth.ts lines 12-30. Key decision: Use access + refresh
token pattern. Research artifacts saved to .agent/tasks/TASK-001/research/
```

### Level 3: Session Archive

When context is critically full, archive the entire completed portion:

- Save full session transcript to `.opencode/sessions/archive-YYYYMMDD-HHMMSS.md`
- Keep only: active task state, key decisions, next steps
- Clear completed task details from context

---

## What to Preserve (Never Compress Away)

- User preferences and constraints
- Architectural decisions (especially trade-offs explained by the user)
- Security requirements
- API keys, credentials, or sensitive data (if present, preserve securely)
- Commit messages and change rationale
- Current task state and next steps

---

## Compression Protocol

```
1. DETECT: Context growing large (20+ turns, repetitive suggestions)
2. ASSESS: What phase just completed? What comes next?
3. COMPRESS: Apply appropriate level (1, 2, or 3)
4. VERIFY: Key decisions still accessible after compression
5. PROCEED: Continue with active work
```

---

## Verification Markers

> [Check] Context saturation detected appropriately
> [Check] Key decisions preserved after compression
> [Check] Compression level matches phase completion
> [Check] Active task state unchanged after compression
