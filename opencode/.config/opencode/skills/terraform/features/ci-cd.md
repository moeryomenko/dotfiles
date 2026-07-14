# CI/CD Pipeline Architecture

Terraform/OpenTofu CI/CD pipeline patterns, artifact management, approval workflows, and drift detection.

## Pipeline Architecture

### Standard Stages

```
[Validate] -> [Test] -> [Security Scan] -> [Plan] -> [Approve] -> [Apply] -> [Verify]
```

### Stage Details

| Stage | Commands | Gates | Artifacts |
|-------|----------|-------|-----------|
| Validate | `terraform fmt -check`, `terraform validate`, `tflint` | All pass | Formatted config |
| Test | `terraform test` (1.6+), or Terratest | All pass | Test report |
| Security | `trivy config .`, `checkov -d .` | Zero critical/high | Scan report |
| Plan | `terraform plan -out=plan.tfplan` | No errors | Plan artifact |
| Approve | Manual or auto (env-dependent) | Approval gate | Approval record |
| Apply | `terraform apply plan.tfplan` | Plan hash matches | Updated state |
| Verify | `terraform plan` shows no changes | Zero diff | Drift report |

### Plan Artifact Integrity

```yaml
# CI pipeline — plan stage
- name: Plan
  run: |
    terraform plan -out=plan.tfplan
    sha256sum plan.tfplan > plan.tfplan.sha256

# CI pipeline — apply stage (separate job)
- name: Apply (reviewed plan only)
  run: |
    sha256sum -c plan.tfplan.sha256
    terraform apply plan.tfplan
```

## GitHub Actions Workflow

```yaml
name: Terraform
on:
  pull_request:
    paths: ['environments/prod/**']
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      - run: terraform fmt -check -recursive
      - run: terraform init
      - run: terraform validate
      - run: tflint --format=checkstyle

  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: terraform init
      - run: terraform plan -out=plan.tfplan
      - uses: actions/upload-artifact@v4
        with:
          name: plan
          path: plan.tfplan*

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: plan
      - run: sha256sum -c plan.tfplan.sha256
      - run: terraform init
      - run: terraform apply plan.tfplan
```

## Environment Protection

### Branch-Based Environment Mapping

| Branch | Environment | Apply trigger | Approval |
|--------|-------------|---------------|----------|
| `feature/*` | Dev | PR validation | None (plan only) |
| `main` | Staging | Auto on merge | CI auto-approve |
| `release/*` | Prod | Tagged release | Manual approval |

### Remote Backend Isolation

```hcl
# Root configuration selects backend based on workspace
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "${terraform.workspace}/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Drift Detection

### Scheduled Detection

```yaml
jobs:
  drift-detection:
    runs-on: ubuntu-latest
    schedule:
      - cron: '0 6 * * 1'  # Weekly on Monday
    steps:
      - run: terraform init
      - run: terraform plan -detailed-exitcode
      # Exit code 2 means drift detected
      - if: failure()
        run: echo "Drift detected in production"
```

### Remediation Workflow

1. Detection alerts via Slack/email/PagerDuty
2. Automated PR creation with `terraform plan` output
3. Review and apply through normal pipeline
4. Post-remediation verify zero drift

## Cost Control

### Cost Estimation Integration

```yaml
- name: Infracost
  run: |
    infracost breakdown --path=. --format=diff
  # Comment cost diff on PR
```

### Resource Tagging for Cost Tracking

```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
    Project     = var.project_name
  }
}

resource "aws_instance" "web" {
  tags = merge(local.common_tags, {
    Name = "${var.name}-web"
  })
}
```

### Auto-Cleanup

```yaml
# Scheduled cleanup for non-production environments
- name: Schedule Destroy
  if: github.ref != 'refs/heads/main'
  run: |
    echo "destroy_after=$(date -d '+24 hours' +%s)" >> $GITHUB_ENV

- name: Auto Destroy
  if: env.destroy_after
  run: |
    export TF_VAR_auto_destroy=true
    terraform destroy -auto-approve
```
