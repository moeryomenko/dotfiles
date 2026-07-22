# HCP Packer Registry

HCP Packer Registry is a managed service for tracking VM image metadata across
the image lifecycle. It acts as a central catalog: Packer pushes build metadata
on every run, and downstream tools (Terraform, other Packer builds) consume
published image identifiers by channel.

This document covers registry integration from the Packer side (publishing) and
the consumer side (Terraform data sources). It is based on the registry client
in `internal/hcp/registry/`.

---

## What HCP Packer Registry Provides

| Capability | Description |
|---|---|
| **Image metadata management** | Bucket-based image catalog with versioned metadata (fingerprints, labels, artifacts). |
| **Version tracking** | Every Packer run creates or updates a version. Fingerprints provide deduplication -- re-running with the same fingerprint resumes the same version. |
| **Channel-based promotion** | Assign versions to channels (e.g., `development`, `staging`, `production`). Consumers pin to a channel and always get the latest assigned version. |
| **Enforced provisioners** | HCP stores provisioner blocks that Packer auto-injects into every build for that bucket. Used for compliance (security scanners, hardening scripts). |
| **Artifact registry** | Stores cloud-specific image identifiers (AMI IDs, GCE image names, QEMU disk paths) keyed by platform and region. |
| **SBOM support** | `hcp-sbom` provisioner generates or uploads Software Bill of Materials (SPDX/CycloneDX) and attaches them to the version. |
| **Terraform integration** | Terraform data sources (`hcp_packer_iteration`, `hcp_packer_version`, `hcp_packer_image`, `hcp_packer_artifact`) consume published images for infrastructure provisioning. |

---

## Authentication

The registry client authenticates to HCP using one of two methods.

### Client Credentials (Recommended)

```
export HCP_CLIENT_ID=...
export HCP_CLIENT_SECRET=...
export HCP_PROJECT_ID=...
```

Credentials are obtained by creating an HCP Service Principal in the HCP
Portal. The service principal must have the `Packer Registry` permission on the
target project.

### Credential File

Place a credential file at `~/.config/hcp/cred_file.json` or set:

```
export HCP_CRED_FILE=/path/to/cred_file.json
```

### Disable HCP Registry

To skip all HCP integration (useful for local testing):

```
export HCP_PACKER_REGISTRY=off
```

### Authentication Check

The registry calls `env.HasHCPAuth()` which checks for `HCP_CLIENT_ID` +
`HCP_CLIENT_SECRET` OR a valid credential file. If neither is present, Packer
emits a diagnostic error pointing to the required variables:

```
Error: HCP authentication information required
```

---

## HCL2 Configuration Blocks

### Top-Level `hcp_packer_registry`

Defined at the Packer config root. Since Packer 1.12.1 this is the recommended
location (per-block is deprecated).

```hcl
hcp_packer_registry {
  bucket_name  = "ubuntu-22-04"
  description  = "Ubuntu 22.04 LTS golden images"
  bucket_labels = {
    os         = "ubuntu"
    version    = "22.04"
    team       = "platform"
  }
  build_labels = {
    environment = "production"
  }
  channels = ["production", "staging"]
}
```

| Attribute | Type | Required | Description |
|---|---|---|---|
| `bucket_name` | `string` | no* | 3-36 chars, `[a-zA-Z0-9-]`. Falls back to `HCP_PACKER_BUCKET_NAME` env var. |
| `description` | `string` | no | Max 255 characters. |
| `bucket_labels` | `map(string)` | no | Labels applied to the bucket itself. |
| `build_labels` | `map(string)` | no | Labels applied to each build in the version. |
| `channels` | `list(string)` | no | Channels to assign the version to on completion. |
| `labels` | `map(string)` | no | **Deprecated**. Use `bucket_labels` instead. |

\* Required in practice -- either `bucket_name` or `HCP_PACKER_BUCKET_NAME` must
be set.

### Per-Build `build { hcp_packer_registry { ... } }`

