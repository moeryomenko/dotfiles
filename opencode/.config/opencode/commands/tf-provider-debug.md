---
description: Debug Terraform provider issues — schema errors, plan modifier problems, test failures.
agent: build
---

# /tf-provider-debug — Provider Debugging

Debug Terraform provider schema errors, plan modifier failures, and acceptance test issues.

## Usage

`/tf-provider-debug <symptom>`

## Workflow

1. Load `~/.config/opencode/skills/terraform-provider/schema-design.md` for attribute semantics
2. Diagnose based on symptom

## Common Symptoms

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Unsupported attribute" | Schema mismatch | Check attribute types in schema vs `tfsdk` struct tags |
| "Invalid combination of arguments" | Required/Optional/Computed mismatch | Check Required:true shouldn't also be Computed:true |
| "Value unchanged" | Missing plan modifier | Add `UseStateForUnknown` for computed values |
| "Planned state not matching" | State not set after mutation | Check `resp.State.Set` in Create/Update |
| "Provider not found" | Incorrect address | Check `providerserver.ServeOpts.Address` |
| "401/403 on API call" | Missing configure | Check `Configure` method sets up auth client |
