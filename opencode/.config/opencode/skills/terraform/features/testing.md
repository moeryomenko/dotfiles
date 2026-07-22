# Testing Terraform/OpenTofu

Testing infrastructure for Terraform and OpenTofu configurations. Covers native test framework mechanics, mock providers, and integration testing patterns.

## Native Test Framework (1.6+)

### Test File Structure

```
tests/
├── defaults.tftest.hcl
├── with_mocks.tftest.hcl
└── fixtures/
    ├── minimal/
    └── complete/
```

### Test Runner

```bash
# Run all tests
terraform test
tofu test

# Run specific file
terraform test -filter=tests/defaults.tftest.hcl

# Verbose output
terraform test -verbose
```

### Test File Structure

```hcl
# tests/defaults.tftest.hcl
provider "aws" {
  region = "us-east-1"
}

run "defaults" {
  command = plan

  variables {
    name        = "test"
    enabled     = true
    environment = "test"
  }

  assert {
    condition     = aws_instance.web.tags["Name"] == "test-web"
    error_message = "Web instance tag mismatch"
  }
}

run "with_custom_config" {
  command = apply

  variables {
    name        = "custom"
    environment = "test"
    instance_type = "t3.large"
  }

  assert {
    condition     = aws_instance.web.instance_type == "t3.large"
    error_message = "Instance type not applied"
  }
}
```

### `command = plan` vs `command = apply`

| Aspect | `plan` | `apply` |
|--------|--------|---------|
| Speed | Fast | Slower (creates real resources) |
| Computed values | Unavailable | Available |
| Set-type evaluation | Indexing fails | Indexing works |
| Provider calls | `plan` only | Full CRUD |
| Use case | Input-derived logic | Output verification |

### Set-Type Nested Blocks

Set-type blocks cannot be indexed with `[0]` during plan — use `command = apply`:

```hcl
# This fails during plan (set-type, no stable index)
run "fails" {
  command = plan
  assert {
    condition     = aws_s3_bucket.main.rule[0].status == "Enabled"
    error_message = "..."
  }
}

# This works
run "works" {
  command = apply
  assert {
    condition     = one(aws_s3_bucket.main.rule[*].status) == "Enabled"
    error_message = "..."
  }
}
```

## Mock Providers (1.7+)

### Provider Mocking

Mock providers replace real provider calls with configurable responses:

```hcl
mock_provider "aws" {
  # All AWS calls return default zero values
}

run "test_with_mocks" {
  command = plan
  # Uses mock provider instead of real AWS
  assert {
    condition     = aws_instance.web.tags["Name"] == "test-web"
    error_message = "..."
  }
}
```

### Mock Override Pattern

```hcl
mock_provider "aws" {
  # Override specific resource read
  mock_resource "aws_instance" {
    defaults = {
      id             = "i-1234567890abcdef0"
      instance_type  = "t2.micro"
      private_ip     = "10.0.1.50"
    }
  }
}
```

### When to Use Mocks vs Real

| Scenario | Approach | Cost |
|----------|----------|------|
| Logic validation | Mock providers | Free |
| Computed attribute verification | Real providers (command = apply) | Resource cost |
| Security/Compliance checks | Static analysis (trivy, checkov) | Free |
| Full integration test | Real providers (Terratest) | Highest cost |

## Terratest Integration Testing

### Go Test Structure

```go
func TestTerraformModule(t *testing.T) {
  terraformOptions := &terraform.Options{
    TerraformDir: "../examples/complete",
    Vars: map[string]interface{}{
      "name": "test-module",
    },
  }

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  output := terraform.Output(t, terraformOptions, "instance_id")
  assert.NotEmpty(t, output)
}
```

### Terratest Best Practices

- Use `examples/` as test fixtures — they serve dual purpose as docs
- Always call `terraform.Destroy` in defer
- Tag test resources for cleanup
- Use `terraform.InitAndApply` over separate Init + Apply calls
- Set `TF_VAR_` environment variables for sensitive test inputs
- Group related tests into test suites

## Static Analysis Integration

### Pre-Commit Pipeline

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.96.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: tflint
      - id: terraform_docs
      - id: terraform_trivy
```

### Tool-Specific Configs

```yaml
# .tflint.hcl
plugin "aws" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

### LLM Mistake Checklist

Common AI-generated Terraform test mistakes:

1. Indexing set-type blocks with `[0]` during plan — always fails
2. Using `terraform test` with `command = apply` for everything — unnecessarily slow
3. Forgetting to set `mock_provider` at the file level before individual `run` blocks
4. Asserting computed values during plan — they're unknown until apply
5. Not cleaning up test resources in Terratest (missing `defer terraform.Destroy`)
6. Using `sleep` or `wait` in tests instead of proper retry/dependency patterns
