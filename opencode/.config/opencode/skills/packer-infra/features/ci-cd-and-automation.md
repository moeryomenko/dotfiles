# CI/CD and Automation

Practical reference for integrating Packer builds into automated pipelines.
All CLI flags and environment variables are verified against the Packer source
code (commit `command/cli.go`, `main.go`, `log.go`, `packer/ui.go`,
`internal/hcp/env/variables.go`, `packer-plugin-sdk/packer/cache.go`).

---

## 1. Command-Line Interface Reference

### `packer build`

Build images from templates. Executes multiple builds in parallel as defined
in the template.

```
packer build [options] TEMPLATE
```

| Flag | Default | Description |
|------|---------|-------------|
| `-color=false` | `true` | Disable color output |
| `-debug` | `false` | Debug mode enabled for builds |
| `-except=foo,bar,baz` | -- | Run all builds and post-processors other than these |
| `-only=foo,bar,baz` | -- | Build only the specified builds |
| `-force` | `false` | Force a build to continue if artifacts exist, deletes existing artifacts |
| `-machine-readable` | `false` | Produce machine-readable output |
| `-on-error` | `cleanup` | `cleanup` (default), `abort`, `ask`, or `run-cleanup-provisioner` |
| `-parallel-builds=N` | `0` | Number of builds to run in parallel. `0` = unlimited. `1` disables parallelization |
| `-timestamp-ui` | `false` | Prefix each UI output with an RFC3339 timestamp |
| `-var 'key=value'` | -- | Variable for templates, can be used multiple times |
| `-var-file=path` | -- | JSON or HCL2 file containing user variables |
| `-warn-on-undeclared-var` | `false` | Show warnings for variable files containing undeclared variables |
| `-ignore-prerelease-plugins` | `false` | Disable loading of prerelease plugin binaries (`x.y.z-dev`) |
| `-use-sequential-evaluation` | `false` | Fallback to sequential approach for local/datasource evaluation |
| `-skip-enforcement` | `false` | Skip injection of HCP Packer enforced provisioners (requires admin privileges) |

