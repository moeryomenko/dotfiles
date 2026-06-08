---
name: review-output-contract
description: Strict output format for reviewer and QA agents. Ensures reviews are consistent, parseable, and actionable. Follows a structured contract with required sections.
when_to_use: "When performing code review, spec audit, or QA verification. When writing review comments or verification reports. NOT for implementation work."
allowed-tools: Read, Grep, Glob
effort: low
---

# Review Output Contract — Consistent Review Format

> Every review must follow the same structure. Consistent format = actionable feedback.

## Overview

All review and QA output MUST follow this strict contract. This ensures:
- Reviews are parseable by both humans and agents
- Nothing is accidentally omitted
- Feedback is actionable, not vague
- Follow-up is tracked

---

## Review Report Contract

```markdown
## Review: [File or Scope]

### Summary
[1-2 sentence high-level assessment]

### Findings

#### F-001: [Short Title]
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW | INFO
- **File**: `path/to/file.ts` (line N)
- **Issue**: [Specific description of what's wrong]
- **Expected**: [What should be there instead]
- **Spec Reference**: [REQ-XXX or VC-XXX if applicable]

#### F-002: [Short Title]
...

### Overall Assessment
- **PASS** — Meets spec requirements, no blocking issues
- **CONDITIONAL** — Minor issues found, fix before merge
- **FAIL** — Blocking issues found, must rework

### Summary Table
| Finding | Severity | File | Status |
|---------|----------|------|--------|
| F-001   | HIGH     | auth.ts | Fixed |
| F-002   | MEDIUM   | db.ts   | Open  |
```

---

## QA Verification Contract

```markdown
## QA Verification: [Task/Spec ID]

### Verification Criteria

#### VC-01: [Criterion description]
- **Status**: PASS | FAIL
- **Method**: [How it was verified]
- **Evidence**: [Specific proof — test output, command result, etc.]
- **Session**: [Verifier session ID, must differ from engineer's]

#### VC-02: [Criterion description]
...

### Verdict
- **PASS** — All criteria met
- **FAIL** — One or more criteria failed

### Problems (if FAIL)
See `problems.md` for details.
```

---

## Code Review Guidelines

When reviewing code:

1. **Check against spec first** — Does the implementation match the spec?
2. **Verify evidence** — Does evidence.md exist? Are all ACs PASS?
3. **Check git safety** — Are only task-related files changed?
4. **Look for regressions** — Do existing tests still pass?
5. **Be specific** — File, line, expected vs actual

### What NOT to include
- Style preferences not in spec (defer to project conventions)
- Unactionable comments ("this could be better")
- Praise without substance (keep it technical)
- Questions that should be tested (run the code)

---

## Verification Markers

> [Check] Report follows the review contract format
> [Check] Every finding has severity, file, and specific description
> [Check] Spec references included where applicable
> [Check] Overall assessment clearly states PASS/CONDITIONAL/FAIL
