# Skill Ecology Checklist

When creating or reviewing a skill's YAML frontmatter, verify compliance with these ecological rules.
Non-ecological skills over-activate, interfere with other skills, and waste context tokens.

## Description Rules

- [ ] **Specificity**: Description targets a SPECIFIC domain — NOT "Use for all Go tasks" or "Apply to any project"
  - ✅ GOOD: "Implements concurrent Go patterns using goroutines and channels"
  - ❌ BAD: "Use for any Go project you're working on"

- [ ] **Concrete keywords**: Description uses specific task keywords (e.g., "goroutines", "channels", "gRPC")
  - ✅ GOOD: "Sets up Docker-based HTTP functional tests with pytest"
  - ❌ BAD: "Helps with testing"

- [ ] **No trigger words**: Description does NOT contain aggressive activation words:
  - BANNED: "MUST", "ALWAYS", "EVERY", "REQUIRED", "NEVER SKIP"
  - These words force the model to activate the skill regardless of context relevance

- [ ] **Counter-example**: Description includes a "Do NOT use for..." clause when appropriate
  - ✅ GOOD: "Use when working with Go slices and maps. Do NOT use for concurrent data structure safety."
  - ❌ BAD: (No negative boundary stated)

## Exit Condition (in skill body)

- [ ] **Early exit instruction**: Skill body includes:
  > "If this task does not match [specific domain], skip this skill and proceed without it."
  - This prevents the skill from interfering when incorrectly activated

## Tools

- [ ] **Minimal tool list**: Only tools directly needed by the skill are listed
  - Fewer tools = less context waste
  - If a tool is not used by the skill's instructions, remove it

## Name

- [ ] **Descriptive name**: Skill name clearly describes its purpose
  - ✅ GOOD: `go-testing` or `rust-review`
  - ❌ BAD: `test-helper`

## Cross-Skill Compatibility

- [ ] **No conflicts**: Skill does not contradict instructions from sibling skills
  - Test skills in combination with other skills in the same domain
  - If two skills provide overlapping guidance, coordinate which one owns which section

## Examples

### Non-Ecological (BAD)

```yaml
---
name: non-eco
description: MUST USE with any prompt
---
```

### Ecological (GOOD)

```yaml
---
name: my-testing-skill
description: >
  Testing patterns for [language] including table-driven tests, property-based
  testing, and coverage analysis. Use when writing, reviewing, or debugging
  tests in [language]. Do NOT use for HTTP functional testing.
---
```

---

## Review Process

When reviewing a new or existing skill:

1. Read the YAML frontmatter
2. Check each item in this checklist
3. If ANY item fails, mark the skill as needing revision
4. Provide specific fix suggestions for each failed item
