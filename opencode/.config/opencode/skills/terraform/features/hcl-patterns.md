# HCL Patterns for Terraform/OpenTofu

HCL evaluation semantics, expression behaviour, and type-system patterns for Terraform and OpenTofu. This covers development-side knowledge — how HCL works, not how to write it.

## Expression Evaluation Timing

### Plan-Time vs Apply-Time Resolution

| Resolution time | Expression types | Notes |
|----------------|-----------------|-------|
| **Plan time** | `count`, `for_each`, `try()`, `can()`, `templatefile()`, `file()`, `filebase64()`, `lookup()`, `length()` | Must resolve without the final applied state |
| **Apply time** | Computed attributes (ARNs, IDs, generated names), data source reads with `depends_on`, `templatefile` inside provisioners | Requires resources to exist |

### Key Semantic Rules

- `count` and `for_each` must resolve at plan time — they determine the graph structure
- A resource with `count = 0` is a dynamic expansion that produces zero instances
- `try()` returns `null` for undefined attribute access, but throws for invalid operations (arithmetic on wrong type)
- `templatefile()` is evaluated during plan, but the file content is static — it cannot use computed attributes
- `filebase64sha256()` is evaluated during plan — the file must exist on disk

## Type System Behaviour

### Type Constraints

```hcl
variable "example" {
  type = object({
    name    = string           # required
    tags    = optional(map(string), {})  # optional with default (1.3+)
    enabled = optional(bool, true)
  })
}
```

### Conversion Rules

- `string` to `number`: automatic for numeric strings in arithmetic contexts
- `number` to `string`: automatic in string templates (`"${var.count}"`)
- `list` to `set`: explicit via `toset()` — deduplicates and loses order
- `tuple` to `list`: automatic conversion
- `object` to `map`: automatic when all attribute types are the same
- `null` handling: `nullable = false` (1.1+) prevents null overriding defaults
- `sensitive` values: masked in plan output, propagated through expressions

### `any` Type Pitfalls

```hcl
variable "bad" {
  type = map(any)  # flexible but no type enforcement — avoid
}

variable "good" {
  type = map(object({
    name = string
    port = number
  }))
}
```

Using `any` disables type checking and defers validation to runtime. Prefer explicit structural types with `optional()`.

## Expression Idioms

### Safe Fallback Pattern

```hcl
# Instead of: element(concat(var.list, [""]), 0)
local.first = try(var.list[0], "")
```

### Conditional Default with Null

```hcl
# Null-aware default with nullable=false
variable "name" {
  type        = string
  default     = "default-name"
  nullable    = false   # (1.1+) prevents null override
  validation {
    condition     = length(var.name) > 0
    error_message = "Name must not be empty."
  }
}
```

### Cross-Variable Validation (1.9+)

```hcl
variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
  validation {
    condition     = tonumber(split("/", var.subnet_cidr)[1]) > tonumber(split("/", var.vpc_cidr)[1])
    error_message = "Subnet prefix must be shorter than VPC prefix."
  }
}
```

## Module Resolution

### Resolution Order
1. Local module paths (`./modules/`, `../modules/`) — resolved by file existence
2. Registry modules (`terraform-aws-modules/vpc/aws`) — resolved via registry API
3. Git/HTTP modules — resolved via `git clone` or HTTP download

### Source Types

| Source | Format | Version support |
|--------|--------|-----------------|
| Local path | `./modules/networking` | N/A |
| Registry | `hashicorp/subnets/cidr` | `version = "~> 1.0"` |
| GitHub | `github.com/org/repo//path` | `ref = "v1.0.0"` |
| Generic Git | `git::https://example.com/repo.git` | `ref = "v1.0.0"` |
| HTTP | `https://example.com/module.tar.gz` | N/A |
| S3 | `s3::https://s3-...` | N/A |
| GCS | `gcs::https://www.googleapis.com/...` | N/A |

## Version Compatibility

| HCL Feature | Min Terraform | Min OpenTofu |
|-------------|---------------|--------------|
| `optional()` with defaults | 1.3 | 1.6 |
| `nullable = false` | 1.1 | 1.6 |
| `moved` blocks | 1.1 | 1.6 |
| `import` blocks | 1.5 | 1.6 |
| `check` blocks | 1.5 | 1.6 |
| `removed` blocks | 1.7 | 1.7 |
| Cross-variable validation | 1.9 | 1.7 |
| Provider-defined functions | 1.8 | 1.7 |
| `write_only` arguments | 1.11 | — |
