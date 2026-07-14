---
description: Review Terraform provider implementations (Plugin Framework & SDK v2). Loads provider skill for schema, lifecycle, and testing review.
agent: build
---

# /tf-provider-review — Provider Implementation Review

Review Terraform provider code for correctness, schema design, and testing coverage.

## Usage

`/tf-provider-review [--quick|--full]`

## Workflow

1. Load `~/.config/opencode/skills/terraform-provider/plugin-framework.md` for Framework conventions
2. Load `~/.config/opencode/skills/terraform-provider/sdk-v2.md` for SDK v2 patterns (if applicable)
3. Load `~/.config/opencode/skills/terraform-provider/schema-design.md` for attribute semantics
4. Load `~/.config/opencode/skills/terraform-provider/features/acceptance-testing.md` for test coverage

## Checklist

- Schema uses correct type (Framework attribute vs SDK v2)
- Required/Optional/Computed semantics correct
- Plan modifiers present where needed (RequiresReplace, UseStateForUnknown)
- CRUD lifecycle handles all states (create, read, update, delete)
- Read handles 404 (removes from state)
- Delete handles already-deleted (idempotent)
- ImportState implemented
- Acceptance tests cover basic, update, and import scenarios
- Sweepers configured for cleanup
