# Packaging

Directives for authoring, building, and distributing Python packages. Apply these rules when creating a new package, configuring build metadata, or publishing to PyPI.

## pyproject.toml as the Single Config Source

PEP 517, 518, 621, and 660 make `pyproject.toml` the single source of project metadata and build configuration. Do not split configuration across `setup.py`, `setup.cfg`, and `pyproject.toml` — consolidate into `pyproject.toml`.

- Declare the build system under `[build-system]` (PEP 518).
- Declare project metadata under `[project]` (PEP 621): `name`, `version`, `description`, `requires-python`, `dependencies`, `optional-dependencies`.
- Use PEP 660 editable installs (`pip install -e .`) via the backend's editable hook, not a legacy `setup.py develop`.

```python
# Example: validate metadata programmatically before publishing.
import tomllib
from pathlib import Path


def load_project_meta(path: str) -> dict:
    """Return the [project] table from pyproject.toml."""
    data = tomllib.loads(Path(path).read_text())
    required = {"name", "version", "requires-python"}
    missing = required - data.get("project", {}).keys()
    if missing:
        raise ValueError(f"pyproject.toml missing: {missing}")
    return data["project"]
```

## Build Backends and the src Layout

Choose a build backend and commit to it. Prefer the src layout (`src/<package>/`) over the flat layout for any package intended for distribution.

| Backend | Use when |
|---------|----------|
| `setuptools` | Existing projects, maximum compatibility |
| `hatchling` | New pure-Python projects wanting modern defaults |
| `flit` | Pure-Python packages with minimal build needs |

The src layout prevents accidental imports from the working directory during tests. With a flat layout, `import mypkg` resolves to the source tree even before installation, masking packaging bugs. Configure the backend to discover packages under `src/`:

```python
# build_check.py — assert the built wheel contains the expected modules.
import subprocess
import zipfile


def wheel_modules(wheel_path: str) -> list[str]:
    """Return top-level modules shipped in a wheel."""
    with zipfile.ZipFile(wheel_path) as zf:
        return sorted({n.split("/")[0] for n in zf.namelist() if n.endswith(".py")})


subprocess.run(["python", "-m", "build"], check=True)
assert "mypkg" in wheel_modules("dist/mypkg-0.1.0-py3-none-any.whl")
```

## Distribution and PyPI Publishing

Build both a wheel (binary distribution) and an sdist (source distribution). Wheels install faster and avoid requiring build tools on the consumer side.

- Build with `python -m build` (PEP 517 frontend), which produces both artifacts in `dist/`.
- Publish with `twine upload dist/*`. Prefer trusted publishing (OIDC) on GitHub Actions over long-lived API tokens.
- Test against TestPyPI first: `twine upload --repository testpypi dist/*`.
- Declare CLI entry points under `[project.scripts]` so the backend generates the `console_scripts` metadata.

```python
# entry_points_check.py — verify console_scripts were generated.
import importlib.metadata as md


def console_scripts(dist_name: str) -> list[str]:
    """Return console_scripts entry points for an installed distribution."""
    return [ep.name for ep in md.entry_points(group="console_scripts") if ep.dist.name == dist_name]
```

## When to Use

- Creating a new distributable package or restructuring an existing one.
- Authoring or reviewing `pyproject.toml` for PEP 621 compliance.
- Setting up CI publishing to PyPI or a private index.
- Adding CLI entry points to a library.

## Cross-References

- See the `python-uv` skill for uv-based project setup and dependency management (`uv init`, `uv build`, `uv publish`).
- See `project-structure.md` for src layout rationale, module cohesion, and `__all__` conventions.
- See `testing.md` for testing packages installed in editable mode.
- See `configuration.md` for runtime configuration of packaged applications.