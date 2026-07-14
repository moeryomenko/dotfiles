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

### External Diff Safety
- Always pass `--no-ext-diff` with every `git diff`, `git log -p`, and `git show` command.
- External diff tools (meld, beyond compare, etc.) are designed for interactive use. In non-interactive agent environments they can hang, fail silently, or produce unparseable output.
- `git diff --quiet` is especially vulnerable: even though no output is displayed, git may still attempt to invoke an external diff tool, causing hangs or failures in CI/agent environments.
- Correct patterns:
  ```bash
  git diff --no-ext-diff
  git diff --no-ext-diff --cached
  git diff --no-ext-diff --staged --quiet
  git log -p --no-ext-diff
  git show --no-ext-diff
  ```
- Use `--no-ext-diff` even when you think no external diff is configured. It's a cheap safety flag that eliminates an entire class of environment-specific failures.

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

# Step 4: Commit with scoped commit message
git commit -m "auth: add login endpoint"
```

---

## Commit Message Convention

Use scoped commits (no type prefixes — the scope IS the classifier):
```
<scope>: <description>

Rules:
- No type prefixes (no feat:, fix:, chore:, etc.)
- Scope is the subsystem or module the change touches
- Imperative mood: "add pagination" not "added pagination"
- No leading capital after scope colon
- No trailing period
- ~50 chars preferred, max 72
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
> [Check] Scoped commit message used
> [Check] git diff/log/show commands use --no-ext-diff
