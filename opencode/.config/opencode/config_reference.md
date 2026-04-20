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

| Agent | Mode | write | edit | bash | lsp | glob | grep | question | webfetch | skill |
|-------|------|-------|------|------|-----|------|------|----------|----------|-------|
| **architector** | primary | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **plan** | primary | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **build** | primary | ✅ | ✅ | ✅ (scoped) | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| explorer | subagent | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| engineer | subagent | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| reviewer | subagent | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| qa | subagent* | ✅* | ✅* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| reflector | subagent | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |

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
| **architector** | `llama/qwen` | Spec Architect & Iterative Refiner |
| **plan** | `llama/qwen` | Implementation Planner (task decomposition) |
| **build** | `llama/qwen` | Staff+ Engineer / Execution Orchestrator |
| explorer | `llama/qwen` | Subagent — research & discovery |
| engineer | `llama/qwen` | Subagent — implementation specialist |
| reviewer | `llama/qwen` | Subagent — spec compliance auditor |
| qa | `llama/qwen` | Subagent — verification testing |
| reflector | `llama/qwen` | Subagent — post-implementation feedback |
| goreview | `llama/qwen` | Primary — Go code review without modifications |

## File Structure

```
.config/opencode/
├── opencode.json              ← Main configuration
├── subtask2.jsonc             ← Delegation plugin config
├── workflow.md                ← Workflow description (~170 lines)
├── config_reference.md        ← This file (configuration reference)
├── prompts/
│   ├── planner.md             ← @architector prompt (iterative spec refinement)
│   ├── plan_impl.md           ← @plan prompt (task decomposition)
│   ├── build.md               ← @build prompt (implementation & orchestration)
│   ├── explorer.md            ← @explorer prompt (research)
│   ├── engineer.md            ← @engineer prompt (implementation)
│   ├── reviewer.md            ← @reviewer prompt (compliance audit)
│   ├── qa.md                  ← @qa prompt (verification testing)
│   ├── reflector.md           ← @reflector prompt (post-mortem analysis)
│   └── plugin_awareness.md    ← Plugin guidance
├── specs/
│   └── templates/
│       ├── spec_template.md          ← Spec contract template
│       └── research_report_template.md  ← Research report template
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
| 2026-04-21 | Added `@architector` primary agent | Iterative spec refinement separate from planning |
| 2026-04-21 | Repositioned `@plan` as task decomposer | Created explicit `implementation_plan.md` artifact |
| 2026-04-21 | Updated `@build` prompt — removed decomposition logic | Clear boundary: build implements/orchestrates, never plans |
| 2026-04-21 | Added `prompts/plan_impl.md` | New prompt for repositioned @plan agent |
| 2026-04-21 | Replaced `prompts/planner.md` content | Now contains @architector (iterative spec refinement) |
| 2026-04-21 | Updated tool matrix — added architector, updated plan/build | Reflects new 3-primary-agent architecture |
| 2026-04-21 | Fixed stale model references | `llama/gemma4` → `llama/qwen` throughout |
| 2026-04-20 | Added `prompts/build.md` | Build agent identity with delegation behavior |
| 2026-04-20 | Added `permission` block to build agent | Prevent accidental destructive commands |
| 2026-04-20 | Removed `webfetch`/`websearch` from build | Build executes specs, not research |
| 2026-04-20 | Added `lsp` to engineer tools | Code navigation for implementation |
| 2026-04-20 | Increased build steps to 30 | Execution needs more cycles than planning |
| 2026-04-20 | Enhanced `subtask2.jsonc` | Quality gates, parallel limits, timeouts |
| 2026-04-20 | Updated `engineer.md` | Pipeline awareness + escalation paths |
| 2026-04-20 | Split `workflow.md` → `workflow.md` + `config_reference.md` | Separation of concerns |
