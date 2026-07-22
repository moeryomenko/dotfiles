# Packer HCL2 Template Syntax

Practical reference for writing `.pkr.hcl` files. Every example uses real Packer HCL2 syntax validated against the Packer source.

---

## 1. Packer Block

The `packer` block sets version constraints and plugin requirements at the top of a template.

```hcl
packer {
  required_version = ">= 1.9, < 2.0"

  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}
```

| Attribute | Purpose |
|---|---|
| `required_version` | Version constraint string. Supports `>=`, `~>`, `!=`, etc. Multiple constraints: `">= 1.9, < 2.0"` |
| `required_plugins` | Map of plugin names to requirements. Each entry needs `version` and `source`. |
| `source` | Plugin registry path: `"github.com/<org>/<name>"`. Omitting `source` defaults to `github.com/hashicorp/<name>`. |

**Plugin installation**: Packer downloads plugins from the HCP Packer Registry automatically on `packer init` or `packer build`. Run `packer init` to resolve all plugin dependencies before building.

---

## 2. Variables

### 2.1 Variable Declaration

```hcl
variable "image_id" {
  type        = string
  default     = "ubuntu-22.04"
  description = "The base image identifier"
}

variable "port" {
  type    = number
  default = 42
}

variable "headless" {
  type    = bool
  default = true
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "development"
    Project     = "infrastructure"
  }
}
```

### 2.2 Complex Type Constraints

```hcl
variable "instance_spec" {
  type = object({
    cpu    = number
    memory = number
    disk   = number
  })
  default = {
    cpu    = 4
    memory = 8192
    disk   = 50000
  }
}

variable "allowed_ports" {
  type = tuple([number, number, number])
  default = [22, 80, 443]
}
```

### 2.3 Validation Blocks

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment name"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "disk_size" {
  type        = number
  default     = 20000

  validation {
    condition     = var.disk_size >= 10000
    error_message = "Disk size must be at least 10000 MB."
  }
}
```

### 2.4 Variable Assignment

Variables can be set in multiple ways, with the following precedence (highest first):

1. Environment variables (`PKR_VAR_<name>`)
2. `-var` flag on the command line
3. `-var-file` flag
4. `*.pkrvars.hcl` auto-loaded files
5. Variable default

**Variable files** (`.pkrvars.hcl`):

```hcl
// variables.pkrvars.hcl
image_id = "ubuntu-22.04"
headless = false
tags = {
  Environment = "production"
}
```

**Environment variable override** (prefix `PKR_VAR_`):

```bash
export PKR_VAR_headless=false
export PKR_VAR_image_id="ubuntu-22.04"
packer build template.pkr.hcl
```

---

## 3. Locals

Locals assign computed expressions to named values. They are evaluated once per build and are the primary mechanism for derived configuration.

```hcl
locals {
  # Static computed value
  http_directory = dirname(convert(fileset(".", "etc/http/*"), list(string))[0])

  # String interpolation with variables
  iso_url_ubuntu = "http://releases.ubuntu.com/${var.ubuntu_version}/ubuntu-${var.ubuntu_version}-server-amd64.iso"

  # Map literal
  standard_tags = {
    Component   = "user-service"
    Environment = "production"
  }

  # Function call chaining
  provisioner_scripts = fileset(".", "etc/scripts/*.sh")

  # Interpolation with other locals
  output_directory = "qemu_iso_ubuntu_${var.ubuntu_version}_amd64"
}

