# False Positive Guide — Terraform/OpenTofu Review

Patterns that look wrong during review but are correct, intentional, or acceptable. Use this guide during structured reviews to avoid flagging legitimate code.

## 1. Inline Blocks vs Separate Resources

**What looks wrong**: Using inline `ingress`/`egress` blocks in `aws_security_group` instead of separate `aws_vpc_security_group_{ingress,egress}_rule` resources.

**Why it may be correct**: Inline blocks are simpler for small, static security groups. Separate rule resources are the modern recommended pattern (AWS provider v5+) for dynamic rules, but inline blocks remain valid for stable, simple configurations. The provider maintains backward compatibility.

**When to flag only**: If rules are managed by multiple teams, or rules change dynamically (inline blocks cause all rules to be re-sent on every change).

## 2. `count` for Boolean Toggle

**What looks wrong**: Using `count = var.create ? 1 : 0` instead of a conditional resource approach.

**Why it's correct**: This is the idiomatic Terraform pattern for optional resources. The ternary `count` expression is the standard way to conditionally create a resource. Avoid `for_each` on a single-element map for toggles.

**When to flag only**: If multiple resources use the same toggle and should be created/destroyed together — consider a module with a single toggle.

## 3. `depends_on` on Almost Every Resource

**What looks wrong**: Explicit `depends_on` on most or all resources suggests implicit dependencies are missing.

**Why it may be correct**: Some dependencies are not captured by interpolation references — for example, IAM policies applied to a role that downstream resources assume. In these cases `depends_on` is necessary and correct.

**When to flag only**: If `depends_on` duplicates what implicit references already express, or if it's used on every resource in a module as a blanket workaround.

## 4. `lifecycle { ignore_changes }` Blocker

**What looks wrong**: `ignore_changes = all` or ignoring critical fields (e.g., `ami`, `instance_type`).

**Why it may be correct**: Resources like `aws_autoscaling_group` naturally mutate `desired_capacity`. `ignore_changes` on certain fields is intentional for auto-scaling, scheduled actions, or external management. `ignore_changes = all` is acceptable for resources managed entirely outside Terraform where Terraform only tracks metadata.

**When to flag only**: If `ignore_changes` hides drift that operators should see, or if it's used as a blanket workaround for schema issues rather than a deliberate design choice.

## 5. Local State in Single-User Scenarios

**What looks wrong**: `backend "local"` in a Terraform project.

**Why it may be correct**: For personal infrastructure or prototypes where only one person runs Terraform, local state is acceptable. The hard "never use local state" rule applies to teams and production.

**When to flag only**: If the repo is shared, CI/CD is involved, or the user plans to collaborate.

## 6. `terraform_remote_state` for Cross-Module Access

**What looks wrong**: Using `terraform_remote_state` to read outputs from another component's state.

**Why it may be correct**: This is the intended mechanism for cross-module data access in Terraform. The data source reads the state file directly without creating managed resources. It's preferable to duplicating shared configuration.

**When to flag only**: If it creates tight coupling between independently deployable components, or if the remote state backend uses hardcoded access keys.

## 7. Provisioners (`local-exec`, `remote-exec`)

**What looks wrong**: Using provisioners at all — they're "a last resort" by Terraform's own documentation.

**Why it may be correct**: Some operations have no Terraform provider equivalent (e.g., registering a service with an external system, bootstrapping a cluster). Provisioners with `when = create` or `when = destroy` are acceptable for these cases.

**When to flag only**: If a native provider resource exists for the same operation, or if provisioners are used for routine configuration management instead of a dedicated tool (Ansible, Salt, etc.).

## 8. `sensitive = true` on Outputs

**What looks wrong**: Marking outputs as sensitive in modules hides values from users.

**Why it's correct**: If an output contains any secret material (connection strings, private keys, generated passwords), `sensitive = true` prevents accidental leakage in logs, CI output, and state file reads. The user can still access the value with `terraform output -json` when needed.

**When to flag only**: If applied to all outputs indiscriminately, or if applied to non-sensitive values like resource IDs that users need for other tools.

## 9. `file()` and `templatefile()` in Plan

**What looks wrong**: Calling `file(path)` or `templatefile(path, vars)` directly in a `.tf` file.

**Why it's correct**: These functions are evaluated during plan, and the files are read relative to the module directory. This is the standard pattern for injecting file content into Terraform resources (user_data, policy documents).

**When to flag only**: If the file path uses a relative path that breaks when the module is called from a different working directory, or if `templatefile()` is used where a provider data source exists.

## 10. `for_each` on `toset()` of List

**What looks wrong**: `for_each = toset(var.items)` converting a list to a set.

**Why it's correct**: `for_each` requires a map or set of strings. `toset()` is the standard conversion for list inputs. The deduplication behavior is usually intentional — duplicate list items would create conflicting resource addresses.

**When to flag only**: If the order of items matters and duplicates are semantically distinct (unlikely — use `count + index` for ordered items).

## 11. Cross-Provider Resource References

**What looks wrong**: Referencing attributes from one provider's resources in another provider's resource.

**Why it's correct**: Terraform's graph engine handles cross-provider dependencies naturally. For example, referencing `azurerm_resource_group.main.location` in `aws_vpc.main` is valid as long as both providers are configured. The graph engine ensures correct ordering.

**When to flag only**: If it creates a deployment ordering constraint that can't be satisfied (e.g., resources from two providers must exist in different regions and each requires the other's region-specific output).

## 12. Using `data` Sources for Resources Created by the Same Config

**What looks wrong**: Using a data source to read a resource that was just created by a resource block in the same configuration.

**Why it's correct**: This is valid for reading additional attributes that the resource doesn't export directly in its attributes. Terraform handles the dependency ordering. Common patterns: reading `aws_subnets` after creating a VPC with specific tags.

**When to flag only**: If the data source depends on side effects that only exist after apply but is used during plan (computed `data` sources defer to apply).
