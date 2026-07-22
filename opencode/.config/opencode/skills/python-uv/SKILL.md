---
name: python-uv
description: "uv package manager for Python — project setup, dependency management, lockfiles, and migration from pip/poetry/pipenv. Use when setting up Python projects, managing dependencies with uv, or migrating from pip/poetry/pipenv."
invocation_policy: automatic
---

# Python uv Workflows

`uv` is an extremely fast Python package installer and resolver written in Rust. It replaces pip, pip-tools, poetry, pipenv, and pyenv in a single tool, with a global disk cache that deduplicates downloads across projects. This skill provides agent guidance for the uv CLI surface: project initialization, dependency management, lockfiles, Python version management, and migration from legacy tools.

## Capabilities

Route to the reference file matching the task:

| Task | Reference |
|------|-----------|
| Initialize a new project, manage Python versions, create virtual environments | [references/project-setup.md](references/project-setup.md) |
| Add/remove dependencies, sync from lockfile, dependency groups, CI/CD integration | [references/dependency-management.md](references/dependency-management.md) |
| Migrate from pip, pip-tools, poetry, pipenv, or hatch | [references/migration.md](references/migration.md) |

## When to Use This Skill

- Creating a new Python project with `uv init`.
- Adding, removing, or upgrading dependencies via `uv add` / `uv remove`.
- Synchronizing an environment from a lockfile with `uv sync`.
- Regenerating a lockfile with `uv lock`.
- Running commands in the project environment with `uv run`.
- Installing or pinning a Python interpreter with `uv python install` / `uv python pin`.
- Migrating an existing project from pip, poetry, or pipenv to uv.

## Core uv Concepts

- **Project-centric**: uv manages `pyproject.toml` as the source of truth and `uv.lock` for reproducible installs.
- **Automatic venv**: `uv sync` and `uv run` create and use `.venv` automatically — no manual activation required.
- **Global cache**: a shared cache (`~/.cache/uv` or `$UV_CACHE_DIR`) deduplicates wheels across projects, making repeated installs near-instant.
- **Lockfile**: `uv.lock` is a cross-platform lockfile recording resolved versions and hashes for reproducibility.
- **Python management**: uv downloads and manages standalone Python builds via `uv python install`, removing the need for pyenv.
- **Drop-in pip**: `uv pip` provides a pip-compatible interface for legacy workflows that do not use `pyproject.toml`.

## Cross-Referencing

- For Python language patterns, type safety, and testing conventions, see the `python` skill (`../python/SKILL.md`).
- For packaging standards (PEP 517/518/621), see `../python/features/packaging.md`.
- For project structure guidance (src layout, `__all__`), see `../python/features/project-structure.md`.
- For debugging Python projects, see the `python-debugging` skill (`../python-debugging/SKILL.md`).
- All references in this skill use relative paths.