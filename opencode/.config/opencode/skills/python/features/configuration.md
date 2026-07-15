# Python Configuration

Agent guidance for externalizing configuration from code. Apply these directives when setting up a new project's settings system, migrating hardcoded values to environment variables, or managing secrets. Configuration belongs in the environment, not in source — the same code must run unchanged across dev, staging, and production.

## Pydantic-Settings

Enforce `pydantic-settings` (`BaseSettings`) as the default configuration layer for any service with more than a handful of values. It loads from environment variables, validates types, and fails fast at startup with a clear error listing every missing field. Avoid scattering `os.getenv("KEY")` calls across modules — they defer validation until first use and produce cryptic `None` failures deep in request handling.

```python
from pydantic_settings import BaseSettings
from pydantic import Field, ValidationError
import sys

class Settings(BaseSettings):
    """Application configuration loaded and validated at startup."""

    db_url: str = Field(alias="DATABASE_URL")
    db_pool_size: int = Field(default=10, alias="DB_POOL_SIZE")
    redis_url: str = Field(default="redis://localhost:6379", alias="REDIS_URL")
    api_secret_key: str = Field(alias="API_SECRET_KEY")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

try:
    settings = Settings()
except ValidationError as e:
    print("Configuration error:")
    for error in e.errors():
        print(f"  - {error['loc'][0]}: {error['msg']}")
    sys.exit(1)
```

Import the `settings` singleton throughout the application. Never instantiate `Settings()` in more than one place — duplicate instances read the environment at different times and can diverge if values change. For test isolation, override settings via dependency injection or `pydantic-settings`' `SettingsConfigDict` rather than mutating `os.environ`.

## Environment Variables and .env Files

Follow the 12-factor app principle: store config in the environment, not in code. Environment variables are the universal configuration interface across containers, orchestration systems, and CI runners. Use `python-dotenv` (or pydantic-settings' built-in `.env` support) only for local development convenience — never load `.env` files in production; the orchestrator injects real environment variables.

```python
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    """Settings with .env fallback for local development only."""

    s3_bucket: str = Field(alias="S3_BUCKET")
    s3_region: str = Field(default="us-east-1", alias="S3_REGION")

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }
```

Namespace related variables with a consistent prefix (`DB_`, `REDIS_`, `AUTH_`) so `env | grep DB_` is useful during debugging. Add every required variable to a `.env.example` file committed to the repository; the real `.env` file stays gitignored. Never commit secrets — see the secrets section below.

## Config Hierarchies

Enforce a single override chain: defaults in code -> environment variables -> explicit CLI flags. Each layer overrides the one below it. This makes local development zero-config (sensible defaults), staging and production environment-driven (env vars), and one-off operations explicit (CLI flags).

```python
import argparse
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Settings with CLI override support."""
    port: int = 8000
    log_level: str = "INFO"

def build_settings(cli_args: argparse.Namespace) -> Settings:
    """Build settings from env, then apply CLI overrides."""
    settings = Settings()
    if getattr(cli_args, "port", None) is not None:
        settings = settings.model_copy(update={"port": cli_args.port})
    if getattr(cli_args, "log_level", None) is not None:
        settings = settings.model_copy(update={"log_level": cli_args.log_level})
    return settings
```

Document the full hierarchy in the project README: which variables exist, their defaults, and which are required. A new contributor must be able to run the service locally with only `.env.example` copied to `.env`.

## Secrets Management

Never hardcode secrets in source, configuration files, or container images. Secrets live in the environment (injected by the orchestrator), in a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager), or in mounted files (`secrets_dir` support in pydantic-settings). Treat secret values as unloggable — never emit them in structured logs, trace attributes, or error messages.

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """Settings reading secrets from a mounted directory."""

    db_password: str
    api_secret_key: str

    model_config = SettingsConfigDict(
        secrets_dir="/run/secrets",
        env_prefix="APP_",
    )
```

Rotate secrets without redeploying by reading them at use time rather than caching the value for the process lifetime — but only when the secret backend supports it. For most services, loading once at startup is acceptable; document the rotation procedure so operators know whether a restart is required.

## When to Use

Load this feature file when:
- Setting up a new project's configuration system or replacing scattered `os.getenv` calls
- Migrating hardcoded values (URLs, credentials, feature flags) to environment variables
- Implementing pydantic-settings with validation and fail-fast startup
- Managing secrets without hardcoding them in source or images
- Establishing a config hierarchy (defaults -> env -> CLI) for a multi-environment service
- Applying 12-factor app configuration principles to a Python codebase

## Cross-References

- For binding `LOG_LEVEL` and tracing endpoint configuration into observability: load `observability.md`
- For retry/backoff configuration values that settings often expose: load `resilience.md`
- For packaging configuration into installable distributions: load `packaging.md`
- For project layout where the settings module lives: load `project-structure.md`