# Inventory Generation

Ansible inventory generation from Terraform state — group structure, host vars, and output modes.

## Output Modes

### JSON Inventory (`--list`)

```json
{
  "all": {
    "hosts": ["web-0", "db-0"],
    "vars": {
      "region": "us-east-1",
      "environment": "production"
    }
  },
  "type_aws_instance": {
    "hosts": ["web-0", "db-0"]
  },
  "type_aws_instance_web": {
    "hosts": ["web-0"]
  }
}
```

### INI Inventory (`--inventory`)

Standard Ansible INI format with `[group]` headers and `host var=value` syntax:

```ini
[all]
web-0 ansible_host=203.0.113.1 public_ip=203.0.113.1 private_ip=10.0.1.50
db-0 ansible_host=10.0.1.100 private_ip=10.0.1.100

[type_aws_instance]
web-0 ansible_host=203.0.113.1 public_ip=203.0.113.1 private_ip=10.0.1.50
db-0 ansible_host=10.0.1.100 private_ip=10.0.1.100

[type_aws_instance_web]
web-0 ansible_host=203.0.113.1 public_ip=203.0.113.1

[type_aws_instance_db]
db-0 ansible_host=10.0.1.100 private_ip=10.0.1.100

[tag_environment_prod]
web-0 ansible_host=203.0.113.1
db-0 ansible_host=10.0.1.100
```

Each host line starts with the host name followed by `key=value` pairs for every
attribute. The `ansible_host` variable is always emitted when an IP address is
resolved. Group order follows the same hierarchy as JSON output: `all` first, then
type groups, then tag groups.

### Host Output (`--host <name>`)

```json
{
  "id": "i-abc123",
  "public_ip": "203.0.113.1",
  "private_ip": "10.0.1.50",
  "tags": {
    "Name": "web-server",
    "Environment": "prod"
  },
  "ansible_host": "203.0.113.1"
}
```

## Group Structure

### Automatic Groups

| Group | Content | Example |
|-------|---------|---------|
| `all` | All hosts + outputs as vars | Every host |
| `type_<resource_type>` | By resource type | `type_aws_instance` |
| `type_<type>_<name>` | By resource type + name | `type_aws_instance_web` |
| `type_<type>_<name>_<index>` | Individual instances | `type_aws_instance_web_0` |
| Tag groups | By tag value | `tag_environment_prod` |

### Outputs as Host Vars

```hcl
# Terraform outputs are available as `all` group vars
output "region" {
  value = "us-east-1"
}

output "environment" {
  value = "production"
}
```

## Host Variable Resolution

```go
// Host variable priority:
// 1. All resource attributes flattened
// 2. ansible_host set to first found IP address
// 3. Tags become individual variables
```

## Resource Exclusion

Not all Terraform resources represent inventory hosts. The tool applies exclusion rules:

| Exclusion | Reason | Examples |
|-----------|--------|---------|
| Data resources (`data.*`) | Read-only sources, not infrastructure hosts | `data.aws_ami.ubuntu`, `data.aws_vpc.main` |
| Non-host resources | Network primitives without IP addresses | `aws_security_group`, `aws_subnet`, `aws_vpc`, `aws_route_table` |
| Provisioner-only resources | No runtime IP or hostname | `null_resource`, `terraform_data` |

### Host Detection Heuristic

```go
// A resource is considered a host if:
// 1. It has mode "managed" (not "data")
// 2. It has a resolvable IP address (via provider-specific key lookup)
// 3. It has at least one of: id, public_ip, private_ip, ipv4_address
//
// Data resources (mode == "data") are always excluded regardless of IP.
// Resources without any recognized IP key are still included if they
// have an id, but their ansible_host is left unset.

func isHostResource(resource Resource) bool {
    if resource.Mode == "data" {
        return false
    }
    // If we can resolve an IP, it's a host
    if ip := resolveIP(resource); ip != "" {
        return true
    }
    // Fall back: include resources that have an id attribute
    _, hasID := resource.Attributes["id"]
    return hasID
}
```

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `TF_KEY_NAME` | `id` | Attribute key used as the resource's inventory hostname |
| `TF_HOSTNAME_KEY_NAME` | (none) | Attribute key used for `ansible_host` (overrides IP lookup) |
| `TF_STATE` | `terraform.tfstate` | Path to state file or directory |
| `TI_TFSTATE` | (none) | Legacy alias for `TF_STATE` |

### TF_KEY_NAME

Overrides the attribute key used as the inventory hostname. By default, the tool uses
the resource `id` (e.g., `i-abc123`) as the host name. Set `TF_KEY_NAME` to use a
different attribute:

```bash
# Use the value of the "Name" tag as the inventory hostname
export TF_KEY_NAME="tags.Name"
# Now hosts are named "web-server" instead of "i-abc123"

# Use a custom attribute
export TF_KEY_NAME="hostname"
```

### TF_HOSTNAME_KEY_NAME

Overrides the attribute used for `ansible_host`. By default, the tool resolves
`ansible_host` from the first IP address found using provider-specific key lookups
(see Provider Resource Mapping). Set `TF_HOSTNAME_KEY_NAME` to pin a specific
attribute:

```bash
# Use private IP instead of public IP for ansible_host
export TF_HOSTNAME_KEY_NAME="private_ip"

# Use a DNS name or custom attribute
export TF_HOSTNAME_KEY_NAME="fqdn"

# Combined with TF_KEY_NAME for full control
export TF_KEY_NAME="tags.Name"
export TF_HOSTNAME_KEY_NAME="private_ip"
# Results in: web-server ansible_host=10.0.1.50
```

This is useful when instances are behind a NAT or VPN and the public IP is not
reachable from the controller. If the specified key does not exist on a resource,
the tool falls back to the normal IP resolution.

## Binary Detection

```go
// Binary selection order (from getTerraformCommand()):
// 1. TF_CLI_COMMAND environment variable (manual override)
// 2. `tofu` binary (preferred for OpenTofu users)
// 3. `terraform` binary (fallback)

func getTerraformCommand() string {
  if cmd := os.Getenv("TF_CLI_COMMAND"); cmd != "" {
    return cmd
  }
  if _, err := exec.LookPath("tofu"); err == nil {
    return "tofu"
  }
  return "terraform"
}
```

### Input Mode Detection

```go
// Path resolution order
// 1. Command-line argument (file or directory)
// 2. TF_STATE env var
// 3. TI_TFSTATE env var (legacy)
// 4. terraform.tfstate in current directory

func getInputPath(arg string) string {
  if arg != "" {
    return arg
  }
  for _, env := range []string{"TF_STATE", "TI_TFSTATE"} {
    if p := os.Getenv(env); p != "" {
      return p
    }
  }
  return "terraform.tfstate"
}
```

### State Acquisition

```go
// If input is a directory, run show to get JSON state
func getState(input string) ([]byte, error) {
  info, err := os.Stat(input)
  if err != nil {
    return nil, err
  }

  if info.IsDir() {
    cmd := getTerraformCommand()
    // Try show -json first
    out, err := exec.Command(cmd, "show", "-json").Output()
    if err != nil {
      // Fallback to state pull
      return exec.Command(cmd, "state", "pull").Output()
    }
    return out, nil
  }

  // Read file directly
  return os.ReadFile(input)
}
```
