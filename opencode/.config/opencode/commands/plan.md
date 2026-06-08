# /plan — Generate Implementation Plan from Spec

Decompose an approved `.spec.md` into a task-ordered `.plans/<feature-name>/plan.md`.

## Usage

```
/plan [spec-path]
```

If no spec-path is given, use the most recent .spec.md in the workspace.

## Custom Rules

Before generating the plan, load project-specific planning rules:

```bash
RULES=$(bash scripts/resolve-rules.sh planning-rules.md ~/.config/opencode)
if [ -n "$RULES" ]; then
    echo "Loaded custom planning rules"
    echo "$RULES"
fi
```

## Workflow

1. **Read the Spec**: Read the .spec.md file specified by the user or auto-detected
2. **Load Custom Rules**: Use resolve-rules.sh to load project-specific planning rules
3. **Detect Project Type**: Check for go.mod, Cargo.toml, package.json, etc.
4. **Decompose into Tasks**: Break the spec into atomic, ordered tasks
5. **Assign Skills**: Scan `<available_skills>` from system prompt and map each task to 2-4 relevant skills
6. **Produce Plan**: Write `plan.md` to `.plans/<feature-name>/plan.md`
7. **Submit for Review**: Call submit_plan with the plan path for user annotation

## Output

```
.plans/<feature-name>/plan.md
```

## Full vs Quick

- **Full**: Complete decomposition with task details, dependencies, skills, risk assessment
- **Quick**: High-level task list only, suitable for small changes

## Verification Markers

> [Check] Spec read and understood
> [Check] Custom rules loaded (if any)
> [Check] Project type detected
> [Check] All tasks have acceptance criteria
> [Check] Dependency ordering is valid
