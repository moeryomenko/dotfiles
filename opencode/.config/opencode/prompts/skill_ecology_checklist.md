# Skill Ecology Checklist

Use this checklist when auditing skill files (SKILL.md) for structural
correctness. Every skill MUST pass these checks before being considered valid.

## Frontmatter Checks

- [ ] `name` is present, lowercase hyphen-separated, <= 64 chars
- [ ] `name` matches the parent directory name
- [ ] `description` is present and covers BOTH what the skill does AND when to use it
- [ ] `description` uses third person ("Use when...", not "I help with...")
- [ ] `when_to_use` field is present and includes positive triggers AND negative exclusions
- [ ] `allowed-tools` lists only the tools the skill actually needs
- [ ] `effort` is set to `low`, `medium`, or `high`

## Content Checks

- [ ] Skill has a clear title (`# Skill Name`)
- [ ] Skill has an Overview section (2-3 sentences)
- [ ] Skill has "When to Use" section with explicit positive and negative lists
- [ ] Skill has step-by-step Protocol section
- [ ] Skill has Verification Markers (`> [Check] ...`) after each step
- [ ] No emoji in skill content (per AGENTS.md rule)

## Structural Checks

- [ ] File is named `SKILL.md` exactly (case-sensitive)
- [ ] File lives in its own directory named after the skill
- [ ] No frontmatter field is `name` that differs from the directory name
- [ ] File passes `scripts/validate-skills` validator
