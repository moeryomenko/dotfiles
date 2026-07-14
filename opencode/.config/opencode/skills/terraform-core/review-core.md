# Terraform/OpenTofu Core Review Checklist

Structured review checklist for Terraform and OpenTofu core Go contributions.

## Before You Begin

1. Identify which codebase — Terraform (BUSL-1.1, HashiCorp CLA) or OpenTofu (MPL-2.0, DCO)
2. Load `technical-patterns.md` for architecture context
3. Load `features/go-patterns.md` for code conventions
4. Check if the change requires a changie entry (Terraform) or CHANGELOG update (OpenTofu)
5. For OpenTofu: confirm contribution is human-written (no LLM-generated code)

## Checklist Categories

### 1. Architecture & Package Structure

- [ ] Change follows existing package layout
- [ ] New packages justified (not adding to existing package where appropriate)
- [ ] No circular imports between packages
- [ ] Public API surface minimized (unexport what can be unexported)
- [ ] Interface definitions are minimal and focused

### 2. Graph & Walk Correctness

- [ ] New graph nodes implement correct interfaces (GraphNodeResource, GraphNodeDynamicExpandable)
- [ ] Walk order is correct for the operation (forward for apply, reverse for destroy)
- [ ] Dynamic expansion handles count/for_each correctly
- [ ] Cycle detection doesn't produce false positives
- [ ] Graph transformers maintain correct ordering constraints

### 3. State Management

- [ ] State mutations are properly serialized
- [ ] State locking is acquired before mutations
- [ ] No direct state file manipulation outside statemgr interface
- [ ] State migration handles all schema versions
- [ ] Resource instance addresses are correctly formed

### 4. Backend Handling

- [ ] Backend only stores state if it doesn't execute operations
- [ ] No hardcoded backend credentials in code
- [ ] Backend configuration is static (no interpolation)
- [ ] Migration path between backends is safe

### 5. Provider Interface

- [ ] Provider schema changes are backward compatible
- [ ] Resource instance operations are idempotent
- [ ] Error handling preserves partial state on failure
- [ ] Provider process lifecycle is correct (start, stop, timeout)

### 6. Code Conventions

- [ ] Imports follow standard ordering (stdlib, external, internal)
- [ ] No testify assertions (use standard testing + go-test-deep in Terraform)
- [ ] Error messages are user-actionable (not internal-only)
- [ ] Diagnostics use tfdiags for user-facing errors
- [ ] Copyright header matches codebase convention
- [ ] Go 1.26+ idioms used where appropriate

### 7. Testing

- [ ] Unit tests cover new functionality
- [ ] Mock providers used for provider-dependent tests
- [ ] Race detector passes on affected packages (Terraform: -race on internal/terraform, internal/command, internal/states)
- [ ] Test fixtures in testdata/ (not inline in test files)
- [ ] Acceptance tests gated by TF_ACC=1
- [ ] No API calls in unit tests

### 8. Backward Compatibility

- [ ] State file format version not bumped unnecessarily
- [ ] Plan format changes are version-gated
- [ ] Deprecated fields have deprecation messages
- [ ] CLI output changes are backward compatible
- [ ] Environment variable changes are additive (not breaking)

### 9. Build & CI

- [ ] `go build` / `go build ./cmd/tofu` succeeds
- [ ] Generated code is regenerated (make generate, make protobuf)
- [ ] Staticcheck/lint passes
- [ ] Changelog/Changie entry for user-facing changes
- [ ] No CGO dependencies unless explicitly required

### 10. Policy & Deprecation

- [ ] No new state storage backends accepted — all new backends must implement only `StateMgr`
      and delegate `Operation` to the local backend. Adding new backends that implement
      `Operation` directly requires explicit maintainer approval.
- [ ] No new tool-specific provisioners accepted — `chef`, `puppet`, `salt-mastercall`, etc.
      provisioners are considered legacy. Use configuration management tools directly.
- [ ] `terraform-bundle` is deprecated — do not add features or fixes to
      `tools/terraform-bundle/`. Users should migrate to `terraform providers mirror`.

### 11. Security

- [ ] No secrets in logs, diagnostics, or error messages
- [ ] Provider plugin verification by checksum
- [ ] State file paths are validated (no path traversal)
- [ ] Remote operations are authenticated
- [ ] Temporary files are cleaned up
