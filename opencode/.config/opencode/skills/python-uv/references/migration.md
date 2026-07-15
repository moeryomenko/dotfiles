# Migration to uv

Agent guidance for migrating Python projects from pip, pip-tools, poetry, pipenv, and hatch to uv. Use the comparison tables to translate commands and the pitfalls section to avoid common migration errors.

## Migrate from pip

pip operates on `requirements.txt` and installs into the active environment. uv replaces this with a project-centric workflow anchored on `pyproject.toml` and `uv.lock`.

| pip / pip-tools | uv equivalent | Notes |
|-----------------|---------------|-------|
| `pip install -r requirements.txt` | `uv sync` (after migrating to pyproject.toml) or `uv pip install -r requirements.txt` | `uv pip` is a drop-in for legacy workflows |
| `pip install requests` | `uv add requests` | `uv add` also updates pyproject.toml and uv.lock |
| `pip install -e .` | `uv sync` (editable install is automatic for the project) | No separate editable install command |
| `pip freeze > requirements.txt` | `uv pip freeze` or commit `uv.lock` | Prefer the lockfile for reproducibility |
| `pip uninstall requests` | `uv remove requests` | `uv remove` updates pyproject.toml and uv.lock |
| `pip list` | `uv pip list` | Lists packages in the project venv |
| `pip download` | `uv pip download` | Compatible interface |

Migration steps:

```bash
# 1. Initialize a pyproject.toml in the project root
uv init --app .

# 2. Add dependencies from requirements.txt
uv add -r requirements.txt

# 3. Generate the lockfile
uv lock

# 4. Verify the environment
uv sync
uv run python -c "import requests; print(requests.__version__)"

# 5. Remove requirements.txt once the lockfile is committed
```

## Migrate from pip-tools

pip-tools pairs `pip-compile` (generates a pinned `requirements.txt`) with `pip-sync` (installs exactly those pins). uv consolidates both into `uv lock` and `uv sync`.

| pip-tools | uv equivalent | Notes |
|-----------|---------------|-------|
| `pip-compile` | `uv lock` | Generates `uv.lock` (cross-platform) instead of `requirements.txt` |
| `pip-compile --upgrade` | `uv lock --upgrade` | Regenerates with latest compatible versions |
| `pip-compile --upgrade-package requests` | `uv lock --upgrade-package requests` | Upgrade a single package |
| `pip-sync` | `uv sync` | Installs exactly what the lockfile records |
| `requirements.in` + `requirements.txt` | `pyproject.toml` + `uv.lock` | Source of truth + lockfile |

```bash
# Migrate: convert requirements.in to pyproject.toml dependencies
uv init --app .
uv add -r requirements.in
uv lock
uv sync --frozen
```

## Migrate from poetry

poetry manages `pyproject.toml` with a `[tool.poetry]` section and a `poetry.lock` file. uv uses the standard `[project]` section (PEP 621) and `uv.lock`.

| poetry | uv equivalent | Notes |
|--------|---------------|-------|
| `poetry new my-project` | `uv init my-project` | Scaffolds project structure |
| `poetry add requests` | `uv add requests` | Adds to pyproject.toml and lockfile |
| `poetry add --group dev pytest` | `uv add --group dev pytest` | Named dependency groups |
| `poetry remove requests` | `uv remove requests` | Removes from pyproject.toml and lockfile |
| `poetry install` | `uv sync` | Installs from lockfile |
| `poetry install --no-dev` | `uv sync --no-dev` | Exclude dev dependencies |
| `poetry lock` | `uv lock` | Regenerates lockfile |
| `poetry lock --no-update` | `uv lock --check` | Verify lockfile is current |
| `poetry run pytest` | `uv run pytest` | Run in project environment |
| `poetry run python script.py` | `uv run python script.py` | Run a script |
| `poetry shell` | `uv run bash` or `source .venv/bin/activate` | uv has no dedicated shell command |
| `poetry export -f requirements.txt` | `uv export --format requirements-txt` | Export lockfile to requirements format |
| `poetry build` | `uv build` | Build wheel and sdist |
| `poetry publish` | `uv publish` | Publish to PyPI |

Migration steps:

