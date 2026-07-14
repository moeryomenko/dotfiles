---
name: terraform
description: Terraform/OpenTofu HCL review, development patterns, and core internals. Auto-load when working with .tf files. Complements antonbabenko/terraform-skill for user-facing HCL patterns; this skill covers structured code review and development-side knowledge.
invocation_policy: automatic
---

# Terraform & OpenTofu Skill

Development-side Terraform skill: structured review prompts, core internals, and feature reference for Terraform/OpenTofu HCL and engine development. Complements the user-facing [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill).

For HCL authoring patterns (module design, variable/output contracts, testing strategy, CI/CD templates, state backends), use that skill. This skill covers:

- **Structured code review** for Terraform/OpenTofu configurations
- **Core engine internals** (graph, state, plans, providers)
- **Development-side patterns** (HCL evaluation semantics, module tree resolution, test framework mechanics)

## Configuration

The Terraform skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Structured HCL Review
When reviewing Terraform/OpenTofu configurations, modules, or state operations:
1. Load `review-core.md` for the main review checklist
2. Load `technical-patterns.md` for execution model and dependency graph context
3. Load `false-positive-guide.md` for patterns that look wrong but are correct

### HCL Evaluation & Module Resolution
When deep-diving into HCL semantics or module tree resolution:
1. Load `features/hcl-patterns.md` for HCL evaluation semantics, expression behavior, type system
2. Load `features/module-design.md` for module tree resolution, remote module contracts, registry patterns

### State & Backend Internals
When debugging state issues, migrating state, or understanding backend behavior:
1. Load `features/state-management.md` for state file format, serialization, locking internals
2. Load `technical-patterns.md` for the state lifecycle and backend protocol

### Testing Infrastructure
When writing or debugging Terraform/OpenTofu tests:
1. Load `features/testing.md` for native test framework mechanics, mock provider patterns, Terratest structure

### CI/CD Integration
When setting up Terraform CI/CD pipelines:
1. Load `features/ci-cd.md` for pipeline architecture, artifact management, approval workflows

### Security & Compliance
When auditing configurations for security:
1. Load `features/security-compliance.md` for provider permission models, state file hardening, policy engine patterns

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.

For user-facing HCL authoring patterns (module design, variable/output contracts, testing strategy, state backends), reference [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill).
