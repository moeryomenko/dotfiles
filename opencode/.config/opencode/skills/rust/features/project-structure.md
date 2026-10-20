# Project Structure

Let the package's purpose, workspace boundaries, compilation time, public API, and deployment model determine structure. Preserve established repository layout unless it makes ownership, visibility, testing, or release boundaries unclear.

## Crates and modules

A binary may call a library entry point when the logic is reusable or benefits from integration testing, but a small binary need not manufacture a library solely for that pattern. Organize modules around coherent domain or capability boundaries; flat modules are often clearer until a hierarchy pays for itself.

Use the narrowest visibility that supports intended callers. Re-export a curated public API when it decouples callers from internal layout; do not add a prelude unless repeated imports and name-collision policy justify one.

Use separate packages/workspace members for independent release, feature, dependency, security, or compile-time boundaries—not merely to mirror folders.

## Cargo policy

Set `rust-version` to the actual minimum supported compiler and test that version in CI. Edition and local compiler availability do not raise the crate's MSRV.

```toml
[package]
edition = "2024"
rust-version = "1.85"

[dependencies]
serde = { workspace = true }
```

At a workspace root, centralize only policy that is genuinely shared, such as `[workspace.package]`, `[workspace.dependencies]`, and `[workspace.lints]`. Member packages opt into inherited values deliberately. Select the resolver and features from the supported Cargo/toolchain and dependency graph; avoid broad feature sets such as `full` unless the package needs them.

Keep `build.rs` deterministic, minimally privileged, and explicit about rebuild inputs with `cargo:rerun-if-changed`. A build script is not automatically preferable to runtime initialization or checked-in generated code.

## Load next

- Workspace lint configuration: `linting.md`
- Dependency and feature decisions: `ecosystem.md`
- Public module contracts: `api-design.md`
