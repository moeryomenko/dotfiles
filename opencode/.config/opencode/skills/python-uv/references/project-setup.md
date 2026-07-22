# Project Setup with uv

Agent guidance for initializing Python projects, managing interpreter versions, and structuring virtual environments with uv. Use these directives when scaffolding new projects or onboarding an existing codebase to uv.

## Initialize a Project

`uv init` scaffolds a project in the current directory (or a named subdirectory). It creates `pyproject.toml`, `.python-version`, a `.venv` virtual environment, `README.md`, and a `main.py` entry stub.

```bash
# Initialize in the current directory
uv init

# Initialize a new project in a subdirectory
uv init my-service
cd my-service

# Initialize a library project (adds a src/ layout and build backend)
uv init --lib my-library

# Initialize an application project (default, no src/ layout)
uv init --app my-app
```

After `uv init`, the project layout resembles:

```
my-project/
├── .python-version      # pinned interpreter version
├── .venv/               # auto-created virtual environment
├── pyproject.toml       # project metadata and dependencies
├── README.md
└── main.py              # entry stub (application projects)
```

For library projects (`uv init --lib`), uv adds a `src/` directory with a package skeleton and configures a build backend (`hatchling` by default).

## Manage Python Versions

uv downloads and manages standalone Python builds, eliminating the need for pyenv or system package managers for interpreter provisioning.

```bash
# Install a specific Python version
uv python install 3.12

# Install multiple versions
uv python install 3.11 3.12 3.13

# List installed and available versions
uv python list

# Pin the project's Python version (writes .python-version)
uv python pin 3.12

# Use a specific version for a single command without pinning
uv run --python 3.11 python script.py
```

`uv python pin` writes the version to `.python-version`, which `uv sync` and `uv run` read automatically. Pin a version early in project setup to ensure reproducible environments across contributors and CI.

## Virtual Environment Handling

uv creates and manages `.venv` automatically. `uv sync` and `uv run` create the virtual environment if it does not exist — manual activation is unnecessary in most workflows.

```bash
# Explicit venv creation (rarely needed; sync/run do this automatically)
uv venv

# Create a venv with a specific Python version
uv venv --python 3.12

# Run a command in the project environment without activating
uv run python script.py
uv run pytest
```

Prefer `uv run` over manual `source .venv/bin/activate`. The `uv run` command ensures the environment is synchronized with the lockfile before executing, preventing drift between `pyproject.toml` and the installed packages.

## pyproject.toml Structure

`uv init` generates a minimal `pyproject.toml`. Extend it with project metadata and dependencies as needed.

```toml
[project]
name = "my-service"
version = "0.1.0"
description = "Service for processing events"
readme = "README.md"
requires-python = ">=3.12"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
# uv-specific configuration lives here
```

For application projects that are not distributed as packages, omit `[build-system]` or set `tool.uv.package = false` to skip build-backend requirements. For libraries, keep the build backend so `uv build` can produce wheels.

## Project Structure Decisions

- **Application projects** (`uv init --app`): flat layout with `main.py` at the root. Suitable for services, CLIs, and scripts that are deployed, not distributed.
- **Library projects** (`uv init --lib`): `src/` layout with a package directory. Prevents accidental imports from the working directory and aligns with PEP 621 packaging standards.
- **`.python-version`**: commit this file so CI and contributors use the same interpreter.
- **`.venv/`**: add to `.gitignore`. uv recreates it on demand.