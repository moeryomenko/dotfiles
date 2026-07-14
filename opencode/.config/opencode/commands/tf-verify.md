---
description: Verify Terraform/OpenTofu changes after implementation. Runs structured verification against review-core.md checklist.
agent: build
---

# /tf-verify — Verify Terraform/OpenTofu Changes

Run structured verification after fixing Terraform/OpenTofu configuration issues.

## Usage

`/tf-verify [scope]`

## Workflow

1. Load `~/.config/opencode/skills/terraform/review-core.md` for verification criteria
2. Load `~/.config/opencode/skills/terraform/false-positive-guide.md` to verify fix didn't introduce new issues
3. Verify the fix:
   - Run `terraform fmt -check` for formatting
   - Run `terraform validate` for syntax and type correctness
   - Run `terraform plan` to confirm expected diff
   - Run security scan (trivy/checkov) if applicable
4. Check review-core checklist for any remaining issues
5. Run `terraform test` if test files exist

## Verification Checklist

- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] Plan diff shows only intended changes
- [ ] No new security findings (trivy/checkov)
- [ ] All moved/removed blocks are present for refactored resources
- [ ] State locking is configured
- [ ] Changes do not increase blast radius
- [ ] Test files pass (if present)
