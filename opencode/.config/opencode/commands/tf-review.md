---
description: Review Terraform/OpenTofu configurations against the structured review checklist. Loads review-core.md and technical-patterns.md for systematic analysis.
agent: build
---

# /tf-review — Structured Terraform/OpenTofu Configuration Review

Review Terraform/OpenTofu configurations, modules, and state operations against structured guidelines.

## Usage

`/tf-review [--quick|--full] [scope]`

## Workflow

1. Load `~/.config/opencode/skills/terraform/review-core.md` for the main review checklist
2. Load `~/.config/opencode/skills/terraform/technical-patterns.md` for execution model context
3. Load `~/.config/opencode/skills/terraform/false-positive-guide.md` to avoid flagging acceptable patterns
4. Load the antonbabenko/terraform-skill for user-facing HCL patterns if needed
5. Run through each checklist category (Structure, Naming, State, Security, Identity, Testing, CI/CD, Versioning)
6. Produce a structured report following the template in review-core.md

## Quick Mode

`/tf-review --quick` — High-level check of the 3 most critical categories: Security, State Impact, and Resource Identity.

## Full Mode (default)

`/tf-review --full` — Systematic check across all 10 categories with per-category findings.

## Output

Structured report with:
- Runtime context (terraform/tofu version, provider versions)
- Per-category findings table (severity, finding, evidence, fix)
- PASS/FAIL/APPROVED summary
