# Linting and Formatting

Treat linting as repository policy. Start with the crate's existing toolchain, MSRV, generated-code policy, and CI commands; add a lint because it catches a failure mode the project intends to maintain.

Run `cargo fmt --check`, `cargo clippy --all-targets` with the repository's selected feature matrix, and tests as appropriate. Do not blanket-enable every restriction lint without an ownership and remediation policy.

## Workspace lints

Define shared lint policy at the workspace root and opt member crates into it:

```toml
# workspace Cargo.toml
[workspace.lints.rust]
unsafe_op_in_unsafe_fn = "deny"

[workspace.lints.clippy]
unwrap_used = "warn"
```

```toml
# member Cargo.toml
[lints]
workspace = true
```

Lint names, groups, toolchain support, and generated-code exceptions can change, so verify configuration against the selected Cargo version. A lint warning is a review signal, not a proof that every exception is wrong.

Use `#[allow]` narrowly with a reason when the local code intentionally differs from policy. Prefer fixing the underlying issue to suppressing a lint globally.

## Load next

- Unsafe-policy documentation: `unsafe.md`
- Project/toolchain policy: `project-structure.md`
