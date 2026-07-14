# False Positive Guide — Libvirt Provider

Patterns that look wrong during libvirt provider review but are correct, intentional, or acceptable.

## 1. Generated Code is Gitignored

**What looks wrong**: The `internal/generated/*.gen.go` files are not in the repository.

**Why it's correct**: Generated code is gitignored by design. The codegen pipeline runs automatically (`make generate` is triggered by `make build` and `make test`). New checkouts must run `make generate` or `make build` first.

**When to flag only**: If a file that should be generated is gitignored but the codegen hasn't been updated to produce it.

## 2. Libvirt Normalizes Values on Readback

**What looks wrong**: A field set to `q35` appears as `pc-q35-10.1` after apply.

**Why it's correct**: Libvirt normalizes architecture/machine values to their full versioned names. The provider should preserve the user's original value in state (use the plan value, not the API readback).

**When to flag only**: If the provider overwrites user input with the normalized API value.

## 3. Nested Attributes Look Like Blocks

**What looks wrong**: Using `Schema.ListNestedAttribute` instead of `Schema.ListNestedBlock` looks different from SDK v2 patterns.

**Why it's correct**: Plugin Framework best practice is nested attributes. Blocks are legacy SDK v2 patterns. Attributes provide better validation and planning semantics.

**When to flag only**: If a list/set field needs backward compatibility with SDK v2 consumers.

## 4. golibvirt Constants vs Strings

**What looks wrong**: Passing `golibvirt.DomainRunning` (a numeric constant) instead of the string `"running"`.

**Why it's correct**: golibvirt uses numeric/typed constants from the libvirt wire protocol. String comparison would be incorrect. Always use the constants defined in the golibvirt package.

**When to flag only**: If a new golibvirt version deprecates a constant.

## 5. Multiple Connection Dialers

**What looks wrong**: Multiple connection dialers (local socket, SSH, TLS) with different code paths.

**Why it's correct**: Each transport has different requirements and capabilities. The dialer interface abstracts over them, and each implementation handles its own connection details.

**When to flag only**: If a new dialer duplicates significant code from an existing dialer.

## 6. XML Roundtrip Diffs

**What looks wrong**: After creating a domain, reading its XML description back from libvirt produces different XML than what was sent — elements reordered, default values filled in, whitespace normalized, missing optional elements added.

**Why it's correct**: Libvirt normalizes XML on every write/read cycle. It reorders elements to match the RNG `interleave` definition order, fills in default values for unspecified optional fields, and normalizes whitespace and attribute quoting. The resulting XML is semantically equivalent but structurally different. This is a standard libvirt behavior, not a provider bug.

**When to flag only**: If the diff changes functionality — e.g., a critical attribute is missing or a different configuration is applied on the next update. Style-only diffs (reordering, whitespace, default filling) are always expected and should never be flagged.