**Deprecated** since Packer 1.12.1. Still supported with a deprecation warning.

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  hcp_packer_registry {
    bucket_name  = "ubuntu-22-04"
    description  = "Ubuntu 22.04 built with amazon-ebs"
    build_labels = {
      builder = "amazon-ebs"
    }
  }

  provisioner "shell" {
    inline = ["echo 'hello'"]
  }
}
```

### Complete Annotated Example

```hcl
# HCP Packer Registry configuration -- top-level block
hcp_packer_registry {
  # Bucket slug: 3-36 alphanumeric chars and hyphens
  bucket_name  = "rhel-9-golden"

  # Description shows in HCP Packer UI
  description  = "RHEL 9 golden images with CIS hardening"

  # Labels on the bucket itself
  bucket_labels = {
    os         = "rhel"
    major      = "9"
    compliance = "cis-level1"
  }

  # Labels injected into every build in this template
  build_labels = {
    automated = "true"
  }

  # Channels to auto-assign on version completion
  channels = ["development"]
}

# Sources reference
source "qemu" "rhel-9" {
  iso_url          = "https://example.com/rhel-9.iso"
  iso_checksum     = "sha256:..."
  ssh_username     = "root"
  shutdown_command = "shutdown -P now"
}

# Build block
build {
  sources = ["source.qemu.rhel-9"]

  provisioner "shell" {
    inline = [
      "dnf install -y cloud-init",
      "systemctl enable cloud-init",
    ]
  }

  # Build-level hcp_packer_registry is DEPRECATED but still works.
  # When present alongside a top-level block, Packer emits an error.
}
```

### Configuration Priority

The `GetHCPPackerRegistryBlock()` method resolves configuration in this order:

1. Top-level `hcp_packer_registry` block (highest priority)
2. Per-build `hcp_packer_registry` block (deprecated, emits warning)
3. `HCP_PACKER_BUCKET_NAME` environment variable (fallback)

If both top-level and per-build blocks exist, Packer emits a diagnostic error.

---

## Image Lifecycle

### Version Creation Flow

```
Packer build starts
       |
       v
  Registry.New(cfg, ui)       <- checks HCP_PACKER_REGISTRY env, template blocks
       |
       v
  IsHCPEnabled(cfg)           <- true if any config source enables HCP
       |
       v
  createConfiguredBucket()    <- reads template dir, env vars, config blocks
       |
       v
  Bucket.Initialize()         <- upserts bucket, creates/gets version by fingerprint
       |
       v
  populateVersion()           <- registers expected builds, creates missing builds
       |
       v
  StartBuild()                <- sets status to RUNNING, starts heartbeat goroutine
       |
       v
  (provisioning runs...)      <- enforced provisioners are injected here
       |
       v
  CompleteBuild()             <- uploads artifacts, marks build DONE, updates channels
       |
       v
  registryArtifact returned   <- contains bucket name + version ID
```

### Fingerprint-Based Deduplication

Every version is identified by a **fingerprint** -- a ULID generated at startup
or passed via `HCP_PACKER_BUILD_FINGERPRINT`. This enables resuming:

```bash
# First run creates the version
packer build template.pkr.hcl

# Resume same version (e.g., after a build failure)
export HCP_PACKER_BUILD_FINGERPRINT="01ARZ3NDEKTSV4RRFFQ69G5FAV"
packer build template.pkr.hcl
```

If the fingerprint already exists and the version is complete, Packer errors:

```
The version associated to the fingerprint <fp> is complete.
If you wish to add a new build to this bucket a new version must be
created by changing the fingerprint.
```

### Build Lifecycle States

| State | Description |
|---|---|
| `BUILD_UNSET` | Initial state on build creation |
| `BUILD_RUNNING` | Set by `StartBuild()`, maintained by heartbeat goroutine |
| `BUILD_DONE` | Set by `CompleteBuild()` -- only after artifacts are published |
| `BUILD_FAILED` | Set when provisioning or artifact upload fails |
| `BUILD_CANCELLED` | Set when context is cancelled (SIGINT/SIGTERM) |

Heartbeat goroutine sends status updates every 2 minutes (`HeartbeatPeriod`) to
prevent HCP from marking the build as timed out.

### Example: Full Registry Flow from Template to Published Image

```hcl
# ubuntu-22-04.pkr.hcl
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "build_type" {
  type    = string
  default = "release"
}

