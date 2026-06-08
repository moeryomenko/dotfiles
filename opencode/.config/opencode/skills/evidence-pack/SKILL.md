---
name: evidence-pack
description: Create evidence artifacts for task completion. Produces evidence.md (human-readable) and evidence.json (machine-readable) per task with per-acceptance-criterion status. Use after implementing a task to prove it works.
when_to_use: "After completing a task implementation. When the user asks for proof of completion, or before handing off to QA for verification. NOT for writing code — for documenting what was done."
allowed-tools: Read, Write, Grep, Bash
effort: low
---

# Evidence Pack — Task Completion Artifacts

> "Seems right" is not done. Evidence artifacts prove every acceptance criterion is met.

## Overview

Every implemented task MUST produce evidence artifacts before being considered complete. These artifacts serve as:
- **Proof** that the task was implemented correctly
- **Audit trail** for future reference
- **Handoff document** for reviewer and QA agents

---

## Evidence Schema

### evidence.md (Human-Readable)

```markdown
# Evidence: TASK-NNN

## Task
[Task description from implementation plan]

## Acceptance Criteria
- AC-1: PASS — [evidence description, e.g., "Function returns expected struct"]
- AC-2: PASS — [evidence description]
- AC-3: FAIL — [reason]

## Files Changed
- `path/to/file.go` — [change summary]
- `path/to/test.go` — [test added]

## Verification Commands Run
- `go test ./...` — 42/42 passing
- `go vet ./...` — no issues
```

### evidence.json (Machine-Readable)

```json
{
  "task_id": "TASK-NNN",
  "spec_ref": ".specs/SPEC-NNN.md",
  "ac_results": [
    {"id": "AC-1", "status": "PASS", "evidence": "Function returns expected struct"},
    {"id": "AC-2", "status": "PASS", "evidence": "Edge case handled"}
  ],
  "files_changed": ["path/to/file.go"],
  "verification": {
    "tests_pass": 42,
    "tests_fail": 0,
    "lint_pass": true,
    "build_pass": true
  },
  "verifier_session": "fresh-<uuid>"
}
```

### verdict.json (QA Output)

```json
{
  "task_id": "TASK-NNN",
  "verdict": "PASS" | "FAIL",
  "criteria_results": [
    {"vc_id": "VC-01", "status": "PASS", "evidence": "Tested with 10 concurrent requests"},
    {"vc_id": "VC-02", "status": "FAIL", "evidence": "Edge case not covered"}
  ],
  "problems_file": "problems.md",
  "verifier_session_id": "<uuid>"
}
```

---

## Artifact Storage

All artifacts stored at: `.agent/tasks/<TASK_ID>/`

```
.agent/tasks/TASK-001/
├── evidence.md          # Human-readable proof
├── evidence.json        # Machine-readable proof
├── verdict.json         # QA verification result
├── problems.md          # (on FAIL only) Problems found during QA
└── raw/                 # Raw supporting evidence
    ├── build-output.txt
    ├── test-output.txt
    └── ...
```

---

## Protocol

### After Implementation (Engineer)
1. Run verification commands (build, test, lint)
2. Create `.agent/tasks/<TASK_ID>/evidence.md`
3. Create `.agent/tasks/<TASK_ID>/evidence.json`
4. Store raw output in `.agent/tasks/<TASK_ID>/raw/`

### After QA Verification (QA Agent)
1. Run fresh verification in new subagent session
2. Create `.agent/tasks/<TASK_ID>/verdict.json`
3. If FAIL: create `.agent/tasks/<TASK_ID>/problems.md`

---

## Verification Markers

> [Check] evidence.md exists at .agent/tasks/<TASK_ID>/evidence.md
> [Check] evidence.json exists and is valid JSON
> [Check] Every AC has PASS/FAIL with supporting evidence
> [Check] Verification commands were actually run (not assumed)
> [Check] verdict.json exists after QA pass
