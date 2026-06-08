---
name: memory-system
description: Persistent cross-session memory management. Enables agents to remember user preferences, project conventions, and past decisions across different sessions using a structured MEMORY.md index and topic files.
when_to_use: "When the user says 'remember this', 'save this for later', 'don't forget', or when starting a new session and needing to recall past context. Also when /remember workflow is invoked."
allowed-tools: Read, Write, Grep, Glob
effort: low
---

# Memory System — Persistent Cross-Session Memory

> Enables agents to remember across sessions. Never re-discover what was already learned.

## Overview

The Memory System provides **persistent, searchable memory** that survives across sessions. Instead of re-explaining preferences, conventions, and past decisions every time, agents read a structured MEMORY.md index and topic files.

**Token Impact:** +1,000 tokens to load index, but saves 3,000-10,000 tokens by eliminating re-discovery.

---

## Architecture

```
.opencode/memory/
├── MEMORY.md              <- Lightweight index (max 200 lines)
├── user-preferences.md    <- Topic file: user role, style, tools
├── project-conventions.md <- Topic file: coding standards, patterns
├── tech-decisions.md      <- Topic file: past architectural decisions
├── feedback-history.md    <- Topic file: what user liked/disliked
└── [topic-name].md        <- Additional topic files as needed
```

---

## MEMORY.md Index Format

The index is a **lightweight pointer file** — short entries that reference topic files for details.

**Rules:**
- Maximum **200 lines** total
- Each entry: **~150 characters max**
- Format: `- [type] summary -> topic-file.md`
- Types: `[user]` `[feedback]` `[project]` `[reference]`

**Example:**
```markdown
# Memory Index

## User
- [user] Prefers dark mode, uses Linux, bash -> user-preferences.md
- [user] Senior DevOps engineer, 8 years experience -> user-preferences.md
- [user] Primary language: English -> user-preferences.md

## Project
- [project] Always use bun instead of npm -> project-conventions.md
- [project] Tailwind v4 preferred, no v3 -> tech-decisions.md
- [project] No purple/violet colors in UI -> project-conventions.md

## Feedback
- [feedback] User likes concise responses, no filler -> feedback-history.md
```

---

## Session Start Protocol

When starting a new session:

1. Check if `.opencode/memory/MEMORY.md` exists
2. If yes: Read it to understand user/project context
3. If no: Ask user if they want to initialize memory
4. Load relevant topic files based on the current task

---

## Memory Update Protocol

When the user says something worth remembering:

1. Identify the type: user preference, project convention, technical decision, or feedback
2. Update or create the appropriate topic file
3. Update MEMORY.md index with a pointer entry (keep under 200 lines)
4. If MEMORY.md exceeds 200 lines, consolidate older entries

---

## Conflict Resolution

If the user contradicts a previous memory entry:
1. Note the contradiction
2. Ask the user which is correct
3. Update the entry with the resolution
4. Keep a brief history in the topic file

---

## Verification Markers

> [Check] MEMORY.md exists at .opencode/memory/MEMORY.md
> [Check] Index is under 200 lines
> [Check] Each entry is under 150 characters
> [Check] Topic files referenced in index actually exist
