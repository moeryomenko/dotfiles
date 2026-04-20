# Configuration Reference

## opencode.json — Full Configuration

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "@franlol/opencode-md-table-formatter@latest",
    "opencode-mem",
    "@plannotator/opencode@latest",
    "@spoons-and-mirrors/subtask2@latest"
  ],
  "provider": {
    "llama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama(local)",
      "options": {
        "baseURL": "http://127.0.0.1:8080/v1",
        "timeout": false
      },
      "models": {
        "gemma4": {
          "name": "gemma4",
          "limit": {
            "context": 262144,
            "output": 65536
          }
        }
      }
    }
  },
  "agent": { ... }
}
```

> **Note**: The full agent configuration is in `opencode.json`. See the agent tool matrix and permission rules below for details.

## Tool Matrix

| Agent | write | edit | bash | lsp | glob | grep | webfetch | websearch | skill |
|-------|-------|------|------|-----|------|------|----------|-----------|-------|
| plan | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| build | ✅ | ✅ | ✅ (scoped) | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| explorer | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| engineer | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| reviewer | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| qa | ✅* | ✅* | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| reflector | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |

\* qa can only modify test files (`*_test.go`, `*.spec.ts`, `*_test.py`, `tests/`, etc.)

## Permission Rules

### Build Agent
```json
"permission": {
  "edit": "ask",
  "bash": {
    "*": "deny",
    "go vet *": "allow",
    "go build *": "allow",
    "go test *": "allow",
    "go fmt *": "allow",
    "golangci-lint run *": "allow",
    "git diff *": "allow",
    "git log *": "allow",
    "grep -r * *.go": "allow",
    "find * -name '*.go'": "allow",
    "cat *": "allow"
  }
}
```

### Goreview Agent
```json
"permission": {
  "edit": "deny",
  "bash": {
    "*": "deny",
    "go vet *": "allow",
    "staticcheck *": "allow",
    "errcheck *": "allow",
    "golangci-lint run *": "allow",
    "git diff *": "allow",
    "git log *": "allow",
    "grep -r * *.go": "allow",
    "find * -name '*.go'": "allow"
  }
}
```

## Plugin Configuration

### subtask2.jsonc
```jsonc
{
  "replace_generic": true,
  "generic_return": "Review the subtask output above. Validate that it meets the acceptance criteria specified in the task. If the output is incomplete or incorrect, note the specific deficiencies. If it meets criteria, summarize key results and continue to the next logical step.",
  "max_parallel": 2,
  "require_return_instruction": true,
  "subtask_timeout": 300
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `replace_generic` | bool | `false` | Replace default subtask summary prompt with custom one |
| `generic_return` | string | N/A | Custom prompt used when no return instruction is given |
| `max_parallel` | int | `1` | Max concurrent subtasks (prevents overwhelming the model) |
| `require_return_instruction` | bool | `false` | Force @build to specify what happens after each subtask completes |
| `subtask_timeout` | int (seconds) | `0` (none) | Auto-cancel subtasks running too long |

## Agent Models

| Agent | Model | Notes |
|-------|-------|-------|
| plan | `llama/gemma4` | Primary orchestrator |
| build | `llama/gemma4` | Staff+ engineer |
| explorer | `llama/gemma4` | Subagent |
| engineer | `llama/gemma4` | Subagent |
| reviewer | `llama/gemma4` | Subagent |
| qa | `llama/gemma4` | Subagent |
| reflector | `llama/gemma4` | Subagent |
| goreview | `llama.cpp/qwen3.5` | Specialized Go linting model |

## File Structure

```
.config/opencode/
├── opencode.json              ← Main configuration
├── subtask2.jsonc             ← Delegation plugin config
├── workflow.md                ← Workflow description (~160 lines)
├── config_reference.md        ← This file (configuration reference)
├── prompts/
│   ├── planner.md             ← Spec Architect prompt
│   ├── build.md               ← Staff+ Engineer prompt (NEW)
│   ├── explorer.md            ← Researcher prompt
│   ├── engineer.md            ← Implementation prompt
│   ├── reviewer.md            ← Compliance Auditor prompt
│   ├── qa.md                  ← Spec Verifier prompt
│   ├── reflector.md           ← Meta-Analysis prompt
│   └── plugin_awareness.md    ← Plugin guidance
├── specs/
│   └── templates/
│       ├── spec_template.md          ← Spec contract template (NEW)
│       └── research_report_template.md  ← Research report template (NEW)
├── agents/                    ← Agent skills definitions
│   ├── go-concurrency-audit.md
│   ├── go-error-audit.md
│   ├── goformat.md
│   ├── golint.md
│   └── gotest.md
└── plugins/                   ← Plugin directory (empty)
```

## Configuration Change Log

| Date | Change | Rationale |
|------|--------|-----------|
| 2026-04-20 | Added `prompts/build.md` | Build agent identity with delegation behavior |
| 2026-04-20 | Added `permission` block to build agent | Prevent accidental destructive commands |
| 2026-04-20 | Removed `webfetch`/`websearch` from build | Build executes specs, not research |
| 2026-04-20 | Added `lsp` to engineer tools | Code navigation for implementation |
| 2026-04-20 | Increased build steps to 30 | Execution needs more cycles than planning |
| 2026-04-20 | Enhanced `subtask2.jsonc` | Quality gates, parallel limits, timeouts |
| 2026-04-20 | Updated `engineer.md` | Pipeline awareness + escalation paths |
| 2026-04-20 | Split `workflow.md` → `workflow.md` + `config_reference.md` | Separation of concerns |