# Sensitive local — masked in logs
local "secret_config" {
  expression = "${var.api_key}-${var.secret_suffix}"
  sensitive  = true
}
```

| Function used above | Purpose |
|---|---|
| `fileset(path, pattern)` | Lists files matching a glob pattern |
| `file(path)` | Reads a file's content as a string |
| `dirname(path)` | Returns the directory portion of a path |
| `convert(value, type)` | Converts a value to a target type |

> **Note**: `local` blocks can appear multiple times across files — they merge at the template level. Values reference each other as `local.<name>` within expressions.

---

## 4. Sources (Builder Blocks)

A `source` block configures a builder. It declares what kind of machine to create and how to connect to it. Source blocks are referenced by name from `build` blocks.

```hcl
# sources.pkr.hcl
source "qemu" "ubuntu-2204" {
  headless         = var.headless
  accelerator      = "kvm"
  disk_size        = 5000
  disk_interface   = "virtio-scsi"
  memory           = 2048
  cpus             = 2
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_wait_timeout = "50m"
  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
  http_directory   = local.http_directory
  boot_wait        = "5s"
  iso_url          = local.iso_url_ubuntu
  iso_checksum     = "file:${local.iso_checksum_url}"
}
```

### Common Source Options (cross-builder)

| Option | Type | Typical Values |
|---|---|---|
| `ssh_username` | string | `"vagrant"`, `"root"` |
| `ssh_password` | string | `"vagrant"` |
| `ssh_private_key_file` | string | `"~/.ssh/id_rsa"` |
| `ssh_wait_timeout` | duration | `"50m"`, `"1h"` |
| `ssh_timeout` | duration | `"30s"` |
| `ssh_handshake_attempts` | number | `100` |
| `temporary_key_pair_type` | string | `"ed25519"`, `"rsa"` |
| `communicator` | string | `"ssh"` (default), `"winrm"`, `"none"` |
| `winrm_username` | string | `"Administrator"` |
| `winrm_password` | string | — |
| `winrm_timeout` | duration | `"1h"` |
| `output_directory` | string | `"output/my-image"` |
| `boot_wait` | duration | `"10s"` |
| `boot_command` | list(string) | VM keystroke sequences |
| `http_directory` | string | Path to HTTP serve directory for preseed/kickstart |
| `http_port_min`, `http_port_max` | number | HTTP server port range |
| `shutdown_command` | string | Command to shut down the VM |
| `shutdown_timeout` | duration | `"5m"` |

### Source Naming

```hcl
source "<builder-type>" "<name>" {
  # configuration
}
```

Sources are referenced as `source.<builder-type>.<name>` in build blocks.

---

## 5. Build Blocks

The `build` block is the orchestration unit. It selects sources, runs provisioners, and invokes post-processors.

### 5.1 Full Anatomy

```hcl
build {
  name        = "ubuntu-2204"
  description = <<EOF
  Builds Ubuntu 22.04 images for QEMU and VirtualBox.
  Installs base packages and hardens SSH configuration.
  EOF

  # Reference a source by its full address
  sources = [
    "source.qemu.ubuntu-2204",
    "source.virtualbox-iso.ubuntu-2204",
  ]

  # Source-specific overrides
  source "source.qemu.ubuntu-2204" {
    name         = "qemu-kvm"
    output_directory = "output/qemu-ubuntu-2204"
    boot_command = local.ubuntu_2204_boot_command_qemu
  }

  source "source.virtualbox-iso.ubuntu-2204" {
    name         = "virtualbox"
    output_directory = "output/vbox-ubuntu-2204"
    boot_command = local.ubuntu_2204_boot_command_vbox
  }

  # Provisioners run sequentially
  provisioner "shell" {
    environment_vars = ["HOME_DIR=/home/vagrant"]
    execute_command  = "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    scripts          = fileset(".", "etc/scripts/*.sh")
  }

  provisioner "file" {
    source      = "assets/issue"
    destination = "/etc/issue"
  }

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "apt-get install -y -qq htop",
    ]
  }

  # Post-processors — single
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }

  # Post-processor pipeline (sequential within a group)
  post-processors {
    post-processor "compress" {
      output = "output/{{.BuildName}}.tar.gz"
    }

    post-processor "artifice" {
      files = ["output/{{.BuildName}}.tar.gz"]
    }
  }
}
```

### 5.2 Source Selection

Sources can be listed in `sources` or overridden inline:

```hcl
# Short form — list only
sources = ["source.qemu.ubuntu-2204"]

# With overrides
source "source.qemu.ubuntu-2204" {
  name  = "custom-name"
  memory = 4096  # override just this field
}
```

### 5.3 Provisioner Types

| Provisioner | Purpose |
|---|---|
| `shell` | Run shell commands or scripts (Linux/macOS) |
| `powershell` | Run PowerShell commands or scripts (Windows) |
| `file` | Upload files to the image |
| `ansible` | Run Ansible playbooks against the image |
| `chef-client` | Run Chef client |
| `puppet-masterless` | Run Puppet apply |
| `windows-restart` | Reboot a Windows machine and wait for it to come back |
| `salt-masterless` | Run Salt states |
| `breakpoint` | Pause the build for debugging |
| `shell-local` | Run a script on the host machine |

### 5.4 Post-Processor Pipelines

Post-processors form linear pipelines. Within a `post-processors` block, each `post-processor` passes its output to the next.

```hcl
# Single post-processor
post-processor "manifest" {
  output = "manifest.json"
}

# Pipeline of two post-processors
post-processors {
  post-processor "compress" {
    output = "output/{{.BuildName}}.tar.gz"
  }

  post-processor "artifice" {
    files = ["output/{{.BuildName}}.tar.gz"]
  }
}

# Multiple independent post-processor pipelines
post-processors {
  post-processor "docker-tag" {
    ...
  }
}

post-processors {
  post-processor "vagrant" {
    ...
  }
}
```

Common post-processors: `docker-tag`, `docker-push`, `manifest`, `vagrant`, `compress`, `shell-local`, `artifice`, `checksum`, `amazon-import`, `vsphere`.

### 5.5 Error-Cleanup Provisioner

A special provisioner that runs only when the build fails:

```hcl
build {
  sources = ["source.qemu.ubuntu-2204"]

  provisioner "shell" {
    inline = ["echo 'this might fail'"]
  }

  error-cleanup-provisioner "shell" {
    inline = ["echo 'cleaning up after failure'"]
  }
}
```

---

## 6. HCL2 Functions

Complete list of every function available in Packer HCL2 templates, sourced from `hcl2template/functions.go` and `hcl2template/function/`.

### 6.1 String Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `upper` | `upper(string)` | Uppercase a string | `upper("hello")` → `"HELLO"` |
| `lower` | `lower(string)` | Lowercase a string | `lower("HELLO")` → `"hello"` |
| `title` | `title(string)` | Title-case each word | `title("hello world")` → `"Hello World"` |
| `trim` | `trim(string, cutset)` | Trim characters from both ends | `trim(" hello ", " ")` → `"hello"` |
| `trimspace` | `trimspace(string)` | Trim whitespace | `trimspace("  hi  ")` → `"hi"` |
| `trimprefix` | `trimprefix(string, prefix)` | Remove prefix if present | `trimprefix("hello_ world", "hello_ ")` → `"world"` |
| `trimsuffix` | `trimsuffix(string, suffix)` | Remove suffix if present | `trimsuffix("file.txt", ".txt")` → `"file"` |
| `chomp` | `chomp(string)` | Remove trailing newlines | `chomp("hello\n")` → `"hello"` |
| `format` | `format(format, args...)` | Sprintf-style formatting | `format("hello %s", "world")` |
| `formatlist` | `formatlist(format, lists...)` | Format each element of a list | `formatlist("hello %s", ["a","b"])` |
| `replace` | `replace(string, substr, replacement)` | Replace all occurrences | `replace("a/b/c", "/", "-")` |
| `split` | `split(separator, string)` | Split string into list | `split(",", "a,b,c")` → `["a","b","c"]` |
| `join` | `join(separator, list)` | Join list into string | `join(",", ["a","b"])` → `"a,b"` |
| `regex` | `regex(pattern, string)` | Extract first match | `regex("(\\d+)", "abc123")` → `"123"` |
| `regexall` | `regexall(pattern, string)` | Extract all matches | `regexall("a", "aba")` → `["a","a"]` |
| `regex_replace` | `regex_replace(string, pattern, replacement)` | Regex replace | `regex_replace("abc", "b", "B")` |
| `substr` | `substr(string, offset, length)` | Substring | `substr("hello", 0, 2)` → `"he"` |
| `strrev` | `strrev(string)` | Reverse a string | `strrev("hello")` → `"olleh"` |
| `indent` | `indent(spaces, string)` | Indent every line | — |
| `startswith` | `startswith(string, prefix)` | Check prefix | `startswith("hello", "he")` → `true` |
| `endswith` | `endswith(string, suffix)` | Check suffix | `endswith("hello", "lo")` → `true` |
| `strcontains` | `strcontains(string, search)` | Check substring | `strcontains("hello", "ell")` → `true` |

### 6.2 Numeric Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `abs` | `abs(number)` | Absolute value | `abs(-5)` → `5` |
| `ceil` | `ceil(number)` | Round up | `ceil(3.1)` → `4` |
| `floor` | `floor(number)` | Round down | `floor(3.9)` → `3` |
| `log` | `log(number, base)` | Logarithm | `log(100, 10)` → `2` |
| `max` | `max(nums...)` | Maximum | `max(1, 5, 3)` → `5` |
| `min` | `min(nums...)` | Minimum | `min(1, 5, 3)` → `1` |
| `parseint` | `parseint(string, base)` | Parse integer | `parseint("42", 10)` → `42` |
| `pow` | `pow(number, power)` | Exponentiation | `pow(2, 3)` → `8` |
| `signum` | `signum(number)` | Sign (-1, 0, 1) | `signum(-5)` → `-1` |
| `sum` | `sum(list)` | Sum all elements | `sum([1, 2, 3])` → `6` |

### 6.3 Collection Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `concat` | `concat(lists...)` | Concatenate lists | `concat([1], [2])` → `[1,2]` |
| `distinct` | `distinct(list)` | Remove duplicates | `distinct([1,1,2])` → `[1,2]` |
| `flatten` | `flatten(list)` | Flatten nested lists | `flatten([[1],[2]])` → `[1,2]` |
| `compact` | `compact(list)` | Remove empty elements | `compact(["a",""])` → `["a"]` |
| `contains` | `contains(list, value)` | Check membership | `contains([1,2], 1)` → `true` |
| `element` | `element(list, index)` | Index (wrapping) | `element(["a","b"], 2)` → `"a"` |
| `length` | `length(value)` | Length of string/list/map | `length("hello")` → `5` |
| `slice` | `slice(list, from, to)` | Slice a list | `slice([1,2,3], 0, 2)` → `[1,2]` |
| `lookup` | `lookup(map, key, default)` | Key lookup with fallback | — |
| `keys` | `keys(map)` | Extract map keys | `keys({a=1,b=2})` → `["a","b"]` |
| `values` | `values(map)` | Extract map values | `values({a=1,b=2})` → `[1,2]` |
| `merge` | `merge(maps...)` | Merge maps | `merge({a=1},{b=2})` → `{a=1,b=2}` |
| `zipmap` | `zipmap(keys, values)` | Build map from keys+values | `zipmap(["a"], [1])` → `{a=1}` |
| `chunklist` | `chunklist(list, size)` | Split into chunks | `chunklist([1,2,3], 2)` → `[[1,2],[3]]` |
| `coalesce` | `coalesce(vals...)` | First non-null/non-empty | `coalesce("", "fallback")` → `"fallback"` |
| `coalescelist` | `coalescelist(lists...)` | First non-empty list | — |
| `reverse` | `reverse(list)` | Reverse list | `reverse([1,2,3])` → `[3,2,1]` |
| `sort` | `sort(list)` | Sort list | `sort([3,1,2])` → `[1,2,3]` |
| `setintersection` | `setintersection(sets...)` | Intersection of sets | — |
| `setunion` | `setunion(sets...)` | Union of sets | — |
| `setproduct` | `setproduct(sets...)` | Cartesian product | — |
| `alltrue` | `alltrue(list)` | Are all elements true? | `alltrue([true, false])` → `false` |
| `anytrue` | `anytrue(list)` | Is any element true? | `anytrue([true, false])` → `true` |
| `range` | `range(limit)` | Generate numeric range | `range(3)` → `[0,1,2]` |
| `index` | `index(list, value)` | Find index of value | `index(["a","b"], "b")` → `1` |

### 6.4 File System Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `file` | `file(path)` | Read file as string | `file("${local.http_directory}/preseed.cfg")` |
| `filebase64` | `filebase64(path)` | Read file as base64 | `filebase64("boot.ipxe")` |
| `fileexists` | `fileexists(path)` | Check file exists | `fileexists("preseed.cfg")` → `true` |
| `fileset` | `fileset(base_dir, pattern)` | List files matching glob | `fileset(".", "etc/scripts/*.sh")` |
| `abspath` | `abspath(path)` | Absolute path | `abspath(".")` |
| `basename` | `basename(path)` | Last path component | `basename("/a/b/c")` → `"c"` |
| `dirname` | `dirname(path)` | Parent directory | `dirname("/a/b/c")` → `"/a/b"` |
| `pathexpand` | `pathexpand(path)` | Expand `~` prefix | `pathexpand("~/.ssh/id_rsa")` |

> **Important**: `fileset`, `file`, `fileexists`, and `abspath` resolve paths relative to the template directory at evaluation time. This means a file referenced by a provisioner block in `build.pkr.hcl` is looked up from the directory containing `build.pkr.hcl`.

### 6.5 Encoding & Crypto Functions

| Function | Signature | Description |
|---|---|---|
| `base64decode` | `base64decode(string)` | Decode base64 |
| `base64encode` | `base64encode(string)` | Encode to base64 |
| `base64gzip` | `base64gzip(string)` | Gzip + base64 encode |
| `csvdecode` | `csvdecode(string)` | Parse CSV to list of objects |
| `jsondecode` | `jsondecode(string)` | Parse JSON |
| `jsonencode` | `jsonencode(value)` | Serialize to JSON |
| `yamldecode` | `yamldecode(string)` | Parse YAML |
| `yamlencode` | `yamlencode(value)` | Serialize to YAML |
| `urlencode` | `urlencode(string)` | URL percent-encode |
| `textencodebase64` | `textencodebase64(string, encoding)` | Encode to encoding + base64 (IANA charset) |
| `textdecodebase64` | `textdecodebase64(source, encoding)` | Decode base64 from IANA charset to UTF-8 |
| `md5` | `md5(string)` | MD5 hash |
| `sha1` | `sha1(string)` | SHA-1 hash |
| `sha256` | `sha256(string)` | SHA-256 hash |
| `sha512` | `sha512(string)` | SHA-512 hash |
| `bcrypt` | `bcrypt(string)` | bcrypt hash |
| `rsadecrypt` | `rsadecrypt(ciphertext, private_key)` | RSA decrypt |

### 6.6 Date/Time Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `timestamp` | `timestamp()` | Current UTC timestamp (RFC3339) | `timestamp()` → `"2026-07-14T12:00:00Z"` |
| `timeadd` | `timeadd(timestamp, duration)` | Add duration | `timeadd(timestamp(), "1h")` |
| `formatdate` | `formatdate(format, timestamp)` | Format timestamp | `formatdate("YYYY-MM-DD", timestamp())` |
| `legacy_isotime` | `legacy_isotime(format)` | Legacy ISO time format | `legacy_isotime("2006-01-02")` |
| `legacy_strftime` | `legacy_strftime(format)` | strftime-style format | `legacy_strftime("%Y-%m-%d")` |
| `rfc3339_parse` | `rfc3339_parse(timestamp)` | Parse RFC3339 to cty date | — |
| `unix_timestamp_parse` | `unix_timestamp_parse(unix)` | Parse Unix timestamp | — |

### 6.7 CIDR / Network Functions

| Function | Signature | Description |
|---|---|---|
| `cidrhost` | `cidrhost(prefix, hostnum)` | Calculate host address in CIDR |
| `cidrnetmask` | `cidrnetmask(prefix)` | Convert CIDR to netmask |
| `cidrsubnet` | `cidrsubnet(prefix, newbits, netnum)` | Calculate subnet address |
| `cidrsubnets` | `cidrsubnets(prefix, newbits...)` | Calculate multiple subnet addresses |

### 6.8 Type & Error-Handling Functions

| Function | Signature | Description | Example |
|---|---|---|---|
| `can` | `can(expression)` | Returns true if expression succeeds | `can(var.foo)` → `false` if undefined |
| `try` | `try(expressions...)` | Returns first successful expression | `try(var.foo, "default")` |
| `convert` | `convert(value, type)` | Convert value to target type | `convert(fileset(...), list(string))` |
| `coalesce` | `coalesce(vals...)` | First non-null, non-empty value | `coalesce(var.foo, "fallback")` |

### 6.9 Secret Lookup Functions

| Function | Description |
|---|---|
| `vault(path, key)` | Read secret from HashiCorp Vault KV store |
| `consul_key(path)` | Read key from Consul KV store |
| `aws_secretsmanager(secret_id, json_key)` | Read secret from AWS Secrets Manager |
| `aws_secretsmanager_raw(secret_id)` | Read raw secret from AWS Secrets Manager |

### 6.10 Other Functions

| Function | Signature | Description |
|---|---|---|
| `uuidv4` | `uuidv4()` | Generate a random UUID v4 |
| `uuidv5` | `uuidv5(namespace, name)` | Generate a deterministic UUID v5 |
| `templatefile` | `templatefile(path, vars)` | Render a template file with variables |

### 6.11 Real-World Function Usage

```hcl
locals {
  # fileset lists files sorted alphanumerically
  provisioner_scripts = fileset(".", "etc/scripts/*.sh")

  # dirname + fileset validates the http directory exists at parse time
  http_directory = dirname(convert(fileset(".", "etc/http/*"), list(string))[0])

  # file reads content for embedded serving
  http_directory_content = {
    "/preseed.cfg" = file("${local.http_directory}/preseed.cfg")
  }

  # String formatting
  iso_url = format("http://releases.ubuntu.com/%s/ubuntu-%s-server-amd64.iso",
    var.ubuntu_version,
    var.ubuntu_version)

  # String manipulation
  safe_name = replace(lower(var.environment), " ", "-")

  # List operations
  all_tags = concat(local.standard_tags, var.custom_tags)

  # Conditional
  is_production = var.environment == "prod" ? true : false
}
```

---

## 7. Expressions

### 7.1 Interpolation

Any attribute value can contain interpolation expressions in `${}` syntax:

```hcl
variable "ubuntu_version" {
  default = "22.04"
}

locals {
  iso_url      = "http://releases.ubuntu.com/${var.ubuntu_version}/ubuntu-${var.ubuntu_version}-server-amd64.iso"
  output_dir   = "output/qemu-ubuntu-${replace(var.ubuntu_version, ".", "-")}"
}

source "qemu" "example" {
  iso_checksum = "file:${local.iso_checksum_url}"
  memory       = 512 * 2  # arithmetic, no ${} needed
}
```

### 7.2 Arithmetic Operators

Supported in any numeric context (with or without `${}`):

```hcl
memory         = 512 * 4
disk_size      = 20000 + 5000
cpu_count      = max(2, 4)
boot_wait      = "${9 + 1}s"   # evaluates to "10s"
```

### 7.3 Conditional Expressions

```hcl
disk_size = var.environment == "prod" ? 50000 : 20000
headless  = var.debug ? false : true
name      = var.name != "" ? var.name : "default-name"
```

### 7.4 `for` Expressions

Iterate over lists and maps:

```hcl
locals {
  names = ["alice", "bob", "carol"]

  # Transform list — element projection
  upper_names = [for n in local.names : upper(n)]
  # → ["ALICE", "BOB", "CAROL"]

  # Filtered iteration
  short_names = [for n in local.names : upper(n) if length(n) <= 3]
  # → ["BOB"]

  # Map iteration — produces map
  name_lengths = { for n in local.names : n => length(n) }
  # → { alice = 5, bob = 3, carol = 5 }
}
```

### 7.5 Splat Expressions (`[*]`)

Extract attributes from a list of objects:

```hcl
variable "instances" {
  default = [
    { id = "a", size = "small"  },
    { id = "b", size = "medium" },
    { id = "c", size = "large"  },
  ]
}

locals {
  instance_ids   = var.instances[*].id
  # → ["a", "b", "c"]

  # Full splat on result list (equivalent to var.instances[*].id)
  indexed_ids    = var.instances[*].id[*]
  # → ["a", "b", "c"]  (identical to the non-indexed result)
}
```

### 7.6 Heredoc Strings

```hcl
description = <<EOF
This build creates Ubuntu images for versions:
* 22.04
* 24.04
EOF

# Indented heredoc (dedents to the left margin)
description = <<-EOF
  This build creates Ubuntu images for versions:
  * 22.04
  * 24.04
EOF
```

### 7.7 Template Directives

For multi-line templates with conditionals and iteration:

```hcl
locals {
  template_content = templatefile("${path.root}/cloud-init.yml.tpl", {
    hostname = "builder-01"
    packages = ["htop", "vim"]
  })
}
```

Template directives use Go template syntax inside template files:
```
# cloud-init.yml.tpl
hostname: {{ .hostname }}
{{- if .packages }}
packages:
{{- range .packages }}
  - {{ . }}
{{- end }}
{{- end }}
```

---

## 8. Template Organization

### 8.1 File Naming Convention

Packer discovers all files matching `*.pkr.hcl` in a directory:

```
template/
  packer.pkr.hcl            # packer block + required_plugins
  variables.pkr.hcl         # variable declarations + locals
  sources.pkr.hcl           # source blocks
  build.pkr.hcl             # build block(s)
  variables.pkrvars.hcl     # variable values (auto-loaded if present)
```

| Pattern | Purpose |
|---|---|
| `*.pkr.hcl` | Config files — all loaded and merged |
| `*.pkrvars.hcl` | Variable value files — auto-loaded, cannot declare variables |

### 8.2 Directory Structure Patterns

**Flat project** (single image type):

```
packer/
  packer.pkr.hcl
  variables.pkr.hcl
  sources.pkr.hcl
  build.pkr.hcl
  variables.pkrvars.hcl
  etc/
    preseed.cfg
    scripts/
      01-setup.sh
      02-cleanup.sh
```

**Multi-OS project** (separate build blocks per variant):

```
packer/
  packer.pkr.hcl
  variables.pkr.hcl
  sources.pkr.hcl
  build.ubuntu.pkr.hcl
  build.alpine.pkr.hcl
  variables.common.pkrvars.hcl
  variables.ubuntu.pkrvars.hcl
  variables.alpine.pkrvars.hcl
  etc/
    ubuntu/
      preseed.cfg
    alpine/
      answers
```

**Multi-builder project** (separate source files per builder):

```
packer/
  packer.pkr.hcl
  variables.pkr.hcl
  source.qemu.pkr.hcl
  source.virtualbox-iso.pkr.hcl
  source.vsphere-iso.pkr.hcl
  build.pkr.hcl
  etc/
    scripts/
    http/
```

### 8.3 Reference Architecture

From the Packer examples (`examples/hcl/linux/`), the recommended multi-image, multi-builder pattern:

```
# packer.pkr.hcl — top-level config
packer {
  required_version = ">= 1.0"
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# variables.pkr.hcl — shared variables
variable "headless" {
  type    = bool
  default = true
}

locals {
  http_directory = dirname(convert(fileset(".", "etc/http/*"), list(string))[0])
  http_directory_content = {
    "/preseed.cfg" = file("${local.http_directory}/preseed.cfg")
  }
}

# source.qemu.pkr.hcl — builder-common config
source "qemu" "base-ubuntu-amd64" {
  headless         = var.headless
  disk_size        = 5000
  disk_interface   = "virtio-scsi"
  memory           = 512 * 2
  cpus             = 2
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_wait_timeout = "50m"
}

# variables.ubuntu.pkr.hcl — version-specific values
variable "ubuntu_version" {
  default = "22.04"
}

locals {
  iso_url  = "http://releases.ubuntu.com/${var.ubuntu_version}/ubuntu-${var.ubuntu_version}-server-amd64.iso"
  iso_checksum_url = "http://releases.ubuntu.com/${var.ubuntu_version}/SHA256SUMS"
}

# build.ubuntu.pkr.hcl — per-OS build
build {
  name = "ubuntu-${var.ubuntu_version}"

  source "source.qemu.base-ubuntu-amd64" {
    name          = "qemu-${var.ubuntu_version}"
    iso_url       = local.iso_url
    iso_checksum  = "file:${local.iso_checksum_url}"
    boot_command  = local.ubuntu_boot_command
  }

  provisioner "shell" {
    scripts = fileset(".", "etc/scripts/*.sh")
  }
}
```

### 8.4 Merging Behavior

When Packer loads multiple `.pkr.hcl` files from the same directory:

| Block | Merging Strategy |
|---|---|
| `packer` | Merged — single block across files (duplicate keys error) |
| `variable` | Merged — duplicate name is an error |
| `locals` | Merged across all files |
| `source` | Merged — unique `"type" "name"` pairs |
| `build` | Each `build` block is independent; multiple build blocks produce multiple builds |
| `data` | Merged — unique `"type" "name"` pairs |
| `local` (sensitive) | Merged — unique names |

### 8.5 Build Names and Multiple Builds

Multiple `build` blocks in the same directory produce separate builds. The `name` attribute differentiates them:

```hcl
# This file defines two builds
build {
  name = "ubuntu-22-04"
  sources = ["source.qemu.ubuntu-2204"]
}

build {
  name = "ubuntu-24-04"
  sources = ["source.qemu.ubuntu-2404"]
}
```

Run a specific build with `--only`:

```bash
packer build --only ubuntu-22-04 template/
```

---

## 9. Data Sources

Data sources query external systems for information used during the build. They use the same `data "type" "name"` addressable pattern as sources.

```hcl
data "amazon-ami" "ubuntu" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
}

locals {
  # Reference data source in expressions
  base_ami_id = data.amazon-ami.ubuntu.id
}

source "amazon-ebs" "from-ami" {
  ami_name    = "packer-custom-{{timestamp}}"
  source_ami  = data.amazon-ami.ubuntu.id
  instance_type = "t3.small"
  ssh_username  = "ubuntu"
}
```

---

## 10. Built-in Build Variables

Within a `build` block, the following variables are available in expressions:

| Variable | Type | Description |
|---|---|---|
| `build.ID` | string | Unique build ID (used in logs, artifact names) |
| `build.Name` | string | Build name from `build { name = "..." }` |
| `build.BuildName` | string | Alias for `build.Name` (deprecated) |
| `build.Sequence` | number | Build sequence number |
| `source.name` | string | Source block name |
| `source.type` | string | Source builder type |

Usage:

```hcl
build {
  name = "ubuntu-2204"

  provisioner "shell" {
    inline = [
      "echo 'Building: ${build.Name}'",
      "echo 'Builder type: ${source.type}'",
    ]
  }

  post-processor "manifest" {
    output = "manifest-${build.ID}.json"
  }
}
```

---

## References

- Source: `/home/eryoma/projects/skills/packer/hcl2template/functions.go` (all 90+ functions)
- Examples: `/home/eryoma/projects/skills/packer/examples/hcl/linux/`
- Test fixtures: `/home/eryoma/projects/skills/packer/hcl2template/testdata/complete/`
