---
name: resolution-chain
description: Resolve configuration files through a three-layer override chain (project -> user -> default). Enables customizable skill behavior without editing skill files directly.
when_to_use: "When loading configuration files, custom rules, or overrides for any skill or command. When the user wants to customize behavior per project. NOT for runtime data — for configuration only."
allowed-tools: Read, Bash, Grep
effort: low
---

# Resolution Chain — Multi-Layer Configuration

> First-found-wins configuration resolution. Customize without editing skills.

## Overview

The resolution chain enables users to override any configuration file at three levels:

```
1. <cwd>/.opencode/<file>              # Project-level override
2. ~/.config/opencode/<file>           # User-level override
3. <skill-root>/references/<file>      # Bundled default
```

**Rules:**
- First-found-wins (never merge)
- Empty files are treated as absent
- If no file found at any level -> error or empty result

---

## Resolution Scripts

### resolve-file.sh (Three-Layer)

```bash
scripts/resolve-file.sh <relative-path> [data-dir]
```

Returns the first file found in:
1. `.opencode/<path>` (project override)
2. `<data-dir>/<path>` (user override)
3. `<skill-root>/references/<path>` (bundled default)

### resolve-rules.sh (Two-Layer, for Commands)

```bash
scripts/resolve-rules.sh <filename> [data-dir]
```

Returns the first file found in:
1. `.opencode/<filename>` (project override)
2. `<data-dir>/<filename>` (user override)
3. (empty output if neither exists)

---

## Usage in Skills

Skills load custom rules via:

```bash
# Load project-specific planning rules
RULES=$(bash scripts/resolve-rules.sh planning-rules.md ~/.config/opencode)
if [ -n "$RULES" ]; then
    echo "Loaded custom planning rules"
    echo "$RULES"
fi
```

---

## Usage in Commands

Commands load rules at startup:

```bash
# In commands/plan.md:
1. Resolve custom rules: resolve-rules.sh planning-rules.md
2. If rules found: append as additional instructions
3. Execute command with merged instructions
```

---

## Example: Project-Specific Planning

```
User creates: my-project/.opencode/planning-rules.md
Content: "Always use PostgreSQL, never SQLite"

When /plan runs:
1. resolve-rules.sh checks:
   -> my-project/.opencode/planning-rules.md? YES -> return content
   -> ~/.config/opencode/planning-rules.md? SKIP (first-found-wins)
2. Plan generator APPENDS custom rules as additional instructions
```

---

## Verification Markers

> [Check] Resolution order: project -> user -> default
> [Check] Empty files treated as absent
> [Check] First-found-wins, never merged
> [Check] resolve-rules.sh always exits 0 (non-fatal if no rules found)
