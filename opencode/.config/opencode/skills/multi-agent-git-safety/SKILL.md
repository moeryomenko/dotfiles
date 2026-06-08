---
name: multi-agent-git-safety
description: Git safety rules for multi-agent environments. Prevents cross-agent contamination by enforcing explicit path staging, banning destructive operations, and requiring pre-commit verification.
when_to_use: "Before any git operation in a multi-agent environment. When committing, staging, rebasing, or pushing. NOT for single-agent solo development without concurrent agents."
allowed-tools: Bash, Read, Grep
effort: low
---

# Multi-Agent Git Safety

> Multiple agents in one repo require strict git discipline. One wrong command destroys another agent's work.

## Overview

When multiple agents work in the same repository simultaneously, standard git operations become dangerous. This skill enforces the hard rules needed for safe concurrent agent operation.

---

## Hard Rules

### Committing
- Only commit files YOU changed in THIS session.
- Stage explicit paths (`git add <path1> <path2>`); never `git add -A` or `git add .`.
- Before committing, run `git status` and verify you are only staging your files.

### Never Run (destroys other agents' work or bypasses checks)
- `git reset --hard`
- `git checkout .`
- `git clean -fd`
- `git stash`
- `git add -A`
- `git add .`
- `git commit --no-verify`

### Rebase Conflicts
- Resolve conflicts only in files you modified.
- If a conflict is in a file you did not modify, abort and ask the user.
- Never force push.

---

## Pre-Commit Verification Protocol

Before every commit:

```bash
# Step 1: Check status
git status

# Step 2: Verify ONLY your files are staged
# If you see files you didn't change, STOP and investigate

# Step 3: Stage explicit paths (NEVER use -A or .)
git add src/my-file.go src/my-test.go

# Step 4: Commit with conventional commit message
git commit -m "feat: add my feature"
```

---

## Commit Message Convention

Use conventional commits:
```
<type>: <description>

Types:
- feat: New feature
- fix: Bug fix
- refactor: Code change without feature/fix
- docs: Documentation changes
- test: Test changes
- chore: Maintenance, deps, config
```

---

## Recovery Protocol

If you accidentally run a destructive command:

```bash
# If you ran git add -A:
git restore --staged :/
# Then restage only your files

# If you see a lock file issue:
scripts/committer --force "msg" file1 file2
```

---

## Verification Markers

> [Check] git status run before commit
> [Check] Only my files staged (no git add -A)
> [Check] No destructive commands in session history
> [Check] Conventional commit message used