hcp_packer_registry {
  bucket_name  = "ubuntu-22-04"
  description  = "Ubuntu 22.04 LTS server image"
  bucket_labels = {
    os      = "ubuntu"
    version = "22.04"
  }
  build_labels = {
    build_type = var.build_type
  }
  channels = ["development"]
}

source "qemu" "ubuntu" {
  iso_url          = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
  iso_checksum     = "sha256:a4ac5da8b..."
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  memory           = 2048
  disk_size        = 20G
  cpus             = 2
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y cloud-init qemu-guest-agent",
    ]
  }

  # After build completes:
  #  1. QEMU disk artifact is registered in HCP as platform=qemu
  #  2. Version is assigned to "development" channel
  #  3. Output: Published metadata to HCP Packer registry packer/ubuntu-22-04/versions/<id>
}
```

---

## Channels

Channels provide a stable name for consumers to reference the latest version.
They model promotion: a version built for `development` can later be assigned
to `staging` and then `production`.

### Configuring Channels in the Template

```hcl
hcp_packer_registry {
  bucket_name = "ubuntu-22-04"
  channels    = ["development"]
}
```

When the build completes, the version is automatically assigned to
`development`. Multiple channels can be specified:

```hcl
channels = ["staging", "production"]
```

### Command-Line Channel Assignment

Channels can also be specified via CLI (verify your Packer version docs):

```bash
packer build -channel=development template.pkr.hcl
packer build -channel=staging -channel=production template.pkr.hcl
```

### Channel-Based Image Consumption in Terraform

```hcl
data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "ubuntu-22-04"
  channel     = "staging"
}

# This retrieves the latest complete version assigned to "staging"
```

### Promoting Images Between Channels

Promotion is done outside of Packer -- typically via the HCP UI, API, or
`hcp` CLI:

```bash
# Assign a specific version fingerprint to the production channel
hcp packer channels update production \
  --bucket ubuntu-22-04 \
  --version-fingerprint "01ARZ3NDEKTSV4RRFFQ69G5FAV"
```

---

## Enforced Provisioners

Enforced provisioners are HCP-managed provisioner blocks stored in the HCP
Packer Registry and auto-injected into every build for a given bucket.

### How They Work

1. **Admin defines** provisioner blocks in the HCP Packer UI/API at the
   bucket level (e.g., a security scanning agent install script).
2. **Packer fetches** them during `FetchEnforcedBlocks()` -- called after
   `Initialize()` during the registry setup phase.
3. **Packer injects** them via `InjectEnforcedProvisioners()` -- called before
   provisioning starts. The provisioner blocks are parsed from HCL content and
   appended to each build's provisioner list.
4. **Template authors** do NOT need to add them -- they are injected
   automatically.

### Compliance Use Case

Every image built in the `production` bucket must include a security scanning
agent:

```
+------------------------------------------------------------------+
|  HCP Packer Registry                                             |
|  +------------------------------------------------------------+  |
|  | Bucket: "production-images"                                |  |
|  | Enforced Blocks:                                           |  |
|  |   provisioner "shell" {                                    |  |
|  |     script = "install-security-agent.sh"                   |  |
|  |   }                                                        |  |
|  +------------------------------------------------------------+  |
+--------------------------+---------------------------------------+
                           |
                           | FetchEnforcedBlocks()
                           v
+------------------------------------------------------------------+
|  Packer Build                                                    |
|  +------------------------------------------------------------+  |
|  | Provisioners:                                              |  |
|  |  [0] template-defined provisioners                         |  |
|  |  [1] ENFORCED: install-security-agent                      |  |  <- injected
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

### `only` / `except` Rules

Enforced provisioners can use `only` and `except` to target specific build
types. The `OnlyExcept.Skip(buildType)` call is evaluated for each build:

```hcl
# In HCP Packer enforced block -- applies to all builds EXCEPT docker
provisioner "shell" {
  except = ["docker"]
  script = "install-security-agent.sh"
}
```

### Implementation Reference

Key methods:

| Method | Location | Purpose |
|---|---|---|
| `FetchEnforcedBlocks(ctx)` | `types.bucket.go` | Calls HCP API to retrieve enforced blocks for the bucket |
| `InjectEnforcedProvisioners(builds)` | `hcl.go` (HCL), `json.go` (JSON) | Parses block content into provisioner blocks and appends to each build |
| `ParseProvisionerBlocks(content)` | `hcl2template/enforced_provisioner_parser.go` | Parses raw HCL string into `ProvisionerBlock` slices |

