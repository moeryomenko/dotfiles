---
name: skillify
description: Auto-create new skills from repetitive workflows. When you notice yourself doing the same multi-step process repeatedly, extract it into a reusable SKILL.md that any agent can use.
when_to_use: "When the user says 'make this a skill', 'create a skill for this', 'I keep doing this same thing', or when a repetitive multi-step pattern is observed. NOT for one-off tasks."
allowed-tools: Read, Write, Glob, Grep
effort: low
---

# Skillify — Auto-Create Skills from Workflows

> Turn repetitive patterns into reusable skills. If you've done it three times, it should be a skill.

## When to Skillify

**Good candidates:**
- You've seen the user ask for the same type of work 3+ times
- A workflow involves 5+ consistent steps
- The pattern works across different projects
- Other agents could benefit from this knowledge

**Bad candidates:**
- One-off tasks (just do them)
- Project-specific hacks (use memory instead)
- Already covered by existing skills (check first)

---

## Skill Creation Protocol

### Step 1: Identify the Pattern
```
What triggers this workflow? (user says X, file type Y, domain Z)
What steps are always the same?
What parts vary between uses?
What's the expected output?
```

### Step 2: Generate SKILL.md

Use this template:

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

### Step 2: [Name]
[Description]

...

## Verification Markers
> [Check] Step 1 completed
> [Check] Step 2 completed
```

### Step 3: Validate
```bash
# Validate the new skill frontmatter
bash scripts/validate-skills
```

### Step 4: Register
The skill is auto-discovered by its directory name in the skill path. No registration document is needed — agents discover skills dynamically from their system prompt's `<available_skills>` list.

---

## Verification Markers

> [Check] Pattern identified with 3+ repetitions
> [Check] No existing skill covers this pattern
> [Check] SKILL.md follows template (frontmatter + protocol + verification markers)
> [Check] Frontmatter validates with validate-skills script
> [Check] Skill auto-discovered by directory name
