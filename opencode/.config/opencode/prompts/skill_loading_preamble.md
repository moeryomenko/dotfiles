# Skill Loading Preamble — MANDATORY

You MUST load domain-relevant skills BEFORE performing any task.
This is NOT optional — skills encode critical domain knowledge.

## Protocol

1. **Detect context** — Identify language (Go, Rust, Python, etc.) and task type
   from file extensions, config files, and task description keywords.
   See `prompts/skill_awareness.md` §2 for full detection rules.

2. **Load relevant skills** — Use the `skill` tool to load 2-4 skills matching
   your detected context. Follow the loading order in `skill_awareness.md` §3-4.

3. **Fallback** — If no skill matches, load `find-skills` and search.
   Limit discovery to 2 steps. Never block task execution on skill finding.

4. **Re-check on context shift** — If during execution the task shifts to a
   new domain (e.g., from Go to tests), load additional skills as needed.

## Anti-Patterns

- **Do NOT** skip skill loading — this wastes encoded expertise
- **Do NOT** load all skills — only 2-4 contextually relevant ones
- **Do NOT** guess skill names — use exact names from the inventory

## Quick Reference

| Detected Context | Skills to Load |
|-----------------|----------------|
| Go code (`.go`, `go.mod`) | `go-data-structures`, `golang-pro` (always); `golang-testing` (if tests); `golang-performance` (if optimizing) |
| Rust code (`.rs`, `Cargo.toml`) | `rust-skills`, `rust-best-practices` (always); `rust-async-patterns` (if async); `m15-anti-pattern` (if reviewing) |
| Testing (Go) | `golang-testing` |
| Testing (HTTP/Integration) | `functional-testing` |
| Specification drafting | `create-specification` |
| Code review | `coding-guidelines`, `m15-anti-pattern` |
| Performance profiling | `golang-performance` |
| Skill creation | `create-skill` |

## Before Starting Work

Review BOTH:
- `prompts/skill_awareness.md` — For available skills and context detection
- `prompts/plugin_awareness.md` — For available plugins
