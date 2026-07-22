---
name: packer-vm-baking
description: "QEMU/KVM VM image baking patterns with Packer. Covers golden image strategy, QEMU-specific boot command/keyboard automation via VNC, preseed/kickstart/cloud-init, QEMU disk management, and image testing."
invocation_policy: automatic
---

# Packer QEMU/KVM VM Baking Skill

QEMU/KVM-focused VM image baking patterns using Packer. This skill covers the full lifecycle of building golden VM images with the QEMU builder: from boot automation and provisioning through post-processing and image testing.

For general HCL authoring patterns, variables, sources, and template structure, use the `packer-hcl` skill. For infrastructure provisioning and CI/CD pipeline patterns around Packer builds, use the `packer-infra` skill.

## Configuration

The packer-vm-baking skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### QEMU Golden Image Patterns
When designing golden image workflows, image versioning, or multi-distribution matrix builds:
1. Load `features/golden-image-patterns.md` for image lifecycle strategy, QEMU disk provisioning, Ansible integration, cleanup before sealing, and image minimization

### QEMU Boot & Automation
When configuring boot commands, keyboard automation via VNC, preseed/kickstart/cloud-init/autoinstall, or QEMU-specific boot quirks:
1. Load `features/boot-and-automation.md` for boot_command key encoding, VNC sendkey mapping, boot wait timing, EFI/BIOS boot differences, preseed/kickstart configuration, and cloud-init datasource seeding

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics.

- **packer-hcl** — For general HCL authoring patterns, source/variable/output contracts, build block structure, and template organization
- **packer-infra** — For CI/CD pipeline integration, artifact storage, build orchestration, and infrastructure for running Packer builds
- **packer-qemu** — For QEMU builder-specific configuration details, accelerator tuning, and platform-specific QEMU options
- **go** — For developing or debugging custom Packer plugins, provisioners, or post-processors written in Go


