<<<<<<< HEAD
# OpenCode Multi-Agent — Shared Hard Rules

This file defines shared rules that ALL agents must follow, regardless of role.
It is the single source of truth for cross-cutting constraints.

---

## 1. Communication Style

- Keep answers short and concise.
- No emojis in commits, issues, PR comments, or code.
- Technical prose only — no fluff or cheerful filler.
- When the user asks a question, answer it first before making edits or running commands.
- When responding to feedback, explicitly state whether you agree or disagree before describing changes.

## 2. Code Quality

- Read files in full before wide-ranging changes; do not rely on search snippets for broad edits.
- No `any` (TypeScript) or unnecessary dynamic typing.
- Inline single-use helpers that have only one call site.
- Check `node_modules` for external API types; do not guess.
- No inline imports — top-level imports only.
- Never remove or downgrade code just to fix type errors from outdated dependencies; upgrade the dependency instead.
- Always ask before removing functionality or code that appears intentional.

## 3. Skill Protocol

- **MANDATORY**: Load domain-relevant skills BEFORE performing any task. This is NOT optional — skills encode critical domain knowledge that ensures correctness.
- Skills are scoped to the subagent invocation and auto-clear on exit.
- Every skill step MUST include a verification marker after each action.
- If a skill is not available, fall back to general capability.
- **Re-check on context shift**: If during execution the task shifts to a new domain (e.g., from implementation to testing), re-scan the `<available_skills>` list and load additional skills as needed.

## 4. Multi-Agent Git Safety

Multiple agents may work in the same repository simultaneously.
Follow these principles to prevent cross-agent contamination.
Detailed command rules are in the `multi-agent-git-safety` skill.

### Principles
- **Own your changes**: Stage explicit paths only. Never `git add -A` or `git add .`.
- **Verify before commit**: Run `git status` to confirm only your files are staged.
- **No destructive operations**: Never run `reset --hard`, `checkout .`, `clean -fd`, `stash`, or `commit --no-verify`.
- **Respect others' work**: Rebase conflicts only in files you modified. For conflicts in unmodified files, abort and ask the user. Never force push.

## 5. Evidence-Based Completion

- Every implemented task MUST produce `evidence.md` + `evidence.json` in `.agent/tasks/<TASK_ID>/` (follow `evidence-pack` skill).
- Every acceptance criterion must have a PASS/FAIL result with supporting evidence.
- QA verification MUST produce `verdict.json` (PASS/FAIL per VC) + `problems.md` (on FAIL).
- Verifiers judge current code and current command results, not prior chat claims.
- Do not claim completion unless every acceptance criterion is PASS.

## 6. Fresh Verifier Rule

- Every verification MUST use a fresh subagent session (never reuse previous sessions).
- The verifier session ID must differ from the implementer's session ID.

## 7. Spec Discipline

- Specs MUST be frozen before implementation begins.
- No spec changes mid-task without re-planning.
- Implementation must trace directly to spec requirements.

## 8. Scoped Commits

