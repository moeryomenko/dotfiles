---
name: packer-infra
description: "Infrastructure and CI/CD around Packer VM builds. Covers HCP Packer Registry integration, artifact management, automated build pipelines, multi-platform orchestration, image versioning and rollout strategies."
invocation_policy: automatic
---

# Packer Infrastructure & CI/CD Skill

Infrastructure and CI/CD around Packer VM builds. Covers HCP Packer Registry integration, artifact management, automated build pipelines, multi-platform orchestration, image versioning and rollout strategies.

This skill complements the user-facing [packer-hcl](packer-hcl/SKILL.md) and [packer-vm-baking](packer-vm-baking/SKILL.md) skills.
It focuses on the operational layer around Packer builds:

- **CI/CD pipeline design** for automated image builds
- **HCP Packer Registry** integration for image lifecycle management
- **Artifact management** (storage, cleanup, promotion between environments)
- **Multi-platform orchestration** (cross-cloud, cross-region builds)
- **Image versioning strategies** and rollout workflows

## Configuration

The Packer Infrastructure skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### CI/CD & Automation

When designing or reviewing CI/CD pipelines for Packer image builds:
1. Load `features/ci-cd-and-automation.md` for pipeline architecture, trigger strategies, build orchestration, artifact management, and rollout workflows

### HCP Packer Registry

When integrating with HCP Packer Registry for image lifecycle management:
1. Load `features/hcp-packer-registry.md` for registry integration, channel management, versioning strategies, and metadata handling

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.

For Packer HCL template design and provisioning, reference [packer-hcl](../packer-hcl/SKILL.md) and [packer-vm-baking](../packer-vm-baking/SKILL.md).

For Go tooling that wraps Packer builds (custom builders, provisioners, post-processors), reference the [Go skill](../go/SKILL.md).
