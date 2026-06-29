---
name: domain-cli
description: Use when building CLI tools in Rust. Keywords: CLI, command line, clap, terminal, stdin, stdout, stderr, argument parsing, shell completion, color output, progress bar, TUI, subcommand.
---

# Domain: CLI (Rust)

**Triggers**: CLI, command line, clap, terminal, stdin, stdout, stderr, argument parsing, shell completion, color output, progress bar, TUI, subcommand, shell.

## Domain Constraints -> Design Implications

| Domain Rule | Design Constraint | Rust Implication |
|-------------|-------------------|------------------|
| Fast startup | Minimal init time | Lazy loading, no heavy deps |
| Single-threaded by default | No thread safety needed | Rc, RefCell ok if needed |
| Error visibility | Clear error messages | anyhow with context for errors |
| User control | Signals (Ctrl+C) | Signal handling |
| Composability | Pipe support | Read from stdin, write to stdout |

---

## Critical Constraints

### Fast Startup

```
RULE: CLI tools should start instantly
WHY: Users notice startup latency
RUST: Lazy init for heavy resources, avoid eager loading
```

### Error Visibility

```
RULE: Errors must be immediately understandable
WHY: User is looking at the terminal, not a dashboard
RUST: anyhow with human-readable context, color output
```

### Unix Philosophy

```
RULE: Do one thing well, compose with pipes
WHY: CLI tools are building blocks
RUST: Read from stdin, write to stdout, stderr for diagnostics
```

---

## CLI Framework Comparison

| Framework | Style | Best For |
|-----------|-------|----------|
| clap (derive) | Derive-based | Most CLI tools |
| clap (builder) | Builder pattern | Complex CLI with dynamic args |
| bpaf | Composable | Functional CLI composition |
| argh | Minimal derive | Simple CLIs |

## Key Crates

| Purpose | Crate |
|---------|-------|
| Argument parsing | clap |
| Terminal colors | colored, owo-colors, anstyle |
| Progress bars | indicatif |
| Shell completion | clap_complete |
| Signals | tokio::signal, signal-hook |
| Paging | bat, less |
| TUI | ratatui |

## Design Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| Derive args | Structured parsing | `#[derive(Parser)]` |
| Subcommands | Hierarchical CLIs | `enum Commands { ... }` |
| Progress bars | Long operations | `indicatif::ProgressBar` |
| Color output | Readable diagnostics | `colored::Colorize` |
| Pipe detection | Adapt to stdin/stdout | `atty::isnt` |

## Code Pattern: CLI with clap

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "myapp", about = "Does awesome things")]
struct Cli {
    #[arg(short, long, default_value = "config.toml")]
    config: PathBuf,

    #[arg(short, long, global = true)]
    verbose: bool,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new project
    Init {
        #[arg(default_value = ".")]
        path: PathBuf,
    },
    /// Build the project
    Build {
        #[arg(short, long)]
        release: bool,
    },
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init { path }) => init_project(&path)?,
        Some(Commands::Build { release }) => build_project(release)?,
        None => run_default(&cli)?,
    }
    Ok(())
}
```

### Error Display

```rust
use anyhow::{Context, Result};

fn main() -> Result<()> {
    if let Err(e) = run() {
        // Print error chain in human-readable format
        eprintln!("error: {:#}", e);
        std::process::exit(1);
    }
    Ok(())
}

fn run() -> Result<()> {
    let content = std::fs::read_to_string("data.csv")
        .context("failed to read data file")?;
    process(&content)
        .context("failed to process data")?;
    Ok(())
}
```

---

## Common Mistakes

| Mistake | Domain Violation | Fix |
|---------|-----------------|-----|
| Panic on bad input | Crashes instead of error message | Return Result with context |
| Blocking for too long | Freezes terminal | Progress bar or async |
| No pipe support | Breaks Unix composability | Check stdin/stdout |
| Hard-coded colors | Bad terminal compatibility | Respect NO_COLOR |
| Too many deps | Slow startup | Lazy init, minimize deps |

## Layer Mapping

| Constraint | Feature File |
|------------|--------------|
| Argument parsing | load `features/api-design.md` |
| Error messages | load `features/error-handling.md` |
| Single-threaded | load `features/ownership.md` |
| Signal handling | load `features/async.md` |
