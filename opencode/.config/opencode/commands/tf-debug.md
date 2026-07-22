---
description: Debug Terraform/OpenTofu state issues, plan failures, and provider problems. Loads technical-patterns.md for execution model context and troubleshooting guidance.
agent: build
---

# /tf-debug — Troubleshoot Terraform/OpenTofu Issues

Debug Terraform/OpenTofu state issues, plan failures, provider problems, and unexpected behaviour.

## Usage

`/tf-debug <symptom> [context]`

## Workflow

1. Load `~/.config/opencode/skills/terraform/technical-patterns.md` for execution model and state lifecycle context
2. Diagnose the symptom:
   - Plan failure: check expression evaluation timing, count/for_each resolution, provider schema
   - State issue: check locking, serial conflicts, state file format
   - Provider error: check provider version, protocol compatibility, credentials
   - Unexpected diff: check ignore_changes, provider normalization, computed attributes
3. Propose fix with validation plan
4. Run `terraform plan` to verify fix

## Common Symptoms

| Symptom | Likely Causes | Diagnostic Steps |
|---------|--------------|------------------|
| Provider not found | Version constraint, registry issue, platform | Check `required_providers`, run `terraform providers` |
| State lock error | Concurrent operation, stale lock | Check state lock status, force unlock if stale |
| Count/for_each can't be evaluated | Expression depends on computed value | Check plan-time resolution rules |
| Unexpected resource replacement | Attribute changed, `create_before_destroy` not configured | Check plan diff, review lifecycle settings |
| Plan shows destroy for renamed resource | Missing `moved` block | Add `moved` block from old to new address |
| Secret visible in plan output | Not marked sensitive | Add `sensitive = true` to variable/output |
