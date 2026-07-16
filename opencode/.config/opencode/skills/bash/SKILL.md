---
name: bash
description: Complete Bash development skill — defensive patterns, testing with BATS, linting with ShellCheck, POSIX compatibility, idioms, project structure, and CI/CD integration. Load automatically when working with .sh files.
invocation_policy: automatic
---

# Bash Skill Assembly

Unified Bash development knowledge base organized by domain features. Route to the correct feature file based on the task.

## ALWAYS READ

1. Load `features/defensive-patterns.md` before loading any other feature file.

This file is MANDATORY. It contains the foundational defensive programming knowledge (strict mode, error trapping, variable safety, safe file operations, argument parsing, structured logging) that every other feature builds on. Skipping it leads to fragile, unsafe scripts.

## Configuration

The Bash skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Defensive Patterns
When writing new Bash scripts, hardening existing scripts, or reviewing for safety:
1. Load `features/defensive-patterns.md` for strict mode (`set -Eeuo pipefail`), error trapping, variable quoting, safe temp files, argument parsing, structured logging, idempotent design, and dependency checking.
2. This is the ALWAYS READ feature — load it before anything else.

### Testing
When writing tests, setting up BATS infrastructure, or establishing test patterns:
1. Load `features/testing.md` for BATS fundamentals, test structure, assertions, setup/teardown, mocking and stubbing, fixture management, error condition testing, shell compatibility testing, parallel execution, and CI/CD integration.

### Linting
When configuring ShellCheck, setting up shfmt, or enforcing code quality gates:
1. Load `features/linting.md` for ShellCheck configuration (`.shellcheckrc`), error code categories (SC1000–SC3057), suppression patterns, shfmt integration, pre-commit hooks, editor integration, CI workflows, and common violation patterns with before/after examples.

### POSIX Compatibility
When targeting POSIX sh (`#!/bin/sh`) or ensuring portability across dash, ash, yash, BusyBox:
1. Load `features/posix-compatibility.md` for shebang conventions, strict mode diffs, conditional diffs (`[ ]` vs `[[ ]]`), missing features (arrays, process substitution, `local`, `+=`), portable alternatives, and ShellCheck SC3010–SC3057 POSIX compliance flags.

### Idioms
When writing idiomatic Bash, choosing between competing syntaxes, or leveraging modern Bash features:
1. Load `features/idioms.md` for parameter expansion patterns, arithmetic, arrays and associative arrays, process substitution, here-documents and here-strings, brace expansion, redirection patterns, coprocesses, nameref variables, and Bash 5.x features with version requirements.

### Project Structure
When designing the layout of a Bash project, organizing libraries, or establishing conventions:
1. Load `features/project-structure.md` for recommended project layout (`bin/`, `lib/`, `tests/`, `fixtures/`), library sourcing patterns, module system, entry point scripts, function naming conventions, exit code conventions, dependency management, documentation generation, configuration file patterns, and Makefile targets.

### CI Integration
When setting up continuous integration for Bash projects, configuring automated checks, or standardizing pipelines:
1. Load `features/ci-integration.md` for GitHub Actions workflows, GitLab CI pipelines, pre-commit hooks, Makefile targets, matrix testing across shell dialects, containerized testing, actionlint, automated releases, coverage reporting, CodeQL scanning, secrets detection, and Dependabot/Renovate integration.

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.

### Common Task-to-Feature Mapping

| Task | Primary Features |
|------|-----------------|
| New script | `defensive-patterns`, `idioms`, `project-structure` |
| Review existing script | `defensive-patterns`, `linting`, `posix-compatibility` |
| Write tests | `testing`, `defensive-patterns` |
| Set up CI | `ci-integration`, `linting`, `testing` |
| Port script to POSIX sh | `posix-compatibility`, `linting` |
| Modernize / refactor | `idioms`, `defensive-patterns`, `project-structure` |
| Library / module design | `project-structure`, `defensive-patterns`, `idioms` |
| Configure linting | `linting`, `ci-integration` |
| Debug script failure | `defensive-patterns`, `testing` |

## Verification

[Check] SKILL.md contains valid YAML frontmatter with name, description, invocation_policy
[Check] ALWAYS READ section points to features/defensive-patterns.md as mandatory first load
[Check] Capabilities section covers all 7 domains: defensive-patterns, testing, linting, posix-compatibility, idioms, project-structure, ci-integration
[Check] All feature file references use relative paths starting with features/
[Check] Cross-Referencing table maps common tasks to primary features
