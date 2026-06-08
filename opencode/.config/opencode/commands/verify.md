# /verify — Run Verification Gate

Run the verification gate: lint -> typecheck -> test -> evidence check.

## Usage

```
/verify [task-id]
```

If no task-id is given, verify the entire project.

## Workflow

1. **Lint**: Run the project linter (e.g., `go vet`, `cargo check`, `eslint`, `ruff`, etc.)
2. **Typecheck**: Run the type checker
3. **Build**: Ensure the project compiles
4. **Test**: Run test suites
5. **Evidence Check**: Verify evidence artifacts exist for the task

Consult loaded skills for language-specific verification commands. Examples:
- Go: `go vet ./... && go build ./... && go test -race ./...`
- Rust: `cargo check && cargo build && cargo test`
- TypeScript: `tsc --noEmit && npm test`
- Python: `ruff check . && pytest`

## Evidence Artifact Check

After running verification commands, check that evidence artifacts exist:

- `.agent/tasks/<TASK_ID>/evidence.md`
- `.agent/tasks/<TASK_ID>/evidence.json`

If running as QA (fresh verifier), also produce:
- `.agent/tasks/<TASK_ID>/verdict.json`

## Output

Verification report with per-VC PASS/FAIL status.

## Full vs Quick

- **Full**: Complete gate (lint -> typecheck -> build -> test -> evidence)
- **Quick**: Test suite only

## Fresh Verifier Rule

When running as the QA agent, you MUST use a fresh subagent session.
Do not reuse the engineer's session. Produce verdict.json with your session ID.

## Verification Markers

> [Check] Lint passes
> [Check] Build passes
> [Check] Tests pass
> [Check] Evidence artifacts exist
> [Check] Verdict.json produced (QA mode only)
