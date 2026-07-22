# Terraform/OpenTofu Review Core

Structured review checklist for Terraform and OpenTofu configurations. Use during code review to ensure correctness, maintainability, security, and performance.

## Before You Begin

1. **Identify the runtime** — `terraform` or `tofu`, exact version, provider versions
2. **Identify the execution path** — local plan, CI pipeline, Terraform Cloud/Atlantis
3. **Load context** — `technical-patterns.md` for execution model background
4. **Load false-positive guide** — `false-positive-guide.md` to avoid flagging acceptable patterns
5. **Check against terraform-skill** — for user-facing patterns (module design, variable contracts), reference the antonbabenko skill

## Checklist Categories

### 1. Structure & Organisation

- [ ] Directory layout follows standard patterns (`environments/`, `modules/`, `examples/`)
- [ ] Resource modules are single-responsibility (one logical group)
- [ ] Infrastructure modules compose resource modules
- [ ] Compositions span regions/accounts at the top level
- [ ] Standard file structure: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- [ ] `versions.tf` pins `required_version` and `required_providers`
- [ ] `.terraform.lock.hcl` is committed to VCS

### 2. Naming & Conventions

- [ ] Descriptive resource names (`aws_instance.web_server`, not `aws_instance.main`)
- [ ] `this` reserved for genuine singleton resources only
- [ ] Variables prefixed with context (`vpc_cidr_block`, not `cidr`)
- [ ] Outputs have `description` set
- [ ] Variable blocks use explicit `type`, `description`, `validation` where applicable
- [ ] Block ordering follows conventions (count/for_each first, then arguments, tags, depends_on, lifecycle)
- [ ] snake_case naming throughout

### 3. State Management

- [ ] Remote state backend configured (never local state in teams)
- [ ] Backend configuration uses partial config or environment variables (not hardcoded keys)
- [ ] State locking mechanism specified (native lock-file 1.10+ or DynamoDB)
- [ ] State organisation follows hybrid pattern (per-environment + per-component)
- [ ] `terraform_remote_state` data sources are version-pinned
- [ ] No plan output from local-only backend committed to VCS

### 4. State Impact & Blast Radius

- [ ] Each environment has independent state (no prod/staging sharing state)
- [ ] Component states are split by lifecycle cadence
- [ ] Destroy operations require explicit `plan -destroy` review
- [ ] No `-auto-approve` on destroy operations
- [ ] `moved` blocks are present for renamed resources (prevent destroy/recreate)
- [ ] `removed` blocks are present for intentionally removed resources (prevent orphaned state)
- [ ] Import blocks used for existing resources being brought under management

### 5. Security & Secrets

- [ ] No secrets in variables or `.tfvars` files
- [ ] Secrets sourced from cloud secret manager or `write_only` arguments (1.11+)
- [ ] No default VPC usage in AWS configurations
- [ ] Encryption at rest enforced for all data services
- [ ] TLS enforced for all endpoints
- [ ] Security groups use least-privilege rules
- [ ] Separate `aws_vpc_security_group_{ingress,egress}_rule` resources used (not inline blocks)
- [ ] IAM policies follow least-privilege
- [ ] `sensitive = true` on variables that contain secrets
- [ ] State file access is restricted and encrypted

### 6. Resource Identity & Lifecycle

- [ ] `for_each` used for resources that may be reordered or removed (stable addresses)
- [ ] `count` used only for boolean toggles or fixed sequential indices
- [ ] No list-index-based identity for resources that may change order
- [ ] `lifecycle` blocks present with `create_before_destroy` for zero-downtime deployments
- [ ] `prevent_destroy` set on critical infrastructure (databases, DNS zones)
- [ ] `ignore_changes` justified and scoped (not blanket `ignore_changes = all`)
- [ ] `create_before_destroy` is the default for replacement; `prevent_destroy` overrides for safety

### 7. Testing

- [ ] Native test files present for Terraform 1.6+/OpenTofu 1.6+
- [ ] Test structure covers:
  - `command = plan` for input-derived value verification
  - `command = apply` for computed value verification
- [ ] Set-type nested blocks tested with `command = apply` (can't index with `[0]`)
- [ ] Mock providers used for cost-free unit tests (1.7+)
- [ ] Static analysis tools configured (tflint, trivy, checkov)
- [ ] Acceptance tests exist for complex integrations (Terratest or equivalent)
- [ ] Test resources tagged for cleanup
- [ ] Test fixtures in `examples/` serve as both docs and test data

### 8. CI/CD Pipeline

- [ ] Pipeline stages: validate -> test -> plan -> apply
- [ ] Environment protection: manual approval for prod apply
- [ ] Plan artifact reviewed and pinned (re-planning not allowed in apply stage)
- [ ] Security scanning stage before plan
- [ ] Cost estimation stage before apply
- [ ] Provider and runtime versions pinned in CI
- [ ] Drift detection configured for production environments
- [ ] `terraform plan` runs on every PR; `terraform apply` only on merge to main

### 9. Version Management

- [ ] Provider versions pinned with `~>` (major version stability)
- [ ] Module versions pinned with exact version in production (`version = "5.1.2"`)
- [ ] Runtime version constrained with `~>` (minor version stability)
- [ ] Provider/runtime upgrades in separate PR from functional changes
- [ ] Feature usage is gated by version floor (e.g., `write_only` requires 1.11+)
- [ ] `.terraform.lock.hcl` committed and kept in sync

### 10. Module Contracts

- [ ] Variables have `description`, explicit `type`, and `validation` blocks for constraints
- [ ] Outputs have `description` and expose stable data subsets
- [ ] `sensitive = true` on outputs containing secret material
- [ ] Optional arguments use `optional()` with typed defaults (1.3+)
- [ ] Complex variable types use `object()` with `optional()` not `map(any)`
- [ ] No provider configuration passed through modules (use provider alias passing)
- [ ] `terraform_remote_state` used only for read-only cross-module data, not for tight coupling

## Output Format

For each review, produce a structured report:

```
## Review: <change description>

### Runtime
- terraform/tofu vX.Y.Z
- Providers: [list with versions]

### Findings
| # | Category | Severity | Finding | Evidence | Fix |
|---|----------|----------|---------|----------|-----|
| 1 | Security | HIGH | ... | line 42 | ... |

### Summary
- PASS items: N
- FAIL items: N
- WARN items: N
- Overall: APPROVED / REJECTED
```
