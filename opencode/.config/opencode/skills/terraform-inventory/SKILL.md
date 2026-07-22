---
name: terraform-inventory
description: terraform-inventory tool development — state parsing and Ansible inventory generation. Auto-load when go.mod references terraform-inventory.
invocation_policy: automatic
---

# Terraform Inventory Skill

Knowledge base for developing `terraform-inventory` — a dynamic Ansible inventory generator from Terraform state files.

## Configuration

The Inventory skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### State File Parsing
When working with Terraform state file parsing:
1. Load `features/state-parsing.md` for format versions, module structure, resource extraction

### Inventory Generation
When generating Ansible inventory from state:
1. Load `features/inventory-format.md` for JSON/INI output, group structure, host vars

### Testing
When writing or debugging inventory tests:
1. Load `features/testing.md` for test fixtures, CLI testing patterns

## Cross-Referencing

For general Terraform state file format, reference `terraform/features/state-management.md`. For Go patterns, reference the `go/` skill.
