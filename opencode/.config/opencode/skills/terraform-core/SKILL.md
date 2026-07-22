---
name: terraform-core
description: Terraform and OpenTofu core contribution patterns. Auto-load when working in internal/terraform/, internal/tofu/, or cmd/tofu/ directories. Covers graph engine, state, plans, backends, and provider resolution.
invocation_policy: automatic
---

# Terraform & OpenTofu Core Contribution Skill

Knowledge base for contributing to Terraform (BUSL-1.1) and OpenTofu (MPL-2.0) core codebases. Covers architecture, Go patterns, testing, and review guidelines.

## Configuration

The Core skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Alignment

This skill covers the internal engine architecture for both Terraform and OpenTofu.
Key policy rules from both codebases are incorporated throughout.

**IMPORTANT: OpenTofu does not accept LLM-generated contributions.** If working on OpenTofu,
inform the user of this policy before making any contribution. All code must be human-written.

The rationale for this policy: OpenTofu is an MPL-2.0 fork of Terraform (BUSL-1.1).
LLM-generated code may inadvertently reproduce BUSL-licensed patterns, creating legal risk
for the project. The consequence of submitting LLM-generated code is that the PR will not be
accepted, and repeated violations may lead to a ban from the project.

**Alternative**: Instead of LLM-generated code, open a GitHub issue describing the problem and
proposed approach. Community members and maintainers can discuss and implement solutions.

## Capabilities

### Core Architecture Reference
When understanding or modifying the core engine:
1. Load `technical-patterns.md` for graph engine, state, plans, backends, configs, provider resolution

### Go Patterns & Conventions
When implementing Go code in the core:
1. Load `features/go-patterns.md` for interface-based plugin model, graph walk, config loading pipeline

### Testing Infrastructure
When writing or debugging core tests:
1. Load `features/testing.md` for test helpers, mock providers, plan/apply test patterns

### Provider Resolution
When working with provider installation or registry protocol:
1. Load `features/provider-resolution.md` for installation, version resolution, provider cache

### Code Review
When reviewing core contributions:
1. Load `review-core.md` for the review checklist
2. Load `false-positive-guide.md` for core-specific false positives
3. Load `technical-patterns.md` for architecture context

## Cross-Referencing

For HCL-level patterns, reference the `terraform/` skill. For provider development patterns, reference `terraform-provider/`.

### Key Cross-Cutting Rules
- **Terraform**: Only `local` and `remote`/`cloud` backends execute operations — all others store state.
- **OpenTofu**: DCO sign-off on every commit (`git commit -s`). NO LLM-generated contributions.
- **Terraform**: Use standard `testing` + `github.com/go-test/deep` (no testify).
- **OpenTofu**: Use `go.uber.org/mock/mockgen` for mock stubs.

## Import Path Differences

Both codebases share the same package structure but differ in the root module path:

| Component | Terraform | OpenTofu |
|-----------|-----------|----------|
| Module path | `github.com/hashicorp/terraform` | `github.com/opentofu/opentofu` |
| Core engine | `github.com/hashicorp/terraform/internal/terraform/` | `github.com/opentofu/opentofu/internal/tofu/` |
| Configs | `github.com/hashicorp/terraform/internal/configs/` | `github.com/opentofu/opentofu/internal/configs/` |
| States | `github.com/hashicorp/terraform/internal/states/` | `github.com/opentofu/opentofu/internal/states/` |
| Plans | `github.com/hashicorp/terraform/internal/plans/` | `github.com/opentofu/opentofu/internal/plans/` |
| Backend | `github.com/hashicorp/terraform/internal/backend/` | `github.com/opentofu/opentofu/internal/backend/` |
| DAG | `github.com/hashicorp/terraform/internal/dag/` | `github.com/opentofu/opentofu/internal/dag/` |
| getproviders | `github.com/hashicorp/terraform/internal/getproviders/` | `github.com/opentofu/opentofu/internal/getproviders/` |

When reviewing or writing code, verify the import path matches the target codebase. A common
error is leaving Terraform import paths in OpenTofu code (or vice versa) after porting changes.

## Go Version Requirements

Both codebases require **Go 1.26.4** or later. To verify:

```bash
# Check installed Go version
go version

# Check module's declared Go version
head -3 go.mod

# Check toolchain requirement (if present)
cat .go-version   # present in some repositories
```

**Go 1.26-specific features available**:
- `errors.New` inlined as `errors.New` — compiler optimisations for error creation
- `iter.Seq` and `iter.Seq2` from the `iter` package for custom iterator support
- `slices`, `maps`, `cmp` standard library packages fully stable
- Enhanced `go test -cover` with per-package coverage profiles
- `unique` package for canonicalisation (interning) of values
- `crypto/tls` 1.3-only handshake — TLS 1.0/1.1 removed from the Go standard library

All new code may use Go 1.26 idioms freely. Do not restrict to older patterns for
compatibility.
