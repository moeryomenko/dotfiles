# False Positive Guide — Terraform/OpenTofu Core

Patterns that look wrong during core contribution review but are correct, intentional, or acceptable.

## 1. No testify in Terraform

**What looks wrong**: Using standard `testing.T` methods instead of testify assertions.

**Why it's correct**: Terraform deliberately avoids testify. The codebase uses `github.com/go-test/deep` for deep comparison. New code should follow this convention.

**When to flag only**: If a new test introduces testify when the surrounding tests use standard `testing`.

## 2. Multiple `go.mod` files

**What looks wrong**: Multiple `go.mod` files in sub-modules under `internal/backend/remote-state/*/`.

**Why it's correct**: Each remote state backend is a separate Go module because it may have different dependency requirements. Terraform's CI loops over sub-modules with `go list -m ...`.

**When to flag only**: If a new dependency adds a `go.mod` where one isn't needed.

## 3. Large Interface Definitions

**What looks wrong**: Interfaces with many methods (e.g., `providers.Interface`, `statemgr.Full`).

**Why it's correct**: These are plugin-boundary interfaces that define the entire contract between Terraform core and providers/backends. Breaking them into smaller interfaces would fragment the protocol.

**When to flag only**: If a new interface is introduced with many unrelated methods that could be separated.

## 4. String-Keyed Maps in State

**What looks wrong**: Using string-keyed maps instead of typed structs for state representation.

**Why it's correct**: The state file is serialised as JSON, and many fields are dynamically determined (provider-specific attributes). String-keyed maps are the natural representation for dynamic content.

**When to flag only**: If a statically-known field uses string keys instead of a struct field.

## 5. Experimental Features Behind Build Tags

**What looks wrong**: Features gated behind build tags or ldflags (e.g., `main.experimentsAllowed`).

**Why it's correct**: Terraform uses build-time flags for experimental features to prevent accidental enablement in production builds. This is intentional for safe feature rollout.

**When to flag only**: If a feature is gated behind a build tag but has no visible gating in code or error messages.

## 6. Direct Field Access on State Types

**What looks wrong**: Directly accessing `sync.Map` fields or `promising.Future` values instead of using accessor methods.

**Why it's correct**: Some internal types expose fields directly for performance-critical paths where the accessor overhead matters. These are documented as internal.

**When to flag only**: If used outside the package that defines the type.

## 7. Dynamic Graph Node Expansion

**What looks wrong**: A single graph vertex expanding into N instance vertices at walk time,
bypassing static graph construction.

**Why it's correct**: Resources with `count` or `for_each` implement `GraphNodeDynamicExpandable`.
The graph builder places a single placeholder vertex; at walk time, `DynamicExpand()` replaces
it with N instance vertices. This is the intentional design and not a bug.

**When to flag only**: If a node implements `GraphNodeDynamicExpandable` but produces no
expansion or has no `count`/`for_each` expression.

## 8. Backend.Local Wrapping

**What looks wrong**: Every backend appears to delegate to `Backend.Local` for operation
execution instead of implementing `Operation` directly.

**Why it's correct**: Only `local` and `remote`/`cloud` backends implement the `Operation`
method. All other backends (S3, GCS, AzureRM, etc.) wrap `Backend.Local` to execute operations
while only providing their own `StateMgr` for state storage. This is the intended delegation
pattern.

**When to flag only**: If a new backend implements `Operation` without a clear reason
to bypass the local backend.

## 9. Expression Evaluation at Graph-Walk Time

**What looks wrong**: HCL expressions appear to be evaluated during graph walk, not during
config loading — making it hard to trace where values come from.

**Why it's correct**: Terraform/OpenTofu evaluate HCL expressions lazily during the graph walk,
not during config parsing. This allows expressions to reference values that aren't known until
apply time (e.g., resource attributes from create-before-destroy). The `EvalContext` provides
variable scope at walk time.

**When to flag only**: If an expression evaluation produces a value that should have been
available at config load time but wasn't.

## 10. Dual Copyright Headers

**What looks wrong**: OpenTofu source files contain both "Copyright (c) HashiCorp, Inc."
and "Copyright (c) The OpenTofu Authors" in the same file.

**Why it's correct**: OpenTofu is a fork of Terraform. Files originally written by HashiCorp
retain the HashiCorp copyright line; the OpenTofu Authors line is added for modifications.
Both are required by the MPL-2.0 license's provenance requirements.

**When to flag only**: If a brand-new file (not forked) includes a HashiCorp copyright header.
