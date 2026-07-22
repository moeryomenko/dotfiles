# Security & Compliance Patterns

Provider permission models, state file hardening, policy engine patterns, and security scanning for Terraform/OpenTofu.

## Provider Permission Models

### Understanding Provider Access

```hcl
# AWS provider — least-privilege IAM
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT:role/TerraformRole"
  }
}
```

### Minimum Required Permissions per Provider

| Provider | Required actions | Recommendation |
|----------|-----------------|---------------|
| AWS | ec2:*, s3:*, iam:*, etc. (per resource) | Scoped IAM policy with resource-based conditions |
| Azure | Microsoft.Compute/*, Microsoft.Network/* | Scoped Azure RBAC role |
| GCP | compute.*, storage.* | Scoped IAM role with conditions |
| vSphere | Resource.Assign, VirtualMachine.* | vSphere role with datacenter scope |

### Permission Boundaries

```hcl
# AWS IAM role with permissions boundary
resource "aws_iam_role" "terraform" {
  name               = "TerraformRole"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  permissions_boundary = "arn:aws:iam::ACCOUNT:policy/TerraformBoundary"
}
```

## State File Security

### Attack Surface

| Vector | Risk | Mitigation |
|--------|------|------------|
| State file reading | Secret exposure | Encryption at rest, IAM restrictions |
| State file tampering | Infrastructure corruption | State locking, versioning |
| Unauthorized backend access | Full infrastructure control | Network ACLs, IAM roles |
| CI log leakage | Secret exposure | Mask plan output, sensitive variables |

### State Encryption

```hcl
# S3 backend with encryption
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true                    # SSE-S3
    kms_key_id     = "alias/terraform-state" # SSE-KMS
    use_lockfile   = true                    # Native locking (1.10+)
  }
}
```

### OpenTofu State Encryption (1.6+)

```hcl
# OpenTofu — encrypt state file with AES-GCM
terraform {
  backend "s3" {
    # ...
  }
  encryption {
    key_provider "pbkdf2" "default" {
      passphrase = "encryption-key"
    }
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.default
    }
    state {
      method = method.aes_gcm.default
      enforced = true
    }
  }
}
```

## Secrets Management

### Avoiding Secret Leakage

```hcl
# BAD — secret in variable default
variable "db_password" {
  default = "supersecret123"
}

# BAD — secret in tfvars
# terraform.tfvars
db_password = "supersecret123"

# GOOD — sourced from runtime
variable "db_password" {
  type      = string
  sensitive = true
}
# Set via: export TF_VAR_db_password=$(aws secretsmanager get-secret-value ...)
```

### write_only Arguments (1.11+)

```hcl
# Terraform 1.11+ — secret never written to state
resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = "mysecret"
  # secret_string is write_only — not stored in state
}
```

### Provider-Level Secret Handling

```hcl
# AWS provider — no hardcoded credentials
provider "aws" {
  # Uses env vars: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
  # Or: aws configure (shared credentials file)
  # Or: IAM instance profile (EC2)
}

# Azure provider — OIDC for CI
provider "azurerm" {
  use_oidc = true
  oidc_request_token  = var.actions_id_token_request_token
  oidc_request_url    = var.actions_id_token_request_url
}
```

## Security Scanning

### Trivy Configuration

```yaml
# .trivy.yaml
severity: CRITICAL,HIGH
skip-dirs:
  - .terraform/
  - .git/
```

```bash
trivy config --severity CRITICAL,HIGH --exit-code 1 .
```

### Checkov Configuration

```yaml
# .checkov.yaml
quiet: true
skip-check:
  - CKV_AWS_88  # Public EC2 (if intentional)
compact: true
```

```bash
checkov -d . --config-file .checkov.yaml
```

### Common Security Issues

| Issue | Checkov ID | Trivy ID | Fix |
|-------|-----------|---------|-----|
| S3 bucket public access | CKV_AWS_53 | AVD-AWS-0086 | `acl = "private"` |
| Security group open to world | CKV_AWS_24 | AVD-AWS-0102 | Restrict `cidr_blocks` |
| Unencrypted RDS | CKV_AWS_16 | AVD-AWS-0080 | `storage_encrypted = true` |
| Unencrypted EBS | CKV_AWS_47 | AVD-AWS-0027 | `encrypted = true` |
| IAM policy wildcard | CKV_AWS_63 | AVD-AWS-0057 | Scope `Resource` and `Action` |
| Plaintext secrets in variables | CKV_SECRET_1 | — | Use secret manager |
| Missing HTTP->HTTPS redirect | CKV_AWS_43 | AVD-AWS-0054 | `redirect { protocol = "https" }` |

## Policy as Code

### Open Policy Agent (OPA/Rego)

```rego
# terraform.rego — enforce tagging
package terraform

deny[msg] {
  resource := input.resource.aws_instance[_]
  not resource.tags.ManagedBy
  msg = sprintf("%v must have ManagedBy tag", [resource.address])
}
```

```bash
# Check with OPA
opa eval --data policies/terraform.rego --input plan.json "data.terraform.deny"
```

### Sentinel (Terraform Cloud)

```hcl
# sentinel.hcl
import "tfplan"

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.mode == "managed" implies has_tag(rc, "ManagedBy")
  }
}
```

## Compliance Frameworks

### Mapping Terraform Resources to Controls

| Framework | Key controls | Terraform patterns |
|-----------|-------------|-------------------|
| SOC 2 | Access control, encryption | IAM roles, S3 SSE, KMS |
| PCI DSS | Encryption, logging | RDS encryption, CloudTrail |
| HIPAA | Access control, audit | VPC endpoints, CloudWatch |
| ISO 27001 | Asset management | Resource tagging, inventory |

### Automated Compliance Checks

```hcl
# check block — runtime compliance assertion (1.5+)
check "compliance_encryption_check" {
  data "aws_s3_bucket" "all" {
    # ... iterate over buckets
  }

  assert {
    condition     = alltrue([for b in data.aws_s3_bucket.all : b.server_side_encryption_configuration[0].rule[0].apply_server_side_encryption_by_default[0].sse_algorithm != null])
    error_message = "All S3 buckets must have encryption enabled."
  }
}
```
