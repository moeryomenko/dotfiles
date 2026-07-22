# Provisioners & Post-Processors Reference

Practical reference for configuring provisioner and post-processor blocks in `.pkr.hcl` files. All examples are syntactically valid HCL.

---

## Table of Contents

- [Provisioner Basics](#provisioner-basics)
- [1. Shell Provisioner](#1-shell-provisioner)
- [2. File Provisioner](#2-file-provisioner)
- [3. PowerShell Provisioner](#3-powershell-provisioner)
- [4. Windows-Restart Provisioner](#4-windows-restart-provisioner)
- [5. Ansible Provisioner](#5-ansible-provisioner)
- [6. Breakpoint Provisioner](#6-breakpoint-provisioner)
- [7. Sleep Provisioner](#7-sleep-provisioner)
- [8. Provisioner Overrides](#8-provisioner-overrides)
- [9. Pause / Timeout / Retry](#9-pause--timeout--retry)
- [10. Only / Except](#10-only--except)
- [11. Error Cleanup Provisioner](#11-error-cleanup-provisioner)
- [Post-Processor Basics](#post-processor-basics)
- [12. Compress Post-Processor](#12-compress-post-processor)
- [13. Checksum Post-Processor](#13-checksum-post-processor)
- [14. Manifest Post-Processor](#14-manifest-post-processor)
- [15. Artifice Post-Processor](#15-artifice-post-processor)
- [16. Post-Processor Chains](#16-post-processor-chains)
- [17. keep_input_artifact](#17-keep_input_artifact)
- [18. Execution Order Semantics](#18-execution-order-semantics)

---

## Provisioner Basics

Provisioners modify the build artifact after the builder creates it. They are declared inside a `build` block and run in the order they appear (top to bottom).

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = ["echo Hello from provisioner"]
  }

  provisioner "file" {
    source      = "local/script.sh"
    destination = "/tmp/script.sh"
  }
}
```

Each `provisioner` block requires a label with the provisioner type. An optional `name` attribute can be given for identification in log output.

---

## 1. Shell Provisioner

Runs shell scripts on the remote machine. Supports three mutually exclusive modes: inline commands, a single script, or multiple scripts.

### Inline Mode

Write short commands directly in the template. A temporary script is created with the default shebang (`/bin/sh -e`).

```hcl
provisioner "shell" {
  name             = "install-packages"
  inline           = [
    "apt-get update",
    "apt-get install -y nginx",
  ]
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive",
  ]
  inline_shebang   = "/bin/bash -e"
}
```

### Single Script Mode

Upload and execute one local script file.

```hcl
provisioner "shell" {
  script = "scripts/provision.sh"
}
```

### Multiple Scripts Mode

Upload and execute several scripts in sequence. All scripts are uploaded and executed in the listed order.

```hcl
provisioner "shell" {
  scripts = [
    "scripts/install-deps.sh",
    "scripts/configure-app.sh",
    "scripts/start-service.sh",
  ]
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `inline` | `list(string)` | Inline commands to execute. Mutually exclusive with `script` and `scripts`. |
| `script` | `string` | Path to a local script file to upload and execute. |
| `scripts` | `list(string)` | List of script files to upload and execute in order. |
| `environment_vars` | `list(string)` | Environment variables in `KEY=value` format passed to the script. |
| `env` | `map(string)` | Alternative way to set environment variables using a map. |
| `execute_command` | `string` | Template for the remote execution command. Default: `"chmod +x {{.Path}}; {{.Vars}} {{.Path}}"`. Available template variables: `{{.Path}}`, `{{.Vars}}`, `{{.EnvVarFile}}`. |
| `expect_disconnect` | `bool` | Set to `true` when the script triggers a reboot that disconnects the communicator. |
| `inline_shebang` | `string` | Shebang line for inline scripts. Default: `"/bin/sh -e"`. |
| `valid_exit_codes` | `list(int)` | Acceptable exit codes. Default: `[0]`. |
| `pause_after` | `string` | Duration to pause after the provisioner completes (e.g. `"10s"`). |
| `skip_clean` | `bool` | Keep the remote script file after execution instead of deleting it. |
| `use_env_var_file` | `bool` | Write environment variables to a file on the remote machine and source them. |
| `start_retry_timeout` | `string` | Time to wait for the remote process to start. Default: `"5m"`. |
| `binary` | `bool` | Upload the script without Unix line-ending conversion. |

### expect_disconnect Example

Use when the provisioner script triggers a reboot:

```hcl
provisioner "shell" {
  script            = "scripts/install-kernel-update.sh"
  expect_disconnect = true
  start_retry_timeout = "10m"
}
```

---

## 2. File Provisioner

Upload files or directories from the local machine to the remote VM, or download from the remote VM to the local machine.

### Upload a Single File

```hcl
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/etc/nginx/nginx.conf"
}
```

### Upload Multiple Files to a Directory

Use `sources` to upload multiple files at once. The destination must be a directory (trailing slash required).

```hcl
provisioner "file" {
  sources      = [
    "configs/app.conf",
    "configs/app.service",
  ]
  destination = "/etc/myapp/"
}
```

### Upload a Directory

Source trailing slash matters:

- **With trailing slash** (`"mydir/"`): uploads the **contents** of the directory.
- **Without trailing slash** (`"mydir"`): uploads the **directory itself** and its contents.

```hcl
# Uploads contents of configs/ into /etc/myapp/
provisioner "file" {
  source      = "configs/"
  destination = "/etc/myapp/"
}

# Uploads configs/ directory into /tmp/ => /tmp/configs/
provisioner "file" {
  source      = "configs"
  destination = "/tmp/"
}
```

### Download from Remote to Local

Set `direction = "download"` to fetch a file from the VM.

```hcl
provisioner "file" {
  direction   = "download"
  source      = "/var/log/syslog"
  destination = "build-logs/syslog"
}
```

### Inline Content

Use `content` to write generated content directly to a file without a local source file.

```hcl
provisioner "file" {
  content     = templatefile("${path.root}/motd.tpl", { hostname = var.hostname })
  destination = "/etc/motd"
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `source` | `string` | Local path to the file or directory to upload. Mandatory unless `sources` is set. |
| `sources` | `list(string)` | List of source files to upload to a single destination directory. |
| `destination` | `string` | Remote path where the file is written. |
| `content` | `string` | Inline content written to the destination. Cannot be combined with `source` or `sources`. |
| `direction` | `string` | `"upload"` (default) or `"download"`. |
| `generated` | `bool` | Skip file existence check during validation. Use for files created on-the-fly. |

---

## 3. PowerShell Provisioner

Executes PowerShell scripts on Windows remote machines. Supports inline commands, script files, and elevated execution.

### Inline Mode

```hcl
provisioner "powershell" {
  inline = [
    "New-Item -Path C:\\app -ItemType Directory -Force",
    "Copy-Item -Path C:\\tmp\\install.ps1 -Destination C:\\app\\",
  ]
}
```

### Single Script

```hcl
provisioner "powershell" {
  script = "scripts/install-iis.ps1"
}
```

### Multiple Scripts

```hcl
provisioner "powershell" {
  scripts = [
    "scripts/install-features.ps1",
    "scripts/configure-firewall.ps1",
  ]
}
```

### Elevated Execution (Run as Admin)

Windows provisioning often requires administrator privileges. Use `elevated_user` and `elevated_password` to run commands as a specific user.

```hcl
provisioner "powershell" {
  scripts           = ["scripts/install-app.ps1"]
  elevated_user     = "Administrator"
  elevated_password = var.admin_password
}
```

### Execution Policy

Control the PowerShell execution policy used when running scripts.

```hcl
provisioner "powershell" {
  script           = "scripts/install.ps1"
  execution_policy = "Bypass"
}
```

### Use pwsh (PowerShell Core)

```hcl
provisioner "powershell" {
  script  = "scripts/deploy.ps1"
  use_pwsh = true
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `inline` | `list(string)` | Inline PowerShell commands. |
| `script` | `string` | Local script file path. |
| `scripts` | `list(string)` | List of script files to execute in order. |
| `elevated_user` | `string` | Username for elevated execution (run as admin). |
| `elevated_password` | `string` | Password for elevated execution. |
| `execution_policy` | `string` | PowerShell execution policy. Values: `"Bypass"`, `"RemoteSigned"`, `"AllSigned"`, `"Restricted"`, `"Unrestricted"`, `"Default"`. |
| `use_pwsh` | `bool` | Use PowerShell Core (`pwsh`) instead of Windows PowerShell. |
| `environment_vars` | `list(string)` | Environment variables as `KEY=value` strings. |
| `valid_exit_codes` | `list(int)` | Acceptable exit codes. Default: `[0]`. |
| `debug_mode` | `int` | Enable debug output (1 or 2). |
| `skip_clean` | `bool` | Keep the remote script file after execution. |
| `start_retry_timeout` | `string` | Timeout for starting the remote process. |

---

## 4. Windows-Restart Provisioner

Reboot a Windows VM and wait for it to come back online. Useful after installing updates or software that requires a restart.

### Basic Restart

```hcl
provisioner "windows-restart" {
  restart_timeout = "15m"
}
```

### Registry Check

Wait for a specific registry key to appear (indicating the restart completed a change).

```hcl
provisioner "windows-restart" {
  restart_timeout = "30m"
  check_registry  = true
  registry_keys   = [
    "HKLM:Software\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending",
    "HKLM:Software\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update\\RebootRequired",
  ]
}
```

### Custom Restart Command

```hcl
provisioner "windows-restart" {
  restart_command  = "shutdown /r /f /t 0 /c \"Packer restart\""
  restart_timeout  = "10m"
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `restart_command` | `string` | Command to initiate the restart. Default: `"shutdown /r /f /t 0 /c \"Packer Restart\""`. |
| `restart_check_command` | `string` | Command to check if the restart is complete and machine is ready. |
| `restart_timeout` | `string` | Maximum time to wait for the machine to restart and become available. |
| `check_registry` | `bool` | Wait for specified registry keys to appear (or disappear) before considering the restart complete. |
| `registry_keys` | `list(string)` | Registry keys to check when `check_registry` is `true`. |

---

## 5. Ansible Provisioner

Runs Ansible playbooks against the build target. Two variants exist:

- **`ansible`**: Runs Ansible on the host machine, connecting to the guest over SSH (requires source builder with SSH communicator).
- **`ansible-local`**: Uploads and runs Ansible locally on the guest machine (no host-side Ansible needed).

### ansible (Remote Execution)

Ansible runs from the provisioning host, connecting to the guest via SSH.

```hcl
provisioner "ansible" {
  playbook_file    = "playbooks/webserver.yml"
  extra_arguments  = [
    "--extra-vars", "env=production",
    "--skip-tags", "dev-only",
  ]
  ansible_env_vars = [
    "ANSIBLE_HOST_KEY_CHECKING=False",
    "ANSIBLE_SSH_RETRIES=5",
  ]
}
```

### ansible-local (Local Execution)

Ansible is installed on the guest VM and runs locally. The playbook and roles are uploaded to the guest before execution.

```hcl
provisioner "ansible-local" {
  playbook_file = "playbooks/setup.yml"
  role_paths    = [
    "roles/common",
    "roles/nginx",
  ]
}
```

### Galaxy Requirements

Install Ansible Galaxy roles before running the playbook.

```hcl
provisioner "ansible" {
  playbook_file = "playbooks/provision.yml"
  galaxy_file   = "requirements.yml"
  galaxy_command = "ansible-galaxy install -r {{.GalaxyFile}} --force"
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `playbook_file` | `string` | Path to the Ansible playbook. |
| `galaxy_file` | `string` | Path to the Ansible Galaxy requirements file. |
| `galaxy_command` | `string` | Custom command for installing Galaxy roles. Default: `"ansible-galaxy install -r {{.GalaxyFile}}"`. |
| `extra_arguments` | `list(string)` | Additional arguments passed to `ansible-playbook`. |
| `role_paths` | `list(string)` | Local paths to Ansible roles (uploaded before execution). |
| `ansible_env_vars` | `list(string)` | Environment variables set for the Ansible process. |
| `user` | `string` | SSH user for host-side Ansible connections. |
| `groups` | `list(string)` | Inventory groups to add the host to. |
| `inventory_directory` | `string` | Directory for generated inventory files. |
| `inventory_file` | `string` | Path to a custom inventory file. |

For a complete list of options, see the [Ansible Provisioner documentation](https://developer.hashicorp.com/packer/plugins/provisioners/ansible/ansible).

---

## 6. Breakpoint Provisioner

Pause the build at a specific point for debugging. Press Enter in the terminal to continue.

### Basic Breakpoint

```hcl
provisioner "breakpoint" {
  note = "Check that Nginx installed correctly before proceeding"
}
```

### Disabled Breakpoint

Keep the breakpoint in the template without pausing by setting `disable = true`. Useful for debugging scenarios you encounter intermittently.

```hcl
provisioner "breakpoint" {
  note    = "Debug: verify SSH key permissions"
  disable = true
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `note` | `string` | Message displayed when the breakpoint triggers. |
| `disable` | `bool` | Skip the breakpoint without asking for input. |

---

## 7. Sleep Provisioner

Pause execution for a specified duration. Useful when waiting for a service to start or for the VM to settle.

```hcl
provisioner "sleep" {
  duration = "30s"
}
```

Duration values follow Go's `time.Duration` format: `"10s"`, `"5m"`, `"1h"`, `"500ms"`.

---

## 8. Provisioner Overrides

Override provisioner settings for specific builder types. The `override` block maps builder names to alternative configurations. Only the overridden attributes need to be specified.

### Use Case: Different Shell Commands per Builder

```hcl
provisioner "shell" {
  inline = ["echo 'Running on default builder'"]

  override {
    virtualbox-iso = {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y nginx",
      ]
    }
    amazon-ebs = {
      inline = [
        "sudo yum update -y",
        "sudo amazon-linux-extras install nginx1",
      ]
    }
  }
}
```

### How It Works

1. The base provisioner block sets the **default** configuration for all builders.
2. The `override` block contains a map keyed by builder type (or source name).
3. When the build runs for a specific builder, the override values **merge into** the base configuration.
4. If a builder type has no matching override, the base configuration is used as-is.

---

## 9. Pause / Timeout / Retry

Every provisioner supports three meta-parameters that control execution behavior.

### pause_before

Wait before starting the provisioner. Useful when the VM needs time to boot or a service needs to initialize.

```hcl
provisioner "shell" {
  pause_before = "10s"
  inline       = ["echo 'This starts 10 seconds after the previous provisioner'"]
}
```

### timeout

Limit the total execution time for a provisioner. The provisioner is cancelled if it exceeds this duration.

```hcl
provisioner "shell" {
  timeout = "5m"
  inline  = ["make long-build"]
}
```

### max_retries

Retry the provisioner up to N times if it fails. The default is 0 (no retries).

```hcl
provisioner "shell" {
  max_retries = 3
  inline      = ["curl -sf http://unstable-service/install.sh | sh"]
}
```

### continue_on_error

Continue the build even if this provisioner fails.

```hcl
provisioner "shell" {
  continue_on_error = true
  inline            = ["echo 'This can fail without stopping the build'"]
}
```

### Combined Example

```hcl
provisioner "shell" {
  pause_before      = "5s"
  timeout           = "10m"
  max_retries       = 2
  continue_on_error = true
  script            = "scripts/idempotent-setup.sh"
}
```

---

## 10. Only / Except

Target provisioners to specific sources or builds using `only` and `except`. These are mutually exclusive — you cannot specify both on the same block.

### only

Run the provisioner only on matching sources (by source type or source name).

```hcl
provisioner "shell" {
  only = ["virtualbox-iso.ubuntu"]
  inline = [
    "echo 'Only runs on the virtualbox-iso.ubuntu source'",
  ]
}

# Match all sources of a type
provisioner "file" {
  only        = ["amazon-ebs.*"]
  source      = "configs/cloud-init"
  destination = "/etc/cloud/cloud.cfg"
}
```

### except

Run the provisioner on all sources **except** those that match.

```hcl
provisioner "shell" {
  except = ["docker.*"]
  inline = [
    "echo 'Runs on everything except Docker builders'",
  ]
}
```

### Scoping Rules

- `only` and `except` filter against the **source reference** in `"type.name"` format.
- Wildcard `"type.*"` matches all sources of a given builder type.
- Post-processors also support `only` and `except` with the same syntax.

---

## 11. Error Cleanup Provisioner

A special provisioner block that runs only when the build fails. Useful for capturing diagnostic information before the VM is destroyed.

### Syntax

Use `error-cleanup-provisioner` instead of `provisioner`:

```hcl
build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    inline = ["echo 'This might fail'"]
  }

  error-cleanup-provisioner "shell" {
    inline = [
      "echo 'Build failed!' > /tmp/error.log",
      "journalctl -n 100 >> /tmp/error.log",
    ]
  }
}
```

### Restrictions

- Only one `error-cleanup-provisioner` is allowed per `build` block.
- It supports the same types as regular provisioners (`shell`, `file`, etc.).
- It receives the same `source` context and communicator as regular provisioners.
- It does **not** support `pause_before`, `timeout`, `max_retries`, or `continue_on_error` meta-parameters.

---

## Post-Processor Basics

Post-processors run **after** provisioning is complete and the builder produces an artifact. They transform, package, upload, or otherwise process the build result.

Two declaration styles:

1. **Single post-processors**: declared with `post-processor` blocks directly inside `build`.
2. **Chains**: declared inside `post-processors` blocks for sequential processing.

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  # Single post-processor
  post-processor "manifest" {
    output = "manifest.json"
  }

  # Chain of post-processors
  post-processors {
    post-processor "compress" {
      output = "image.tar.gz"
    }
    post-processor "checksum" {
      checksum_types = ["sha256"]
    }
  }
}
```

---

## 12. Compress Post-Processor

Package the build artifact into a compressed archive. Supports tar.gz (default), zip, tar.bz2, tar.xz, tar.lz4, and uncompressed tar.

### Basic Usage

```hcl
post-processor "compress" {
  output = "ubuntu-image.tar.gz"
}
```

### ZIP Format

```hcl
post-processor "compress" {
  format = "zip"
  output = "ubuntu-image.zip"
}
```

### Specify Compression Level

```hcl
post-processor "compress" {
  format            = "tar.gz"
  compression_level = 9
  output            = "ubuntu-image-max.tar.gz"
}
```

### Algorithm Selection

Control the archive and compression separately:

```hcl
post-processor "compress" {
  archive   = "tar"
  algorithm = "xz"
  output    = "ubuntu-image.tar.xz"
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `output` | `string` | Output file path template. Default: `"packer_{{.BuildName}}_{{.BuilderType}}"`. Supports template variables: `{{.BuildName}}`, `{{.BuilderType}}`, `{{.BuildTime}}`. |
| `format` | `string` | Archive format. Detected from output extension by default. Supported: `"tar.gz"`, `"tar.bz2"`, `"tar.xz"`, `"tar.lz4"`, `"zip"`, `"tar"`. |
| `compression_level` | `int` | gzip compression level (-1 to 9). Default: 6. |
| `archive` | `string` | Archive type when using algorithm/archive separation. `"tar"` or `"zip"`. |
| `algorithm` | `string` | Compression algorithm: `"gz"`, `"bzip2"`, `"xz"`, `"lz4"`. |

---

## 13. Checksum Post-Processor

Generate checksum files for the build artifact.

### Single Checksum Type

```hcl
post-processor "checksum" {
  checksum_types = ["sha256"]
}
```

### Multiple Checksum Types

```hcl
post-processor "checksum" {
  checksum_types = ["md5", "sha1", "sha256", "sha512"]
}
```

### Custom Output Path

```hcl
post-processor "checksum" {
  checksum_types = ["sha256"]
  output         = "checksums/{{.BuildName}}_{{.BuilderType}}.sha256"
}
```

The checksum post-processor outputs a `.checksum` file containing hash values. It does not modify the artifact.

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `checksum_types` | `list(string)` | Checksum algorithms: `"md5"`, `"sha1"`, `"sha224"`, `"sha256"`, `"sha384"`, `"sha512"`. |
| `output` | `string` | Output path template. Default: `"packer_{{.BuildName}}_{{.BuilderType}}_{{.ChecksumType}}.checksum"`. |

---

## 14. Manifest Post-Processor

Generate a JSON file with metadata about the build artifact. Useful for CI/CD pipelines to read artifact details.

### Basic Usage

```hcl
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
}
```

### With Custom Data

Add arbitrary key-value pairs to the manifest output.

```hcl
post-processor "manifest" {
  output     = "artifact-info.json"
  strip_path = true
  custom_data = {
    built_by    = "Packer CI"
    environment = "production"
    version     = var.image_version
  }
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `output` | `string` | Output path for the JSON file. Default: `"packer-manifest.json"`. |
| `strip_path` | `bool` | Strip directory paths from artifact filenames in the output. |
| `strip_time` | `bool` | Remove timestamp from filenames in the output. |
| `custom_data` | `map(string)` | Additional key-value pairs included in the JSON output. |

### Output Format

```json
{
  "builds": [
    {
      "name": "ubuntu",
      "builder_type": "amazon-ebs",
      "build_time": 1712345678,
      "files": [
        {"name": "ami-abc123", "size": 0}
      ],
      "artifact_id": "ami-abc123",
      "packer_run_uuid": "...",
      "custom_data": {
        "built_by": "Packer CI",
        "environment": "production",
        "version": "1.2.3"
      }
    }
  ]
}
```

---

## 15. Artifice Post-Processor

Use the Artifice post-processor when a builder does not automatically produce output artifacts (e.g., the `null` builder), or when you need to process files created during provisioning that are not captured by the builder.

```hcl
build {
  sources = ["source.null.builder"]

  provisioner "shell" {
    inline = [
      "echo 'Hello' > /tmp/output.txt",
      "echo 'World' > /tmp/meta.txt",
    ]
  }

  # Capture provisioning-generated files as the artifact
  post-processor "artifice" {
    files = ["/tmp/output.txt", "/tmp/meta.txt"]
  }

  # Chain: files captured by artifice flow into compress
  post-processors {
    post-processor "artifice" {
      files = ["/tmp/output.txt"]
    }
    post-processor "compress" {
      output = "output.tar.gz"
    }
  }
}
```

### Key Options

| Option | Type | Description |
|--------|------|-------------|
| `files` | `list(string)` | Paths to provisioning-generated files that constitute the artifact. |

The artifice post-processor **must** use `keep_input_artifact = true` in the previous chain step or it will be configured as a post-processor whose inputs will be removed before it sees them.

---

## 16. Post-Processor Chains

Post-processors form **sequential chains** inside a `post-processors` block. The output of one post-processor becomes the input to the next.

### Single Post-Processor (Standalone)

```hcl
# No chain — runs directly on the builder artifact
post-processor "manifest" {
  output = "manifest.json"
}
```

### Sequential Chain

The artifact flows through the chain in order:

```hcl
post-processors {
  post-processor "compress" {
    output = "image.tar.gz"
  }
  post-processor "checksum" {
    checksum_types = ["sha256"]
    keep_input_artifact = true
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

Flow: `builder artifact` -> `compress` (produces .tar.gz) -> `checksum` (produces .sha256) -> `manifest` (records final artifacts).

### Multiple Parallel Chains

Multiple `post-processors` blocks each run on a **copy** of the same artifact, in parallel:

```hcl
# Chain 1: compress
post-processors {
  post-processor "compress" {
    format = "tar.gz"
    output = "image.tar.gz"
  }
}

# Chain 2: checksum (runs in parallel with chain 1)
post-processors {
  post-processor "checksum" {
    checksum_types = ["sha256", "md5"]
  }
}
```

### Naming Post-Processors in a Chain

Use the `name` attribute to reference specific post-processors:

```hcl
post-processors {
  post-processor "compress" {
    name   = "compressor"
    output = "image.tar.gz"
  }
  post-processor "checksum" {
    checksum_types = ["sha256"]
  }
}
```

---

## 17. keep_input_artifact

Controls whether the **input artifact** to a post-processor is preserved after that post-processor finishes.

- **`keep_input_artifact = false`** (default for most): the input artifact is discarded after processing. Only the output of the post-processor is kept.
- **`keep_input_artifact = true`**: the input artifact is retained alongside the post-processor's output.

```hcl
post-processors {
  # Keep the raw build artifact so it can still be used
  post-processor "compress" {
    keep_input_artifact = true
    output             = "image.tar.gz"
  }
  # Now both the raw artifact and image.tar.gz flow to the next step
  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

### Default Behavior

- **`post-processor` standalone** (not in a chain): defaults to `false`.
- **`post-processors` chain**: the last post-processor in the chain defaults to `false`; intermediate ones default to `true` (so the artifact flows through the chain).
- **`artifice`**: typically needs `keep_input_artifact = true` on the preceding step so the files it captures exist.

---

## 18. Execution Order Semantics

### Provisioners

1. **Sequential**: Provisioners run in declaration order, top to bottom.
2. **Per-builder**: Each source in `build` gets its own provisioner sequence.
3. **Wait**: Each provisioner must complete before the next one starts.

```hcl
provisioner "shell" {
  inline = ["echo 'Step 1'"]  # Runs first
}
provisioner "shell" {
  inline = ["echo 'Step 2'"]  # Runs second
}
```

### Post-Processors

1. **Standalone `post-processor` blocks** at the top level of `build` process first, in declaration order.
2. **`post-processors` chains** run after standalone post-processors.
3. **Multiple `post-processors` blocks** run in parallel on copies of the same artifact.
4. **Inside a chain**: post-processors run sequentially — the output of one feeds the next.

### Full Build Lifecycle

```
source (builder)
  |
  v
[provisioner 1]  ->  [provisioner 2]  ->  ... ->  [provisioner N]
  |
  v
[post-processor A] (standalone, optional)
  |
  v
[post-processors chain 1] -> [post-processor B] -> [post-processor C]
  |                          (parallel)
  +--> [post-processors chain 2] -> [post-processor D] -> [post-processor E]
```

### packer_on_error

The `packer_on_error` build setting controls overall failure behavior:

- `"cleanup"` (default): Clean up and stop on failure.
- `"abort"`: Stop immediately without cleanup.
- `"ask"`: Prompt the user to decide.

Set this in the `build` block or as a global variable:

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = ["exit 1"]
    max_retries = 2
  }

  # User variable controls on-error behavior
}
```
