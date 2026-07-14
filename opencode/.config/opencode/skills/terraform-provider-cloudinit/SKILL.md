---
name: terraform-provider-cloudinit
description: Terraform CloudInit provider development. Auto-load when working on cloudinit-related provider code. Covers MIME multipart generation, resource/data source design, and testing patterns.
invocation_policy: automatic
---

# Terraform Provider CloudInit Skill

Knowledge base for developing `terraform-provider-cloudinit` using the Terraform Plugin Framework. Covers MIME message generation, resource/data source design patterns, and testing.

## Configuration

The CloudInit provider skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Key Architecture

- Uses **Plugin Framework** (not SDK v2)
- One provider type: `cloudinit`
- No configuration needed (`Configure` is empty)
- One resource (`cloudinit_config`, deprecated)
- One data source (`cloudinit_config`) — preferred
- Resource and data source share the same rendering logic

## Capabilities

### MIME Message Generation
When working with cloud-init configuration rendering:
1. Load `features/mime-generation.md` for MIME multipart structure, part merging, content handling

### Resource & Data Source Design
When implementing resources/data sources:
1. Load `features/resource-design.md` for shared model patterns, lifecycle, schema design

## Cross-Referencing

For general Plugin Framework patterns, reference `terraform-provider/`.
