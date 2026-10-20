---
name: domain-cli
description: Use when building command-line applications in Rust, including argument parsing, terminal behavior, pipelines, progress reporting, and process exit semantics.
---

# Rust CLI Guidance

Start with the command's contract: machine-readable versus human-readable output, stdin/stdout/stderr behavior, exit statuses, configuration sources, signal/shutdown behavior, and supported terminal environments. Inspect the crate's MSRV and existing CLI framework before choosing APIs or dependencies.

## Interface boundaries

- Parse arguments and configuration at the executable boundary; validate cross-field and domain rules after parsing.
- Send primary data to stdout and diagnostics, progress, and prompts to stderr so pipelines remain usable.
- Use `std::io::IsTerminal` when the crate MSRV supports it to adapt interactive presentation. Respect explicit user configuration and conventions such as `NO_COLOR`; never make a TTY heuristic the only way to control output.
- Provide stable exit codes and machine-readable formats only when they are part of the command's contract. Avoid changing textual output that scripts may consume without a compatibility decision.

## Errors and process lifetime

Executable boundaries can use an ergonomic reporting type such as `anyhow::Result`; reusable libraries should expose error types that callers can inspect when that is part of their API. Add useful context at filesystem, process, network, and configuration boundaries, then print a failure once in `main` or the selected command runner.

```rust
use anyhow::{Context, Result};

fn run() -> Result<()> {
    let input = std::fs::read_to_string("data.csv")
        .with_context(|| "failed to read data.csv")?;
    process(&input).context("failed to process input")
}

fn main() {
    if let Err(error) = run() {
        eprintln!("error: {error:#}");
        std::process::exit(1);
    }
}
```

`process::exit` bypasses destructors, so required persistence or protocol completion must happen before it.

## Responsiveness and concurrency

A progress bar reports progress; it does not make blocking or CPU-heavy work asynchronous. Keep the terminal responsive by selecting an execution model that matches the workload:

- straightforward synchronous work is often appropriate for a small command;
- use bounded workers, Rayon, or a job system for sustained CPU parallelism;
- use an async runtime for substantial concurrent I/O, with runtime-specific signal and cancellation handling;
- use `spawn_blocking` only to isolate a bounded blocking operation from async workers.

CLI applications may be multithreaded through their own code or dependencies. Choose `Rc`/`RefCell` only when the required ownership never crosses threads; do not infer single-threadedness from the interface.

## `clap` shape

Use the repository's chosen `clap` version and feature set. This excerpt omits application-specific functions and imports such as `std::path::PathBuf`:

```rust
use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Subcommand)]
enum Command {
    Init { #[arg(default_value = ".")] path: PathBuf },
    Build { #[arg(short, long)] release: bool },
}
```

## Load next

- Argument/public option design: `features/api-design.md`
- Error behavior: `features/error-handling.md`
- Async signals, cancellation, and tasks: `features/async.md`
- Configuration, dependencies, and binary layout: `features/project-structure.md`, `features/ecosystem.md`
