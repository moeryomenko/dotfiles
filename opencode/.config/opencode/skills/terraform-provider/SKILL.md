---
name: terraform-provider
description: Terraform Plugin Framework and SDK v2 provider development. Auto-load when provider.go or internal/provider/ detected. Covers schema design, resource lifecycle, acceptance testing, and migration patterns.
invocation_policy: automatic
---

# Terraform Provider Development Skill

Knowledge base for developing Terraform providers using the Plugin Framework and maintaining legacy SDK v2 providers.

## Configuration

The Provider skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Plugin Framework Development
When implementing a new provider with terraform-plugin-framework:
1. Load `plugin-framework.md` for Framework types, resource server, Configure, and schema attributes
2. Load `schema-design.md` for attribute types, Computed/Optional/Required semantics, plan modifiers

### SDK v2 Maintenance
When maintaining or migrating legacy SDK v2 providers:
1. Load `sdk-v2.md` for helper/schema patterns, CRUD, CustomizeDiff
2. Load `schema-design.md` for schema patterns (cross-version)

### Resource & Data Source Implementation
When implementing resources or data sources:
1. Load `features/resource-patterns.md` for CRUD lifecycle, ImportState, plan modifiers
2. Load `features/data-source-patterns.md` for Read semantics, schema differences

### Acceptance Testing
When writing provider tests:
1. Load `features/acceptance-testing.md` for resource.Test, TF_ACC, sweepers, mock providers

### Code Review
When reviewing provider code:
1. Load `features/acceptance-testing.md` for testing patterns
2. Load `plugin-framework.md` for Framework conventions
3. Load `sdk-v2.md` for SDK v2 conventions

## Cross-Referencing

For general Terraform/OpenTofu HCL patterns, reference the `terraform/` skill. For core engine architecture, reference `terraform-core/`.
