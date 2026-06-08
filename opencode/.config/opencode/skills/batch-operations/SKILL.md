---
name: batch-operations
description: Apply operations across multiple files simultaneously. Pattern-based bulk modifications, search-and-replace across codebases, consistent changes to many files at once.
when_to_use: "When the user needs to change multiple files with the same pattern, rename across a codebase, add imports to many files, update versions, or apply consistent modifications. NOT for single-file edits."
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
effort: medium
---

# Batch Operations — Multi-File Changes

> Apply consistent changes across many files at once. One pattern, many targets.

## When to Use

**Good for:**
- Renaming a function/component across all files that use it
- Adding an import to every file in a directory
- Updating version numbers across package files
- Applying the same code pattern to multiple similar files
- Migrating from one API to another across the codebase
- Adding/removing a field from all similar data structures

**Not for:**
- Single-file edits (use direct editing)
- Unique changes per file (handle individually)
- Changes that need per-file judgment (use an agent per domain)

---

## Batch Operation Protocol

### Step 1: Define the Pattern
```
What:     [exact text/pattern to find]
Replace:  [exact replacement text]
Scope:    [file glob pattern, e.g., "src/**/*.tsx"]
Exclude:  [files to skip, e.g., "**/*.test.tsx"]
```

### Step 2: Preview Before Executing
```bash
# Find all affected files FIRST
grep -rl "oldPattern" src/ --include="*.ts"

# Count matches
grep -rc "oldPattern" src/ --include="*.ts" | grep -v ":0$"

# Show context for each match
grep -rn "oldPattern" src/ --include="*.ts"
```

> **NEVER batch-modify without previewing first.** Show what will change.

### Step 3: Execute the Batch

For text replacements:
```bash
# On Linux/macOS
find src -name "*.ts" -exec sed -i 's/oldPattern/newPattern/g' {} +
```

For file renames:
```bash
# Rename all .js to .ts
find src -name "*.js" -exec bash -c 'mv "$0" "${0%.js}.ts"' {} \;
```

### Step 4: Verify Consistency

```bash
# Verify no remaining old references
grep -rn "oldPattern" src/ --include="*.ts"

# Verify new references are correct
grep -rn "newPattern" src/ --include="*.ts"
```

---

## Safety Rules

1. **Always preview first** — show affected files and match count
2. **Use dry-run where possible** — `sed` has no dry-run, but `grep` counts before
3. **Exclude generated files** — `node_modules/`, `dist/`, `build/`, `.git/`
4. **One batch at a time** — apply, verify, commit before the next batch
5. **Start small** — test on 1-2 files before full codebase

---

## Verification Markers

> [Check] Preview shown to user before execution
> [Check] Generated/excluded files excluded from batch
> [Check] No remaining old references after batch
> [Check] Tests pass after batch modification