Source: [`command/cli.go`](../.ref/command/cli.go#L87-L107),
[`command/build.go`](../.ref/command/build.go#L456-L483)

### `packer validate`

Check that a template is valid. Parses the template and checks configuration
with builders, provisioners, etc. Exits with zero if valid, non-zero on errors.

```
packer validate [options] TEMPLATE
```

| Flag | Default | Description |
|------|---------|-------------|
| `-syntax-only` | `false` | Only check syntax, do not verify config of the template |
| `-except=foo,bar,baz` | -- | Validate all builds other than these |
| `-only=foo,bar,baz` | -- | Validate only these builds |
| `-machine-readable` | `false` | Produce machine-readable output |
| `-var 'key=value'` | -- | Variable for templates, can be used multiple times |
| `-var-file=path` | -- | JSON or HCL2 file containing user variables |
| `-no-warn-undeclared-var` | `false` | Disable warnings for variable files containing undeclared variables |
| `-evaluate-datasources` | `false` | Evaluate data sources during validation (HCL2 only, may incur costs) |
| `-ignore-prerelease-plugins` | `false` | Disable loading of prerelease plugin binaries (`x.y.z-dev`) |
| `-use-sequential-evaluation` | `false` | Fallback to sequential approach for local/datasource evaluation |

Source: [`command/cli.go`](../.ref/command/cli.go#L184-L200),
[`command/validate.go`](../.ref/command/validate.go#L111-L137)

### `packer fmt`

Rewrite Packer HCL2 configuration files to a canonical format. Processes
`.pkr.hcl` and `.pkrvars.hcl` files. JSON files (`.json`) are not modified.

```
packer fmt [options] [TEMPLATE]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-check` | `false` | Check if input is formatted. Exit 0 if all formatted, non-zero otherwise |
| `-diff` | `false` | Display diffs of formatting changes |
| `-write` | `true` | Overwrite source files (always disabled with `-check`) |
| `-recursive` | `false` | Also process files in subdirectories |

If TEMPLATE is `.`, the current directory is used. If `-`, content is read
from STDIN.

Source: [`command/cli.go`](../.ref/command/cli.go#L226-L238),
[`command/fmt.go`](../.ref/command/fmt.go#L75-L98)

### `packer inspect`

Inspect a template, parsing and outputting the components a template defines.
Does not validate template contents (other than basic syntax).

```
packer inspect [options] TEMPLATE
```

| Flag | Default | Description |
|------|---------|-------------|
| `-machine-readable` | `false` | Machine-readable output |
| `-use-sequential-evaluation` | `false` | Fallback to sequential approach for local/datasource evaluation |

Source: [`command/cli.go`](../.ref/command/cli.go#L202-L210),
[`command/inspect.go`](../.ref/command/inspect.go#L61-L76)

### `packer init`

Install missing plugins required by a Packer config. Always safe to run
multiple times -- subsequent runs never delete anything.

```
packer init [options] TEMPLATE
```

| Flag | Default | Description |
|------|---------|-------------|
| `-upgrade` | `false` | Upgrade installed plugins to the latest available version (respects version constraints) |
| `-force` | `false` | Force reinstallation of plugins, even if already installed |

Source: [`command/cli.go`](../.ref/command/cli.go#L144-L156),
[`command/init.go`](../.ref/command/init.go#L174-L198)

### `packer console`

Create an interactive console for testing variable interpolation. If a
template is provided, variables defined therein are loaded into context.

```
packer console [options] [TEMPLATE]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-var 'key=value'` | -- | Variable for templates, can be used multiple times |
| `-var-file=path` | -- | JSON or HCL2 file containing user variables |
| `-config-type` | `json` | Set to `hcl2` to run in HCL2 mode when no file is passed |
| `-use-sequential-evaluation` | `false` | Fallback to sequential approach for local/datasource evaluation |

Source: [`command/cli.go`](../.ref/command/cli.go#L163-L170),
[`command/console.go`](../.ref/command/console.go#L79-L96)

### `packer version`

Print Packer version and check for new releases. No flags.

```
packer version
```

Source: [`command/version.go`](../.ref/command/version.go#L32-L34)

---

## 2. Validate-Before-Build Workflow

The standard CI pipeline for Packer:

```bash
# Step 1: Install required plugins
packer init .

# Step 2: Check formatting (strict mode)
packer fmt -check -recursive .

# Step 3: Validate template syntax and configuration
packer validate .

# Step 4: Build images
packer build .
```

Each step exits non-zero on failure, so the pipeline stops at the first error.
This workflow catches three classes of problems independently:

| Step | Catches |
|------|---------|
| `packer init` | Missing plugins, network errors accessing plugin registry |
| `packer fmt -check` | Formatting inconsistencies, merge artifacts |
| `packer validate` | HCL syntax errors, variable type mismatches, missing required variables, invalid builder/provisioner config |
| `packer build` | Runtime errors (network timeouts, disk full, provisioning failures) |

Separating validate from build also means template errors fail fast (milliseconds)
rather than after a long image build.

---

## 3. Automation Flags

### Variable injection

```bash
# Single variable
packer build -var 'image_name=my-app-v1' .

# Multiple variables
packer build -var 'region=us-east-1' -var 'instance_type=t3.large' .

# Variable files (can be combined with -var)
packer build -var-file=prod.pkrvars.hcl .
packer build -var-file=common.pkrvars.hcl -var-file=env-specific.pkrvars.hcl .

# -var overrides -var-file for the same key
packer build -var-file=base.pkrvars.hcl -var 'version=2.0' .
```

### Build filtering

```bash
# Build only specific sources
packer build -only=amazon-ebs.myapp .
packer build -only=amazon-ebs.* .
packer build -only='*.base-image' .

# Exclude specific sources
packer build -except=qemu.local-test .

# Combine only and except
packer build -only=amazon-ebs.* -except=amazon-ebs.legacy .
```

### Output control

```bash
# Machine-readable for programmatic consumption
packer build -machine-readable .

# Timestamp prefix for correlating log events
packer build -timestamp-ui .

# No colors (log files, CI output)
packer build -color=false .

# Combination for CI
packer build -color=false -timestamp-ui -machine-readable .
```

### Error handling

```bash
# Default: cleanup artifacts and continue other builds
packer build -on-error=cleanup .

# Stop everything immediately on first error
packer build -on-error=abort .

# Prompt (interactive only, not for CI)
packer build -on-error=ask .

# Run the error-cleanup-provisioner on failure
packer build -on-error=run-cleanup-provisioner .
```

### Parallelism

```bash
# Unlimited parallel builds (default)
packer build -parallel-builds=0 .

# Limit to N concurrent builds
packer build -parallel-builds=2 .

# Serial execution (disable parallelization)
packer build -parallel-builds=1 .
```

When `-parallel-builds` is set to `0` (default), Packer uses
`math.MaxInt64` -- effectively unlimited. When `1`, builds run serially.
When `-debug` is set, builds also run serially regardless of this flag.

---

## 4. CI/CD Integration Examples

### GitHub Actions

```yaml
# .github/workflows/packer-build.yml
name: Packer Build

on:
  push:
    branches: [main]
    paths:
      - 'packer/**'
      - '.github/workflows/packer-build.yml'
  pull_request:
    paths:
      - 'packer/**'

env:
  PACKER_LOG: 1
  PACKER_CACHE_DIR: /tmp/packer-cache

jobs:
  validate:
    name: Validate Template
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Packer
        uses: hashicorp/setup-packer@v3
        id: setup
        with:
          version: latest

      - name: Cache Packer plugins
        uses: actions/cache@v4
        with:
          path: /home/runner/.config/packer/plugins
          key: packer-plugins-${{ hashFiles('packer/**/*.pkr.hcl') }}
          restore-keys: |
            packer-plugins-

      - name: Cache ISO downloads
        uses: actions/cache@v4
        with:
          path: /tmp/packer-cache
          key: packer-isos-${{ hashFiles('packer/**/*.pkr.hcl') }}

      - run: packer init ./packer
      - run: packer fmt -check -recursive ./packer
      - run: packer validate ./packer

  build:
    name: Build Images
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    strategy:
      matrix:
        builder: [amazon-ebs, qemu]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Packer
        uses: hashicorp/setup-packer@v3
        with:
          version: latest

      - name: Cache Packer plugins
        uses: actions/cache@v4
        with:
          path: /home/runner/.config/packer/plugins
          key: packer-plugins-${{ hashFiles('packer/**/*.pkr.hcl') }}

      - name: Cache ISO downloads
        uses: actions/cache@v4
        with:
          path: /tmp/packer-cache
          key: packer-isos-${{ hashFiles('packer/**/*.pkr.hcl') }}

      - name: Build ${{ matrix.builder }} image
        run: |
          packer init ./packer
          packer build \
            -only=${{ matrix.builder }}.* \
            -var-file=./packer/ci.pkrvars.hcl \
            -color=false \
            -timestamp-ui \
            -parallel-builds=2 \
            ./packer
        env:
          # AWS credentials for EBS builder
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          # HCP Packer registry (optional)
          HCP_CLIENT_ID: ${{ secrets.HCP_CLIENT_ID }}
          HCP_CLIENT_SECRET: ${{ secrets.HCP_CLIENT_SECRET }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
variables:
  PACKER_LOG: "1"
  PACKER_CACHE_DIR: "${CI_PROJECT_DIR}/.packer-cache"

stages:
  - validate
  - build
  - push

.cache-packer:
  cache:
    key: packer-plugins-$CI_COMMIT_REF_SLUG
    paths:
      - .packer-cache/plugins/

packer-validate:
  stage: validate
  image:
    name: hashicorp/packer:latest
    entrypoint: [""]
  script:
    - packer init .
    - packer fmt -check -recursive .
    - packer validate .
  cache:
    key: packer-plugins-$CI_COMMIT_REF_SLUG
    paths:
      - .packer-cache/

# Parallel builds per platform
packer-build-amazon-ebs:
  stage: build
  image:
    name: hashicorp/packer:latest
    entrypoint: [""]
  script:
    - packer init .
    - packer build
        -only=amazon-ebs.*
        -var-file=ci.pkrvars.hcl
        -color=false
        -timestamp-ui
        -machine-readable
        -on-error=abort
        .
  artifacts:
    paths:
      - manifest.json
    expire_in: 30 days
  only:
    - main

packer-build-qemu:
  stage: build
  image:
    name: hashicorp/packer:latest
    entrypoint: [""]
  script:
    - packer init .
    - packer build
        -only=qemu.*
        -var-file=ci.pkrvars.hcl
        -color=false
        -timestamp-ui
        -parallel-builds=1
        -on-error=abort
        .
  artifacts:
    paths:
      - output-qemu/
    expire_in: 30 days
  only:
    - main

push-to-registry:
  stage: push
  image:
    name: hashicorp/packer:latest
    entrypoint: [""  ]
  script:
    - echo "Pushing artifacts to image registry..."
    # Consume build artifacts from previous stages
  needs:
    - packer-build-amazon-ebs
    - packer-build-qemu
  only:
    - main
```

### Local Automation (Makefile)

```makefile
# Makefile
PACKER_DIR ?= .
VAR_FILE ?= prod.pkrvars.hcl

.PHONY: init validate fmt build clean

init:
	packer init $(PACKER_DIR)

validate: init
	packer validate $(PACKER_DIR)

fmt:
	packer fmt -recursive $(PACKER_DIR)

fmt-check:
	packer fmt -check -recursive $(PACKER_DIR)

build: validate
	packer build \
		-parallel-builds=2 \
		-var-file=$(VAR_FILE) \
		-color=false \
		-timestamp-ui \
		$(PACKER_DIR)

# Selective build for development
build-only:
	packer build \
		-parallel-builds=1 \
		-only=$(FILTER) \
		-var-file=$(VAR_FILE) \
		-color=false \
		$(PACKER_DIR)

# Full pipeline
all: fmt-check validate build

# Clean cache
clean:
	rm -rf output-* packer_cache manifest.json
```

---

## 5. Parallel Builds

Packer executes all source blocks in a template concurrently by default.
The `-parallel-builds` flag controls this behavior.

### Behavior

| Value | Behavior |
|-------|----------|
| `-parallel-builds=0` | Unlimited concurrency (default, maps to `math.MaxInt64` internally) |
| `-parallel-builds=N` | At most N builds run simultaneously |
| `-parallel-builds=1` | Serial execution, one build at a time |

### Resource contention considerations

When running multiple builds in parallel, especially with the QEMU builder:

- **Disk space**: Each parallel QEMU build can consume 10-50 GB. With 4 parallel
  builds, 200 GB+ of free disk may be needed.
- **Memory**: Each VM gets its own memory allocation. Sum of all VM memory must
  fit in available RAM.
- **CPU**: CPU oversubscription is generally fine, but extreme contention slows
  all builds.
- **Network**: Multiple concurrent ISO downloads can saturate bandwidth.
  Use ISO caching (`PACKER_CACHE_DIR`) to avoid re-downloads.

### Selective parallelism with `-only`

```bash
# Build only AMI sources, in parallel
packer build -only=amazon-ebs.* .

# Build a single source (implies -parallel-builds=1 for that source)
packer build -only=amazon-ebs.base-image .

# Build multiple specific sources
packer build -only=amazon-ebs.base-image,qemu.ubuntu-2204 .
```

---

## 6. Error Handling

### `-on-error` modes

| Mode | Behavior |
|------|----------|
| `cleanup` | (Default) Clean up any created resources, report error, continue other builds |
| `abort` | Stop immediately without cleanup. Other builds continue until they finish or error |
| `ask` | Prompt user for action (interactive only, not suitable for CI) |
| `run-cleanup-provisioner` | Run the `error-cleanup-provisioner` provisioner on the instance before cleanup |

Source: [`command/cli.go`](../.ref/command/cli.go#L96)

### Error-cleanup provisioner pattern

```hcl
# HCL template with cleanup provisioner
source "qemu" "ubuntu" {
  iso_url          = "https://releases.ubuntu.com/22.04/ubuntu-22.04-server-amd64.iso"
  iso_checksum     = "sha256:..."
  ssh_username     = "ubuntu"
  ssh_password     = "temporary"
  shutdown_command = "echo 'temporary' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "echo 'Configuring system...'",
      "sudo apt-get update -qq",
      "sudo apt-get install -y -qq nginx",
    ]
  }

  # Runs when -on-error=run-cleanup-provisioner
  provisioner "shell" {
    only_on_error = true

    inline = [
      "echo 'Error encountered, running cleanup...'",
      "sudo rm -rf /var/log/installer",
    ]
  }
}
```

The `error-cleanup-provisioner` is a provisioner block with
`only_on_error = true`. It runs only when the build fails and
`-on-error=run-cleanup-provisioner` is set. Use it to upload debug logs,
snapshot the failed state, or tear down partial resources.

---

## 7. Machine-Readable Output

### Format

The `-machine-readable` flag produces structured output parsable by scripts.
Each line follows:

```
timestamp,target,type,data...
```

Fields are comma-separated. Timestamps are Unix epoch in milliseconds.

Source: [`packer/ui.go`](../.ref/packer/ui.go#L188-L230)

### Parsing with awk

```bash
# Extract artifact IDs (e.g., AMI IDs)
packer build -machine-readable . 2>&1 | \
  awk -F, '$3 == "artifact" && $4 == "id" {print $5}'

# Extract error messages
packer build -machine-readable . 2>&1 | \
  awk -F, '$3 == "error" {print $0}'

# Extract build status
packer build -machine-readable . 2>&1 | \
  awk -F, '$3 == "error-count" {print "Builds failed: " $4}'
```

### Parsing with jq (via structured output)

Packers machine-readable output is CSV-like, not JSON. For structured
reporting, wrap the build in a script that produces JSON:

```bash
#!/bin/bash
# build-report.sh — run packer build and produce JSON status report
set -euo pipefail

TEMPLATE="${1:-.}"
START_TS=$(date -u +%s)

# Run build; capture exit code
set +e
packer build -machine-readable -color=false "$TEMPLATE" 2>&1
EXIT_CODE=$?
set -e

END_TS=$(date -u +%s)

# Build JSON report
cat <<EOF
{
  "template": "$TEMPLATE",
  "exit_code": $EXIT_CODE,
  "duration_seconds": $((END_TS - START_TS)),
  "timestamp": "$(date -u -Iseconds)",
  "status": "$([ $EXIT_CODE -eq 0 ] && echo 'success' || echo 'failure')"
}
EOF
exit $EXIT_CODE
```

---

## 8. Environment Variables

### Packer core

| Variable | Description | Source |
|----------|-------------|--------|
| `PACKER_CONFIG` | Path to Packer config file (JSON) | [`main.go:355`](../.ref/main.go#L355) |
| `PACKER_LOG` | Enable debug logging. Set to `1` to enable, `0` to disable | [`log.go:17`](../.ref/log.go#L17) |
| `PACKER_LOG_PATH` | Write logs to a file instead of stderr | [`log.go:18`](../.ref/log.go#L18) |
| `PACKER_NO_COLOR` | Disable colored output (set to any non-empty value). Automatically set when `-machine-readable` is used | [`packer/ui.go:104`](../.ref/packer/ui.go#L104) |
| `PACKER_PLUGIN_PATH` | Single directory path for plugin binaries (no longer supports multiple paths) | [`packer/plugin_folders.go:20`](../.ref/packer/plugin_folders.go#L20) |
| `PACKER_PLUGIN_MIN_PORT` | Minimum port for plugin communication | [`packer/plugin_client.go:224`](../.ref/packer/plugin_client.go#L224) |
| `PACKER_PLUGIN_MAX_PORT` | Maximum port for plugin communication | [`packer/plugin_client.go:225`](../.ref/packer/plugin_client.go#L225) |
| `PACKER_CACHE_DIR` | Override the cache directory for ISO downloads and other cached files. Default: `$HOME/.cache/packer` on Unix | [`packer-plugin-sdk/packer/cache.go:39`](../.ref/sdk-cache.go#L39) |
| `PACKER_RUN_UUID` | UUID generated for each Packer run (set automatically, read for tracking) | [`main.go:58`](../.ref/main.go#L58) |

### HCP Packer

| Variable | Description | Source |
|----------|-------------|--------|
| `HCP_CLIENT_ID` | HCP client credential ID | [`internal/hcp/env/variables.go:7`](../.ref/hcp-env-vars.go#L7) |
| `HCP_CLIENT_SECRET` | HCP client credential secret | [`internal/hcp/env/variables.go:8`](../.ref/hcp-env-vars.go#L8) |
| `HCP_CRED_FILE` | Path to HCP credential file | [`internal/hcp/env/variables.go:9`](../.ref/hcp-env-vars.go#L9) |
| `HCP_PROJECT_ID` | HCP project ID | [`internal/hcp/env/variables.go:13`](../.ref/hcp-env-vars.go#L13) |
| `HCP_ORGANIZATION_ID` | HCP organization ID | [`internal/hcp/env/variables.go:14`](../.ref/hcp-env-vars.go#L14) |
| `HCP_PACKER_REGISTRY` | Enable/disable HCP Packer registry. Set to `off` or `0` to disable | [`internal/hcp/env/variables.go:15`](../.ref/hcp-env-vars.go#L15) |
| `HCP_PACKER_BUCKET_NAME` | Override the HCP Packer bucket name | [`internal/hcp/env/variables.go:16`](../.ref/hcp-env-vars.go#L16) |
| `HCP_PACKER_BUILD_FINGERPRINT` | Set a custom build fingerprint | [`internal/hcp/env/variables.go:17`](../.ref/hcp-env-vars.go#L17) |

### Typical CI usage

```bash
# Enable debug logging for troubleshooting
export PACKER_LOG=1
export PACKER_LOG_PATH=packer-build.log

# Disable colors for log files
export PACKER_NO_COLOR=1

# Use a workspace-local cache directory
export PACKER_CACHE_DIR="${CI_PROJECT_DIR}/.packer-cache"

# HCP Packer registry auth
export HCP_CLIENT_ID="${HCP_CLIENT_ID}"
export HCP_CLIENT_SECRET="${HCP_CLIENT_SECRET}"
export HCP_PACKER_BUCKET_NAME="my-org-images"
```

---

## 9. Caching Strategies

### ISO caching

Packer caches downloaded ISO files in the directory returned by
`CachePath()`. On Unix, resolution order:

1. `PACKER_CACHE_DIR` env var (highest priority)
2. `XDG_CACHE_HOME`/packer (if `PACKER_CACHE_DIR` is unset)
3. `$HOME/.cache/packer` (default fallback)

Source: [`packer-plugin-sdk/packer/cache.go`](../.ref/sdk-cache.go#L33-L44)

```bash
# Explicit cache directory
export PACKER_CACHE_DIR=/mnt/nvme/packer-cache

# CI: Use workspace to persist between steps
export PACKER_CACHE_DIR="${CI_PROJECT_DIR}/.packer-cache"
```

### Plugin caching

`packer init` downloads plugins to the `PACKER_PLUGIN_PATH` directory
(default: `~/.config/packer/plugins`). Cache this directory in CI to
avoid re-downloading on every run.

```yaml
# GitHub Actions — cache plugins and ISOs
- uses: actions/cache@v4
  with:
    path: |
      ~/.config/packer/plugins
      /tmp/packer-cache
    key: packer-${{ hashFiles('packer/**/*.pkr.hcl') }}
```

### Workspace caching in CI

```yaml
# GitLab CI — cache between pipelines
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .packer-cache/    # ISO cache (PACKER_CACHE_DIR)
    - .packer-plugins/  # Plugin cache (PACKER_PLUGIN_PATH)
```

---

## 10. Multi-Project Orchestration

### Sequential dependent builds

When images have dependencies (base OS -> middleware -> application), use a
script or Makefile to orchestrate the build order:

```bash
#!/bin/bash
# orchestrate-builds.sh
set -euo pipefail

# Phase 1: Base OS images
echo "=== Building base OS images ==="
packer build -var-file=common.pkrvars.hcl -only=qemu.ubuntu-base ./images/base/

# Phase 2: Middleware images (depend on base)
echo "=== Building middleware images ==="
packer build -var-file=common.pkrvars.hcl -only=qemu.nginx-base ./images/middleware/

# Phase 3: Application images (depend on middleware)
echo "=== Building application images ==="
packer build -var-file=common.pkrvars.hcl -only=qemu.myapp ./images/app/
```

### Makefile orchestration

```makefile
# Makefile — multi-project orchestration
BASE_DIR    := ./images/base
MIDDLE_DIR  := ./images/middleware
APP_DIR     := ./images/app
VAR_FILE    := prod.pkrvars.hcl

.PHONY: all base middleware app

all: base middleware app

base:
	packer init $(BASE_DIR)
	packer validate $(BASE_DIR)
	packer build -var-file=$(VAR_FILE) $(BASE_DIR)

middleware: base
	packer init $(MIDDLE_DIR)
	packer validate $(MIDDLE_DIR)
	packer build -var-file=$(VAR_FILE) $(MIDDLE_DIR)

app: middleware
	packer init $(APP_DIR)
	packer validate $(APP_DIR)
	packer build -var-file=$(VAR_FILE) $(APP_DIR)
```

### Terraform integration

After building an image, consume its ID in Terraform:

```bash
#!/bin/bash
# build-and-deploy.sh
set -euo pipefail

# Build image; extract artifact ID
packer build -machine-readable -var-file=prod.pkrvars.hcl . 2>&1 | \
  tee /tmp/packer-output.txt

# Extract AMI ID from machine-readable output
AMI_ID=$(awk -F, '/artifact.*id/{print $NF}' /tmp/packer-output.txt)

# Pass to Terraform
export TF_VAR_ami_id="$AMI_ID"
terraform -chdir=./deploy init
terraform -chdir=./deploy apply -auto-approve
```

For QEMU builds, consume the output artifact path:

```bash
# Extract QEMU image path
IMAGE_PATH=$(awk -F, '/artifact.*file/{print $NF}' /tmp/packer-output.txt)

# Copy to deployment location
cp "$IMAGE_PATH" /var/lib/libvirt/images/app.qcow2
```

---

## 11. Secret Management

### Sensitive variables via environment

Packer resolves variables in HCL2 templates using the `env` function.
Use environment variables for secrets instead of plaintext in variable files:

```hcl
// variables.pkr.hcl
variable "db_password" {
  type      = string
  sensitive = true
}

variable "api_token" {
  type      = string
  sensitive = true
}
```

```bash
# Set secrets via environment (not in var files)
export PKR_VAR_db_password="$(vault read ...)"
export PKR_VAR_api_token="$(vault read ...)"

# Variables prefixed with PKR_VAR_ are automatically picked up
packer build .
```

### `sensitive` variable marking

Variables marked `sensitive = true` are redacted from UI output and logs.
Packer scrubs their values with `LogSecretFilter`:

Source: [`packer/ui.go:311`](../.ref/packer/ui.go#L311-L313)

### Restricted var-file permissions

```bash
# Create a var-file with secrets
cat > secrets.pkrvars.hcl << 'EOF'
db_password = "s3cr3t"
api_token   = "tok3n"
EOF

# Restrict permissions (owner read-only)
chmod 400 secrets.pkrvars.hcl

# Use it
packer build -var-file=secrets.pkrvars.hcl .
```

### HCP Packer Registry for secret propagation

When using HCP Packer, build metadata (including variable names but not
sensitive values) is tracked in the registry. The `GetCleanedBuildArgs`
function in Packer strips variable values, keeping only key names:

Source: [`command/cli.go:114-131`](../.ref/command/cli.go#L114-L131)

### CI secret injection

```yaml
# GitHub Actions — inject secrets as Packer variables
- name: Build image
  run: packer build -var-file=prod.pkrvars.hcl .
  env:
    PKR_VAR_db_password: ${{ secrets.DB_PASSWORD }}
    PKR_VAR_api_token: ${{ secrets.API_TOKEN }}
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

---

## References

- Source files verified against: `command/cli.go`, `main.go`, `log.go`,
  `packer/ui.go`, `internal/hcp/env/variables.go`,
  `packer-plugin-sdk/packer/cache.go`
- Packer documentation: <https://developer.hashicorp.com/packer/docs/commands>
- HCP Packer documentation:
  <https://developer.hashicorp.com/packer/docs/hcp>
