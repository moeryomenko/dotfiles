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
