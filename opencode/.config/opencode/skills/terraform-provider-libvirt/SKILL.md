---
name: terraform-provider-libvirt
description: Libvirt Terraform provider development. Auto-load in internal/libvirt/ or internal/codegen/ directories. Covers XML mapping, codegen pipeline, network transports, and RNG schema compliance.
invocation_policy: automatic
---

# Terraform Provider Libvirt Skill

Knowledge base for developing `terraform-provider-libvirt` using the Terraform Plugin Framework. Covers the codegen pipeline, XML schema mapping, connection transports, and review conventions.

## Configuration

The Libvirt provider skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Key Policies (from AGENTS.md)

- **RNG Schemas First**: Consult `/usr/share/libvirt/schemas/*.rng` before implementing schema
- **Nested Attributes Only**: `SingleNestedAttribute` / `ListNestedAttribute` — blocks forbidden for new code
- **Field Read Semantics**: Computed-only = always read; Optional = only populate if user specified; Required = always in state
- **No Magic Numbers**: Use `golibvirt.DomainRunning` etc.
- **Generated Code is gitignored**: Always run `make generate` before building/testing
- **Test files not gitignored**: Test files in `internal/generated/` are NOT gitignored — only `*.gen.go` files are. Committed test fixtures coexist with generated test code.
- **Libvirt Normalizes Values**: e.g., `q35` -> `pc-q35-10.1` — preserve user input on readback

## Capabilities

### Codegen Pipeline
When working with the code generation system:
1. Load `technical-patterns.md` for the full pipeline (reflection -> IR -> templates)

### XML Schema & RNG
When implementing XML-to-HCL mapping:
1. Load `features/rng-schemas.md` for RNG schema consultation and XML mapping rules

### Resource Implementation
When implementing resources:
1. Load `features/domain-resources.md` for domain resource patterns
2. For other resources, reference `technical-patterns.md` for general patterns

### Network Transport
When working with connection dialers:
1. Load `features/network-transport.md` for dialer options

### Code Review
When reviewing libvirt provider code:
1. Load `review-core.md` for the review checklist
2. Load `false-positive-guide.md` for libvirt-specific false positives

## Cross-Referencing

For general Plugin Framework patterns, reference `terraform-provider/`. For Go patterns, reference the `go/` skill.
