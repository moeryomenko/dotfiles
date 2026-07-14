# Terraform/OpenTofu Technical Patterns

Core technical knowledge for reviewing and developing Terraform/OpenTofu configurations. Covers the execution model, dependency graph, state lifecycle, and provider resolution.

## Execution Model

### Phases
Terraform/OpenTofu executes in two distinct phases:

1. **Init** — Provider and module installation, backend configuration, dependency lock file generation
2. **Plan/Apply cycle**:
   - **Validate** — Static validation of HCL syntax and types
   - **Refresh** — Read current state of managed resources
   - **Plan** — Calculate diff between current state and desired state
   - **Apply** — Execute the plan against real infrastructure

### Plan Structure
A plan is a serialised diff containing:
- **Resource changes** — create, update, delete, replace, read, no-op
- **Output changes** — before/after values
- **Metadata** — version, terraform version, provider schemas

### Apply Semantics
- Creates or updates resources in dependency order
- On failure: Terraform marks resources as `tainted` (protocol v5) or records partial state (protocol v6+)
- `-target` limits scope but disables `create_before_destroy` for unselected dependents

## Dependency Graph

### Graph Construction
- Built from `resource` and `data` references in HCL
- `depends_on` adds explicit edges (use sparingly — prefer implicit references)
- `count`/`for_each` expansion happens during graph walk via `GraphNodeDynamicExpandable`
- Module tree is flattened into the graph — module boundaries don't restrict dependencies

### Graph Walk
- Topological order: resources are created/updated in dependency order
- Independent resources can be processed in parallel (provisioner-defined)
- `destroy` walks in reverse dependency order
- Cycle detection: Terraform reports cycles during plan with the node chain

### Dynamic Expansion
- Resources with `count` or `for_each` are expanded at walk time
- `count.index` and `each.value` are resolved per-instance
- Each instance becomes a separate graph node with a unique address
- Address format: `resource_type.resource_name[index]` (numeric) or `resource_type.resource_name["key"]` (string)

## State Lifecycle

### State File Format (0.12+)
```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 42,
  "lineage": "uuid",
  "outputs": {},
  "resources": [
    {
      "module": "root.module_name",
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"].us-east-1",
      "instances": [
        {
          "index_key": 0,
          "schema_version": 1,
          "attributes": {},
          "private": "base64",
          "dependencies": ["aws_vpc.main"]
        }
      ]
    }
  ],
  "check_results": null
}
```

### State Operations
- **Refresh**: Reads real-world state and updates the state file
- **Plan**: Compares state to config, produces diff
- **Apply**: Persists new state after mutations
- **State storage**: Backend abstraction (local file, S3, GCS, AzureRM, etc.)
- **Locking**: Prevents concurrent writes; native lock-file (S3, 1.10+) or DynamoDB

### State Migration Patterns
- **Backend migration**: `terraform init -migrate-state`
- **State refactoring**: `terraform state mv` or `moved` blocks
- **Resource removal**: `terraform state rm` or `removed` blocks (1.7+)
- **Import**: `terraform import` or `import` blocks (1.5+)

## Provider Resolution

### Discovery Order
1. `required_providers` in `versions.tf` or root module
2. Local `.terraform/providers/` cache
3. Provider registry (registry.terraform.io by default)
4. Provider mirror (if configured)

### Version Constraint Format
- `= 1.2.3` — exact version
- `~> 1.2` — any 1.x version >= 1.2 (pessimistic constraint)
- `>= 1.2, < 2.0` — range
- `~> 1.2.3` — any 1.2.x version >= 1.2.3

### Plugin Protocol
- Protocol v5: legacy gRPC protocol
- Protocol v6: current gRPC protocol (Framework providers use v6)
- Providers are executed as separate processes, communicating via gRPC over Unix sockets
- Provider processes are started on `init` and cached for the duration of the run

## Evaluation Model

### HCL Expression Evaluation
- Expressions are evaluated at graph-walk time, not config-load time
- `count` and `for_each` must resolve at plan time
- `try()` and `can()` handle dynamic type failures gracefully
- `templatefile()` evaluated during plan
- `file()` and `filebase64()` evaluated during plan (file must exist)

### Type System
- Primitive types: `string`, `number`, `bool`
- Collection types: `list(<type>)`, `map(<type>)`, `set(<type>)`
- Structural types: `object({...})`, `tuple([...])`
- `any` type constraint: accepts any type, suppresses type checking
- `optional()` with typed defaults preferred over `any` for flexibility

## OpenTofu-Specific Differences

| Feature | Terraform | OpenTofu |
|---------|-----------|----------|
| State encryption | Not available | `internal/encryption/` |
| OCI registry | Not available | `internal/oci/` for provider distribution |
| Experimental engine | Not available | `internal/engine/` (gated by `TOFU_X_EXPERIMENTAL_RUNTIME=1`) |
| License | BUSL-1.1 | MPL-2.0 |
| Contribution policy | CLA + AI-assisted PRs marked with `:robot:` | DCO sign-off, NO LLM-generated contributions |

## Backend Protocol Rules

- Only `local` and `remote`/`cloud` backeds execute operations
- All other backends (S3, GCS, AzureRM, etc.) only store state
- Backend configuration is static — no interpolation in `backend "type"` blocks
- Partial backend configuration allows environment-specific state paths
