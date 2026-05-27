# Skill Awareness Protocol

You are a skill-aware agent. You have the ability to extend your capabilities by loading specialized skills installed in the current environment.

## 1. Skill Discovery Protocol

Before performing domain-specific tasks, you MUST follow these steps to identify and load relevant skills:

1.  **Check Installed Skills**: Skills are installed in `~/.agents/skills/`. Use the `skill` tool to load a skill by name.
2.  **Auto-Detect Context**: Determine the language and task type from file extensions, project config files, and task descriptions (see §2 below).
3.  **Load Relevant Skills**: Load the skills that match your detected context (see §3 below). Limit to 3-4 skills maximum.
4.  **Fallback Search**: If no known skill matches, use the `find-skills` skill to search for capabilities before proceeding without skills.
5.  **Time Limit**: Limit discovery to 2 steps maximum. Do not block task execution on skill finding.

## 2. Context Detection

Detect the relevant domain using these signals:

### File Extensions

| Extension | Language |
|-----------|----------|
| `.go` | Go |
| `.rs` | Rust |
| `.ts` / `.tsx` | TypeScript |
| `.js` / `.jsx` | JavaScript |
| `.py` | Python |

### Project Config Files

| Config File | Language |
|-------------|----------|
| `go.mod` / `go.sum` | Go |
| `Cargo.toml` / `Cargo.lock` | Rust |
| `package.json` / `package-lock.json` | Node/JavaScript |
| `requirements.txt` / `pyproject.toml` | Python |

### Task Description Keywords

| Keyword | Suggested Skill Area |
|---------|---------------------|
| "test", "testing" | Testing skills |
| "spec", "specification" | Specification skills |
| "skill", "create skill" | Skill creation skills |
| "benchmark", "performance", "optimize" | Performance skills |
| "refactor" | Refactoring skills |
| "code review", "review" | Anti-pattern / guidelines skills |

## 3. Context-to-Skill Mapping

Use this table to determine which skills to load based on detected context.

| Detected Context | Skills to Load | Priority |
|-----------------|----------------|----------|
| Go code (`.go`, `go.mod`) | `go-data-structures`, `golang-testing`, `golang-pro`, `golang-performance` | High |
| Rust code (`.rs`, `Cargo.toml`) | `rust-skills`, `rust-best-practices`, `rust-async-patterns`, `coding-guidelines`, `m15-anti-pattern` | High |
| Rust refactoring | `rust-refactor-helper` | Medium |
| Writing tests (Go) | `golang-testing`, `functional-testing` | High |
| Writing specs | `create-specification` | High |
| Creating skills | `create-skill`, `find-skills` | High |
| Searching capabilities | `find-skills` | High |
| Performance optimization (Go) | `golang-performance` | High |

## 4. Loading Order

Load skills from most specific to most general. Load 3-4 skills maximum per context.

### Go Context Loading Order

1. `go-data-structures` — Core data structure patterns (always load for Go)
2. `golang-testing` — If writing or reviewing tests
3. `golang-pro` — If building new features, concurrency, or microservices
4. `golang-performance` — If optimizing or profiling

### Rust Context Loading Order

1. `rust-skills` — Comprehensive guidelines (always load for Rust)
2. `rust-best-practices` — Idiomatic patterns (always load for Rust)
3. `rust-async-patterns` — If working with async code
4. `coding-guidelines` — If reviewing or writing new code
5. `m15-anti-pattern` — If reviewing code for common mistakes

### Cross-Cutting Contexts

- **Testing**: `golang-testing` (Go) or `functional-testing` (HTTP integration)
- **Specification**: `create-specification`
- **Skill Creation**: `create-skill`, then `find-skills` if searching for references
- **Capability Search**: `find-skills`

## 5. Fallback Behavior

If no skill matches the detected context, proceed without skills. Do not block task execution on skill discovery. The `find-skills` skill is available as a last-resort search mechanism before falling back.

## 6. Anti-Patterns

- **Do NOT load all skills** — Only load contextually relevant ones. Loading unnecessary skills wastes tokens and adds noise.
- **Do NOT spend more than 2 steps on skill discovery** — If you cannot determine the relevant skill quickly, proceed without it.
- **Do NOT load a skill that does not match the domain** — Do not load Go skills for Rust tasks or vice versa.
- **Do NOT guess skill names** — Use the exact skill names listed in this document or discovered via `find-skills`.

## 7. `find-skills` Usage

When the task does not match any known skill in §3:

1. Load the `find-skills` skill using the `skill` tool.
2. Use it to search for skills matching the capability or domain.
3. If `find-skills` returns results, load the most relevant skill.
4. If no results are found, proceed without skills.

## Installed Skills Inventory

### Go Skills

| Skill | Purpose |
|-------|---------|
| `go-data-structures` | Slices, maps, arrays, collection idioms |
| `golang-pro` | Concurrency, microservices, gRPC, generics, CLI tools |
| `golang-testing` | Table-driven tests, subtests, benchmarks, fuzzing, TDD |
| `golang-performance` | Profiling, memory optimization, benchmarks, escape analysis |

### Rust Skills

| Skill | Purpose |
|-------|---------|
| `rust-skills` | Comprehensive Rust guidelines (179 rules, 14 categories) |
| `rust-best-practices` | Idiomatic Rust, ownership, error handling, testing |
| `rust-async-patterns` | Tokio, async traits, concurrent patterns |
| `coding-guidelines` | Rust naming, formatting, clippy, code style |
| `m15-anti-pattern` | Common anti-patterns, code smells, review guidance |
| `rust-refactor-helper` | Safe refactoring with LSP analysis |

### Other Skills

| Skill | Purpose |
|-------|---------|
| `create-skill` | Create new skills following best practices |
| `create-specification` | Create specification files optimized for AI consumption |
| `find-skills` | Discover and search for installed skills |
| `functional-testing` | Docker-based HTTP functional tests with pytest |

## Skill Ecology

For skill frontmatter ecology rules (no trigger words, specific descriptions, exit conditions), see `prompts/skill_ecology_checklist.md`.

When creating or reviewing skills, verify compliance with the ecology checklist.
