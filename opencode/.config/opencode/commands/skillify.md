# /skillify — Create Skill from Repetitive Workflow

Extract a repetitive multi-step workflow into a reusable SKILL.md.

## Usage

```
/skillify <skill-name> [description]
```

## Workflow

1. **Identify the Pattern**: Confirm this is a 3+ times repeated workflow with 5+ consistent steps
2. **Check Existing Skills**: Verify no existing skill covers this pattern
3. **Generate SKILL.md**: Create skills/<name>/SKILL.md following the standard template
4. **Validate**: Run `bash scripts/validate-skills` to check frontmatter
5. **Register**: Skill is auto-discovered by its directory name in the skill path — no registration needed

## Skill Template

```markdown
---
name: [kebab-case-name]
description: [One sentence describing what this skill does]
when_to_use: "[When the user asks X, works with Y files, or Z domain. NOT for A.]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash — only what's needed]
effort: [low | medium | high]
---

# [Skill Name] — [Short Subtitle]

> [One-line philosophy or principle]

## Overview
[2-3 sentences explaining what this skill enables]

## When to Use
Good for: [list]
Not for: [list]

## Protocol
### Step 1: [Name]
[Description]
...

## Verification Markers
> [Check] Step 1 completed
> [Check] Step 2 completed
```

## Output

New skill at `skills/<name>/SKILL.md` with validated frontmatter.

## Verification Markers

> [Check] Pattern confirmed (3+ repetitions)
> [Check] No existing skill conflict
> [Check] SKILL.md follows template
> [Check] Frontmatter passes validate-skills
> [Check] Skill auto-discovered by directory name