All commits MUST follow Scoped Commits format (https://scopedcommits.com/):

```
<scope>: <description>
```

- **No types**: Never use Conventional Commits type prefixes (`feat:`, `fix:`, `chore:`, `refactor:`, `style:`, etc.). The scope IS the classifier.
- **No conversation commits**: Every commit message must describe WHAT changed and WHY. Never write messages like "update", "fix", "wip", "as discussed", "address feedback", "review comments", "try again", or any message that reads like a conversation fragment.
- **Imperative mood**: "add pagination" not "added pagination" or "adding pagination".
- **Scope must be a real subsystem**: Use the repo directory name. Use `treewide` for cross-cutting changes.
- **Body explains WHY**: See commiter agent for full body writing rules.

## 9. Mandatory Skill Activation Before Work

**Every agent, regardless of role, MUST activate domain-relevant skills before starting work.**

This is the single most important rule in the system. Skills encode specialized domain knowledge, language idioms, and workflow protocols that cannot be replicated by general reasoning alone.

### The Rule

```
Before performing ANY task:
  1. Scan the <available_skills> list in your system prompt
  2. Select 2-4 skills matching the task's language, domain, and type
  3. Load each selected skill using the `skill` tool
  4. Do NOT skip skill loading — even for "simple" tasks
  5. Do NOT load all skills — only those contextually relevant
  6. Do NOT guess skill names — use exact names from the list
  7. On context shift (e.g., coding -> testing), re-scan and load new skills
  8. If no skill matches, proceed without — do not block execution
```

### Verification Marker

Every skill step MUST include a verification marker to confirm the skill was loaded and applied:

```
> [Check] loaded <skill-name> for domain <domain>
> [Check] applied <skill-name> guidance during <action>
```

### Exceptions

- **Agent whose sole purpose is `@commiter`** — may skip language skills but MUST load `multi-agent-git-safety`
- **Agent explicitly told "skill loading not required"** by @build — may skip

All other agents (engineer, qa, reviewer, fixer, explorer, plan, architector, reflector) MUST activate skills before work.

### Enforcement

- @build will verify skill activation during gate checks
- Missing skill activation is grounds for @reviewer to REJECT an implementation
- @reflector will flag repeated skill-loading failures in post-mortem analysis


<!-- SEMBLE_START -->
## Semble Code Search

A `semble` MCP server is available with two tools:
- `mcp__semble__search` — search the codebase with a natural-language or code query.
- `mcp__semble__find_related` — find code similar to a specific file and line.

Use `mcp__semble__search` to find where something is implemented — instead of using Grep or Glob to discover files. After semble returns the file and line, navigate there directly and read that file. Do not grep for the same content again.

Pass `--content docs` to search documentation and prose, `--content config` for config files, or `--content all` to search code, docs, and config together.

For CLI fallback or sub-agents without MCP access, use:

```bash
semble search "authentication flow" ./my-project --max-snippet-lines 10
semble search "deployment guide" ./my-project --content docs
semble search "database host port" ./my-project --content config
semble find-related src/auth.py 42 ./my-project
semble search "save model to disk" ./my-project --top-k 10
```

The index is built on first run and cached automatically. If `semble` is not on `$PATH`, use `uvx --from "semble[mcp]" semble`.

### Workflow

1. Call `mcp__semble__search` with a query describing what the code does or its name. The tool returns results with 10 lines of context each (function/class signature + first body lines, enough to confirm the location).
2. Navigate directly to the top result's file and line. Read only the function or class at that location.
3. Make the edit. Do not re-search or grep for the same content.
4. Use `--content docs` for documentation, `--content config` for config files, or `--content all` for everything.
5. Optionally use `mcp__semble__find_related` with `file_path` and `line` to discover similar code elsewhere.
6. Use Grep only when you need every occurrence of a literal string across the whole repo (e.g., all callers of a renamed function).
<!-- SEMBLE_END -->
||||||| parent of 568d7fd (refactor(opencode): restructure config into agents/skills/commands/scripts)
=======
# OpenCode Multi-Agent — Shared Hard Rules

This file defines shared rules that ALL agents must follow, regardless of role.
It is the single source of truth for cross-cutting constraints.

---

## 1. Communication Style

- Keep answers short and concise.
- No emojis in commits, issues, PR comments, or code.
- Technical prose only — no fluff or cheerful filler.
- When the user asks a question, answer it first before making edits or running commands.
- When responding to feedback, explicitly state whether you agree or disagree before describing changes.

## 2. Code Quality

- Read files in full before wide-ranging changes; do not rely on search snippets for broad edits.
- No `any` (TypeScript) or unnecessary dynamic typing.
- Inline single-use helpers that have only one call site.
- Check `node_modules` for external API types; do not guess.
- No inline imports — top-level imports only.
- Never remove or downgrade code just to fix type errors from outdated dependencies; upgrade the dependency instead.
- Always ask before removing functionality or code that appears intentional.

## 3. Skill Protocol

- Load domain-relevant skills BEFORE performing any task (see `skill_loading_preamble.md`).
- Skills are scoped to the subagent invocation and auto-clear on exit.
- Every skill step MUST include a verification marker after each action.
- If a skill is not available, fall back to general capability.

## 4. Multi-Agent Git Safety

Multiple agents may work in the same repository simultaneously.
Follow these principles to prevent cross-agent contamination.
Detailed command rules are in the `multi-agent-git-safety` skill.

### Principles
- **Own your changes**: Stage explicit paths only. Never `git add -A` or `git add .`.
- **Verify before commit**: Run `git status` to confirm only your files are staged.
- **No destructive operations**: Never run `reset --hard`, `checkout .`, `clean -fd`, `stash`, or `commit --no-verify`.
- **Respect others' work**: Rebase conflicts only in files you modified. For conflicts in unmodified files, abort and ask the user. Never force push.

## 5. Evidence-Based Completion

- Every implemented task MUST produce `evidence.md` + `evidence.json` in `.agent/tasks/<TASK_ID>/` (follow `evidence-pack` skill).
- Every acceptance criterion must have a PASS/FAIL result with supporting evidence.
- QA verification MUST produce `verdict.json` (PASS/FAIL per VC) + `problems.md` (on FAIL).
- Verifiers judge current code and current command results, not prior chat claims.
- Do not claim completion unless every acceptance criterion is PASS.

## 6. Fresh Verifier Rule

- Every verification MUST use a fresh subagent session (never reuse previous sessions).
- The verifier session ID must differ from the implementer's session ID.

## 7. Spec Discipline

- Specs MUST be frozen before implementation begins.
- No spec changes mid-task without re-planning.
- Implementation must trace directly to spec requirements.
>>>>>>> 568d7fd (refactor(opencode): restructure config into agents/skills/commands/scripts)