If a `NotFound` or `Unimplemented` error is returned from the API, Packer
continues silently -- enforced provisioners are a soft feature.

---

## Datasource Integration for Terraform

Terraform consumes HCP Packer images via data sources in the `hashicorp/hcp`
provider.

### `hcp_packer_version` (Recommended)

Replaces the deprecated `hcp_packer_iteration`. Retrieves version metadata from
a channel.

```hcl
data "hcp_packer_version" "ubuntu" {
  bucket_name  = "ubuntu-22-04"
  channel_name = "production"
}
```

Output fields: `author_id`, `bucket_name`, `status`, `created_at`,
`fingerprint`, `id`, `name`, `updated_at`, `channel_id`.

### `hcp_packer_iteration` (Deprecated)

Older data source replaced by `hcp_packer_version`.

```hcl
data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "ubuntu-22-04"
  channel     = "production"
}
```

Output fields: `author_id`, `bucket_name`, `complete`, `created_at`,
`fingerprint`, `id`, `incremental_version`, `updated_at`, `channel_id`.

### `hcp_packer_artifact` (Recommended)

Replaces the deprecated `hcp_packer_image`. Retrieves specific artifact
details (image ID, region, labels) by platform.

```hcl
data "hcp_packer_artifact" "ubuntu-qemu" {
  bucket_name    = "ubuntu-22-04"
  channel_name   = data.hcp_packer_version.ubuntu.channel_name
  platform       = "qemu"
  region         = "local"
  component_type = "qemu.ubuntu"
}
```

Output fields: `platform`, `component_type`, `created_at`, `build_id`,
`version_id`, `channel_id`, `packer_run_uuid`, `external_identifier`,
`region`, `labels`.

Parameters: `channel_name` and `version_fingerprint` are mutually exclusive;
one must be set.

### `hcp_packer_image` (Deprecated)

Older data source replaced by `hcp_packer_artifact`.

```hcl
data "hcp_packer_image" "ubuntu-aws" {
  bucket_name    = "ubuntu-22-04"
  iteration_id   = data.hcp_packer_iteration.ubuntu.id
  cloud_provider = "aws"
  region         = "us-east-1"
}
```

### Complete Terraform Example

```hcl
# Configure the HCP provider
provider "hcp" {
  # Uses HCP_CLIENT_ID and HCP_CLIENT_SECRET env vars
}

# --- Lookup version from channel ---

# Find the latest version assigned to "production"
data "hcp_packer_version" "ubuntu" {
  bucket_name  = "ubuntu-22-04"
  channel_name = "production"
}

# --- AWS AMI ---

data "hcp_packer_artifact" "ubuntu-aws" {
  bucket_name    = "ubuntu-22-04"
  channel_name   = data.hcp_packer_version.ubuntu.channel_name
  platform       = "aws"
  region         = "us-east-1"
  component_type = "amazon-ebs.ubuntu"
}

resource "aws_instance" "web" {
  ami           = data.hcp_packer_artifact.ubuntu-aws.external_identifier
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.main.id
}

# --- GCP Image ---

data "hcp_packer_artifact" "ubuntu-gcp" {
  bucket_name    = "ubuntu-22-04"
  channel_name   = data.hcp_packer_version.ubuntu.channel_name
  platform       = "gce"
  region         = "us-central1"
  component_type = "googlecompute.ubuntu"
}

resource "google_compute_instance" "web" {
  name         = "web"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = data.hcp_packer_artifact.ubuntu-gcp.external_identifier
    }
  }
}

# --- QEMU/local ---

data "hcp_packer_artifact" "ubuntu-qemu" {
  bucket_name    = "ubuntu-22-04"
  channel_name   = data.hcp_packer_version.ubuntu.channel_name
  platform       = "qemu"
  region         = "local"
  component_type = "qemu.ubuntu"
}

# The external_identifier for QEMU images is the path to the disk image
locals {
  qemu_image_path = data.hcp_packer_artifact.ubuntu-qemu.external_identifier
}

output "ami_id" {
  value = data.hcp_packer_artifact.ubuntu-aws.external_identifier
}

output "qemu_disk_path" {
  value = local.qemu_image_path
}
```

