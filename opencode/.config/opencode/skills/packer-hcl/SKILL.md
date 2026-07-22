---
name: packer-hcl
description: Packer HCL2 template authoring. Load when working with .pkr.hcl files. Covers template syntax (variable/locals/source/build blocks), HCL2 type system, provisioners, post-processors, and template organization patterns.
invocation_policy: automatic
---

# Packer HCL2 Template Authoring Skill

Packer HCL2 template skill: structured reference for authoring, organizing, and maintaining `.pkr.hcl` templates. Covers template syntax, the HCL2 type system, provisioner and post-processor configuration, and multi-source/build orchestration patterns.

## Configuration

The Packer HCL skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Template Syntax & Structure
When authoring or reviewing `.pkr.hcl` templates, defining variables/locals/source/build blocks, or configuring HCL2 type constraints:
1. Load `features/template-syntax.md` for block structure, variable declarations, locals, source definitions, build orchestration, and HCL2 type system reference

### Provisioners & Post-Processors
When configuring provisioner blocks (shell, file, ansible, chef, puppet, powershell, windows-restart, custom), post-processor pipelines (docker-tag, docker-push, manifest, vagrant, compress, shell-local, artifacts), or debug workflows:
1. Load `features/provisioners-post-processors.md` for provisioner reference, post-processor pipelines, ordering, retry strategy, and error handling

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.

- **packer-vm-baking** — Use when building and customizing VM images with Packer, covering OS install, hardening, pre-installed tooling, and golden image lifecycle
- **packer-infra** — Use when integrating Packer builds into infrastructure pipelines, covering CI/CD, artifact management, image registry workflows, and multi-region deployment
- **go** — Use when developing custom Packer plugins, provisioners, post-processors, or data sources in Go
