# /review — Quick or Full Code Review

Review code changes against spec requirements, with optional worktree isolation.

## Usage

```
/review [scope] [options]

scope: all | <filename> | <task-id>
options:
  --quick     - High-level review, no deep analysis
  --full      - Deep structural review with LSP analysis (default)
  --worktree  - Review in isolated worktree
```

## Custom Rules

Before reviewing, load project-specific review rules:

```bash
RULES=$(bash scripts/resolve-rules.sh review-rules.md ~/.config/opencode)
if [ -n "$RULES" ]; then
    echo "Loaded custom review rules"
fi
```

## Workflow

1. **Identify Scope**: Determine which files or task to review
2. **Load Custom Rules**: Use resolve-rules.sh to load project-specific review rules
3. **Read Spec**: Load the relevant .spec.md sections
4. **Analyze Diff**: Read the implementation changes
5. **Structural Check**: Use LSP to verify types, signatures, interfaces
6. **Generate Report**: Follow the review-output-contract format
7. **Launch Interactive Review**: Call revdiff for user annotations

## Output

A structured review report following the review-output-contract format.

## Full vs Quick

- **Full**: LSP structural analysis, spec cross-reference, evidence artifact check
- **Quick**: High-level diff inspection, summary assessment only

## Verification Markers

> [Check] Scope identified
> [Check] Spec sections loaded
> [Check] LSP structural check performed
> [Check] Report follows output contract format