### Data Source Deprecation Summary

| Old (Deprecated) | New (Recommended) |
|---|---|
| `hcp_packer_iteration` | `hcp_packer_version` |
| `hcp_packer_image` | `hcp_packer_artifact` |

---

## SBOM Support

The `hcp-sbom` provisioner integrates Software Bill of Materials generation
into the HCP Packer Registry workflow.

### How It Works

1. SBOM is generated (or provided via `source`) during the build.
2. The provisioner compresses and stores the SBOM as a `packer.SBOM`.
3. On `CompleteBuild()`, the SBOM is uploaded via `bucket.uploadSbom()` to the
   HCP API and attached to the version's build.
4. SBOMs are visible in the HCP Packer UI alongside version metadata.

### Provisioner Configuration

```hcl
build {
  sources = ["source.qemu.ubuntu"]

  # Generate SBOM automatically using embedded Syft
  provisioner "hcp-sbom" {
    auto_generate = true
    scan_path     = "/"
    scanner_args  = ["-o", "cyclonedx-json"]
  }

  # OR: provide a pre-generated SBOM file from the guest
  # provisioner "hcp-sbom" {
  #   source      = "/tmp/sbom.json"
  #   destination = "./sbom-output.json"
  #   sbom_name   = "ubuntu-22-04-sbom"
  # }
}
```

### Key Parameters

| Parameter | Type | Description |
|---|---|---|
| `source` | `string` | Path to pre-generated SBOM file on guest. Mutually exclusive with `auto_generate`. |
| `auto_generate` | `bool` | Enable automatic SBOM generation (Syft-based). Requires Packer binary upload to guest. |
| `scanner_args` | `list(string)` | Arguments to `packer sbom-generate`. Default: `["-o", "cyclonedx-json"]`. |
| `scan_path` | `string` | Path to scan. Default: `/`. |
| `destination` | `string` | Local path to save a copy of the SBOM. |
| `sbom_name` | `string` | Custom name for the SBOM in HCP (3-36 chars, `[A-Za-z0-9_-]`). |
| `execute_command` | `string` | Custom template for scanner execution command. |
| `elevated_user` | `string` | Windows elevated user. |
| `elevated_password` | `string` | Windows elevated password. |

### Supported Formats

- CycloneDX JSON (default)
- SPDX JSON

The provisioner auto-detects the format from the SBOM content.

---

## Metadata Gathering

The `MetadataStore` automatically collects environment metadata and attaches it
to every build. This happens during `CompleteBuild()` via
`Version.AddMetadataToBuild()`.

### OS Metadata

Collected by `metadata.GetOSMetadata()` (from
`internal/hcp/registry/metadata/os.go`):

| Field | Source |
|---|---|
| OS type | `runtime.GOOS` (linux, darwin, windows) |
| Architecture | `runtime.GOARCH` |
| Kernel version | `uname -srio` (Linux), `uname -srm` (macOS/BSD), `cmd /c ver` (Windows) |

### CI/CD Metadata

Auto-detected by `metadata.GetCicdMetadata()` (from
`internal/hcp/registry/metadata/cicd.go`). Supports:

| Platform | Detection | Variables Captured |
|---|---|---|
| **GitHub Actions** | `GITHUB_ACTIONS` | `GITHUB_REPOSITORY`, `GITHUB_SHA`, `GITHUB_REF`, `GITHUB_ACTOR`, `GITHUB_EVENT_NAME`, `GITHUB_JOB`, workflow URL |
| **GitLab CI** | `GITLAB_CI` | `CI_PROJECT_NAME`, `CI_COMMIT_SHA`, `CI_COMMIT_REF_NAME`, `GITLAB_USER_NAME`, `CI_PIPELINE_URL`, `CI_JOB_URL` |
| **Bitbucket Pipelines** | `BITBUCKET_BUILD_NUMBER` | `BITBUCKET_REPO_FULL_NAME`, `BITBUCKET_COMMIT`, `BITBUCKET_BRANCH`, `BITBUCKET_PIPELINE_UUID` |
| **Jenkins** | `JENKINS_URL` | `BUILD_URL`, `JOB_NAME`, `BUILD_NUMBER`, `GIT_COMMIT`, `GIT_BRANCH`, `NODE_NAME` |

