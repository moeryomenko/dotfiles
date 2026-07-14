# Module Design Patterns

Development-side knowledge for Terraform/OpenTofu module structure, tree resolution, and registry contracts.

## Module Hierarchy

### Three-Level Model

1. **Resource module** — Single logical group (VPC + subnets, SG + rules)
2. **Infrastructure module** — Collection of resource modules for one purpose (networking, compute)
3. **Composition** — Complete infrastructure spanning regions/accounts

### Directory Layout

```
modules/
├── networking/         # Infrastructure module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── modules/
│       ├── vpc/        # Resource module
│       └── subnets/    # Resource module
environments/
├── prod/
│   ├── main.tf         # Composition
│   └── terraform.tfvars
└── staging/
```

## Module Tree Resolution

### Root Module
- Must contain `terraform {}` block with backend configuration
- Providers configured at root level propagate to child modules
- Root module providers are inherited by all children

### Child Module Provider Passing

```hcl
# Root module
provider "aws" {
  region = "us-east-1"
  alias  = "us_east"
}

module "vpc" {
  source = "./modules/networking"
  providers = {
    aws = aws.us_east    # explicit provider passing
  }
}
```

### Module Contract Rules

**Variables (inputs):**
- Always `description`, always explicit `type`
- Use `validation` for complex constraints
- `sensitive = true` for secrets
- `optional()` with typed defaults (1.3+) over `map(any)`
- No provider configuration in modules — use provider alias passing

**Outputs (contracts):**
- Always `description`
- Mark sensitive outputs
- Expose stable subsets — not whole provider objects
- Prefer specific attributes over entire resource references

```hcl
# Good — stable subset
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Avoid — exposes entire resource with potential for misuse
output "vpc" {
  value = aws_vpc.main
}
```

## Versioning & Registry

### Module Version Constraints

| Use case | Constraint | Example |
|----------|-----------|---------|
| Production | Exact | `version = "5.1.2"` |
| Development | Patch range | `version = "~> 5.1"` |
| CI/CD | Minor range | `version = "~> 5.0"` |

### Registry Module Structure

```
terraform-<provider>-<name>/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── examples/
│   ├── minimal/
│   └── complete/
└── tests/
```

Naming convention: `terraform-<PROVIDER>-<NAME>` for public registry.

## Remote State References

### `terraform_remote_state` Best Practices

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-state"
    key    = "prod/networking/terraform.tfstate"
    region = "us-east-1"
  }
  default = { vpc_id = "", subnet_ids = [] }
}
```

- Use `default` to make the data source available at plan time (1.3+)
- Pin the config — dynamic backend keys break state resolution
- Read-only access: `terraform_remote_state` never creates or modifies resources
- Document the coupling — explicitly note which component depends on which

### When to Use Remote State vs Data Sources

| Scenario | Approach | Rationale |
|----------|----------|-----------|
| Same component, different module | Direct output reference | Module is deployed together |
| Different component, stable API | `terraform_remote_state` | Decoupled deployment cadence |
| Cloud API with read support | `aws_*` data source | No state coupling |
| Cross-account reference | `terraform_remote_state` with IAM role | Required when no direct API exists |

## Module Anti-Patterns

### Provider Configuration in Modules

```hcl
# AVOID — configures provider inside module
provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.role_arn
  }
}

# PREFER — provider alias passing from root
provider "aws" {
  alias = "child"
  # ...configuration
}
```

### Forcing Root Module Concerns

```hcl
# AVOID — module dictates its own backend
terraform {
  backend "s3" {
    # ...
  }
}

# PREFER — root module dictates backend, module is portable
# (no terraform block in reusable modules)
```

### Over-Abstracting

- Don't create modules for single-resource wrappers (module wrapping one `aws_instance` is over-engineering)
- Don't expose every provider option as a module variable — use `dynamic` blocks for rare configuration
- Module should add value: composition, defaults, validation, or policy enforcement