```bash
# 1. Convert [tool.poetry.dependencies] to [project.dependencies]
#    Move the poetry section to the standard PEP 621 [project] section.
# 2. Remove poetry.lock (uv.lock replaces it)
# 3. Sync the environment
uv sync
uv run pytest
```

## Migrate from pipenv

pipenv uses `Pipfile` and `Pipfile.lock` for dependency management. uv replaces both with `pyproject.toml` and `uv.lock`.

| pipenv | uv equivalent | Notes |
|--------|---------------|-------|
| `pipenv install` | `uv sync` | Install all dependencies from lockfile |
| `pipenv install requests` | `uv add requests` | Add a dependency |
| `pipenv install --dev pytest` | `uv add --dev pytest` | Add a dev dependency |
| `pipenv uninstall requests` | `uv remove requests` | Remove a dependency |
| `pipenv lock` | `uv lock` | Regenerate lockfile |
| `pipenv run pytest` | `uv run pytest` | Run a command in the project environment |
| `pipenv run python script.py` | `uv run python script.py` | Run a script |
| `pipenv shell` | `source .venv/bin/activate` or `uv run bash` | uv has no dedicated shell command |
| `Pipfile` + `Pipfile.lock` | `pyproject.toml` + `uv.lock` | Standard formats replace Pipfile |

Migration steps:

```bash
# 1. Initialize uv project structure
uv init --app .

# 2. Add dependencies from Pipfile (parse [packages] and [dev-packages])
uv add -r <(grep -v '^\[' Pipfile | grep '=' | sed 's/.*= *"\(.*\)"/\1/')
# Or add manually: uv add requests flask

# 3. Add dev dependencies
uv add --dev pytest

# 4. Generate lockfile and sync
uv lock
uv sync

# 5. Remove Pipfile and Pipfile.lock
```

## Migrate from hatch

hatch uses `pyproject.toml` with `[tool.hatch]` sections for build configuration and environments. uv can coexist with hatch as a build backend while managing dependencies.

| hatch | uv equivalent | Notes |
|-------|---------------|-------|
| `hatch new my-project` | `uv init --lib my-project` | Scaffolds a library project |
| `hatch install` | `uv sync` | Install dependencies |
| `hatch run test` | `uv run pytest` | Run a command |
| `hatch env create` | `uv sync` (automatic env creation) | uv creates .venv on demand |
| `hatch build` | `uv build` | Build wheel and sdist |
| `hatch publish` | `uv publish` | Publish to PyPI |
| `[tool.hatch.envs]` | `[dependency-groups]` | uv groups replace hatch environments |

```bash
# Keep hatchling as the build backend, use uv for dependency management
uv init --lib my-project
# pyproject.toml already uses hatchling by default
uv add click rich
uv sync
uv run python -m my_project
```

## Common Migration Pitfalls

### requirements.txt vs pyproject.toml

`requirements.txt` is a flat list of pinned packages. `pyproject.toml` is structured metadata with dependency specifiers. When migrating, convert pinned versions to compatible release specifiers (`>=` rather than `==`) unless exact pinning is required. The lockfile (`uv.lock`) handles exact pinning for reproducibility.

### Virtual environment location

pip and pipenv create virtual environments in custom locations (`venv/`, `.venv/`, or a pipenv-managed path). uv standardizes on `.venv` in the project root. Update `.gitignore`, CI scripts, and IDE configurations that reference the old venv path.

### Python version management

pip and poetry rely on a system Python or pyenv. uv manages Python interpreters internally via `uv python install`. After migration, remove pyenv version files (`.python-version` managed by pyenv) and let uv pin the version:

```bash
uv python install 3.12
uv python pin 3.12
```

### Lockfile format differences

`poetry.lock`, `Pipfile.lock`, and `requirements.txt` are not compatible with `uv.lock`. Do not attempt to convert lockfiles directly — regenerate from `pyproject.toml` with `uv lock`. Commit the new `uv.lock` and remove the old lockfile.

### Build backend conflicts

If a project uses poetry's build backend (`poetry-core`), switch to a standard backend (`hatchling`, `setuptools`, or `flit`) in `[build-system]`. uv works with any PEP 517 build backend.

### Dependency group syntax

poetry uses `[tool.poetry.group.dev]` and pipenv uses `[dev-packages]`. uv uses the standard `[dependency-groups]` section (PEP 735). Rewrite group definitions when migrating.