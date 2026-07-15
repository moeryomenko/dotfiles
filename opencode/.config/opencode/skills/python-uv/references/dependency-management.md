# Dependency Management with uv

Agent guidance for adding, removing, synchronizing, and locking dependencies with uv. Use these directives when modifying project dependencies, regenerating lockfiles, or configuring CI/CD pipelines.

## Add and Remove Dependencies

`uv add` resolves and installs a package, updates `pyproject.toml`, and writes the result to `uv.lock`. `uv remove` reverses this.

```bash
# Add a runtime dependency
uv add requests

# Add with a version constraint
uv add "django>=4.2,<5.0"

# Add multiple packages at once
uv add httpx pydantic

# Add a development dependency (dev dependency group)
uv add --dev pytest pytest-cov

# Add to a named dependency group
uv add --group test hypothesis

# Add an optional dependency (extras)
uv add --optional docs sphinx

# Add from a git repository
uv add "git+https://github.com/owner/repo.git"

# Add a local package in editable mode
uv add --editable ./local-plugin
```

```bash
# Remove a dependency (updates pyproject.toml and uv.lock)
uv remove requests

# Remove a dev dependency
uv remove --dev pytest

# Remove from a named group
uv remove --group test hypothesis
```

## Sync and Lock

`uv sync` installs the exact dependencies recorded in `uv.lock` into `.venv`. `uv lock` regenerates the lockfile from `pyproject.toml` without installing.

```bash
# Sync the environment from the lockfile (creates .venv if needed)
uv sync

# Sync only production dependencies (exclude dev groups)
uv sync --no-dev

# Sync a specific group
uv sync --group test

# Regenerate the lockfile from pyproject.toml
uv lock

# Regenerate and upgrade all packages to latest compatible
uv lock --upgrade

# Upgrade a single package in the lockfile
uv lock --upgrade-package requests
```

The `uv.lock` file is a cross-platform lockfile recording resolved versions, hashes, and sources. Commit it to the repository for reproducible installs across development, CI, and production.

## Run Commands in the Project Environment

`uv run` executes a command in the project's virtual environment, synchronizing dependencies first. This replaces manual venv activation.

```bash
# Run a Python script
uv run python script.py

# Run the test suite
uv run pytest

# Run a CLI tool installed as a dependency
uv run ruff check .

# Run with a specific Python version (overrides .python-version)
uv run --python 3.11 python script.py

# Pass arguments through to the command
uv run python -m http.server 8080
```

## Dependency Groups

uv supports dependency groups via the `[dependency-groups]` section in `pyproject.toml` (PEP 735). Groups separate development, test, and documentation dependencies from runtime requirements.

```toml
[project]
dependencies = [
    "fastapi>=0.110",
    "httpx>=0.27",
]

[dependency-groups]
dev = [
    "ruff>=0.5",
    "mypy>=1.10",
]
test = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "hypothesis>=6.100",
]
docs = [
    "sphinx>=7.3",
    "furo>=2024.5",
]
```

```bash
# Sync with all groups (default)
uv sync

# Sync without dev groups
uv sync --no-dev

# Sync only a specific group
uv sync --only-group test
```

## Workspaces and Monorepos

uv supports workspace projects for monorepo layouts. A workspace root defines member packages that share a single lockfile.

```toml
# Root pyproject.toml
[tool.uv.workspace]
members = ["packages/*"]
```

```toml
# packages/my-lib/pyproject.toml
[project]
name = "my-lib"
version = "0.1.0"

[tool.uv.sources]
# Reference another workspace member by path
my-utils = { workspace = true }
```

```bash
# Sync the entire workspace
uv sync

# Run a command in a specific member
uv run --package my-lib pytest
```

## Install CLI Tools Globally

`uv tool install` installs a CLI tool in an isolated environment, exposing it on `$PATH` without polluting the project venv.

```bash
# Install a CLI tool globally
uv tool install ruff

# Install a specific version
uv tool install ruff@0.5.0

# Upgrade an installed tool
uv tool upgrade ruff

# List installed tools
uv tool list

# Run a tool without installing it permanently
uvx ruff check .
```

## CI/CD Integration

Use `uv sync --frozen` in CI to install exactly what the lockfile records, failing if the lockfile is out of date with `pyproject.toml`. This guarantees reproducible builds and catches uncommitted lockfile drift.

```bash
# Install uv in CI
curl -LsSf https://astral.sh/uv/install.sh | sh

# Sync from lockfile without updating it (reproducible install)
uv sync --frozen

# Verify the lockfile is up to date (fail if drift detected)
uv lock --check

# Cache the uv global cache across CI runs
# Set UV_CACHE_DIR to a CI cache path
export UV_CACHE_DIR=$CI_CACHE_DIR/uv-cache
```

For Docker builds, copy `pyproject.toml` and `uv.lock` before the source code to leverage layer caching:

```dockerfile
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .
CMD ["uv", "run", "python", "-m", "my_service"]
```