### VCS Metadata

Collected by `metadata.GetVcsMetadata()` (from
`internal/hcp/registry/metadata/vcs.go`):

| Field | Source |
|---|---|
| VCS type | Git (auto-detected) |
| Branch ref | `git rev-parse --abbrev-ref HEAD` |
| Commit SHA | `git rev-parse HEAD` |
| Author | Commit author name + email |
| Uncommitted changes | `git status --porcelain` |

### Packer Build Metadata

| Field | Source |
|---|---|
| Packer version | `buildMetadata.PackerVersion` |
| Plugins | Name + version for each loaded plugin |
| CLI options | Raw command-line arguments passed to `packer build` |
| Git SHA | `getGitSHA()` -- added as `git_sha` label to every build |

---

## Environment Variables Reference

All defined in `internal/hcp/env/variables.go`:

| Variable | Purpose |
|---|---|
| `HCP_CLIENT_ID` | HCP service principal client ID |
| `HCP_CLIENT_SECRET` | HCP service principal client secret |
| `HCP_CRED_FILE` | Path to HCP credential file |
| `HCP_PROJECT_ID` | HCP project ID |
| `HCP_ORGANIZATION_ID` | HCP organization ID |
| `HCP_PACKER_REGISTRY` | Set to `off` or `0` to disable HCP integration |
| `HCP_PACKER_BUCKET_NAME` | Default bucket name (fallback if not in template) |
| `HCP_PACKER_BUILD_FINGERPRINT` | Resume a specific version by fingerprint |
| `PACKER_RUN_UUID` | Packer run correlation UUID |

---

## Key Implementation Files

| File | Purpose |
|---|---|
| `internal/hcp/registry/registry.go` | `Registry` interface and `New()` factory |
| `internal/hcp/registry/hcp.go` | `IsHCPEnabled()`, `createConfiguredBucket()`, `HCLRegistry` constructor |
| `internal/hcp/registry/hcl.go` | `HCLRegistry` implementation (PopulateVersion, StartBuild, CompleteBuild, InjectEnforcedProvisioners) |
| `internal/hcp/registry/json.go` | `JSONRegistry` for legacy JSON templates |
| `internal/hcp/registry/types.bucket.go` | `Bucket` struct, Initialize, populateVersion, heartbeat, completeBuild, channel updates |
| `internal/hcp/registry/types.version.go` | `Version` struct, fingerprint generation, build tracking, metadata |
| `internal/hcp/registry/types.builds.go` | `Build` struct, artifact and label management |
| `internal/hcp/registry/types.metadata_store.go` | `MetadataStore`, `Gather()` |
| `internal/hcp/registry/artifact.go` | Registry artifact type |
| `internal/hcp/registry/ds_config.go` | Datasource configuration for version/artifact parent tracking |
| `internal/hcp/registry/null_registry.go` | No-op registry for non-HCP builds |
| `internal/hcp/registry/errors.go` | `ErrBuildAlreadyDone` |
| `internal/hcp/registry/metadata/os.go` | OS metadata gathering |
| `internal/hcp/registry/metadata/cicd.go` | CI/CD platform metadata (GitHub, GitLab, Bitbucket, Jenkins) |
| `internal/hcp/registry/metadata/vcs.go` | VCS metadata (Git) |
| `internal/hcp/env/env.go` | Authentication checks, environment variable queries |
| `internal/hcp/env/variables.go` | Environment variable constants |
| `hcl2template/types.build.hcp_packer_registry.go` | HCL block schema and validation |
| `datasource/hcp-packer-version/data.go` | Packer datasource: version lookup |
| `datasource/hcp-packer-artifact/data.go` | Packer datasource: artifact lookup |
| `datasource/hcp-packer-iteration/data.go` | Packer datasource (deprecated): iteration lookup |
| `datasource/hcp-packer-image/data.go` | Packer datasource (deprecated): image lookup |
| `provisioner/hcp-sbom/provisioner.go` | SBOM generation/upload provisioner |
