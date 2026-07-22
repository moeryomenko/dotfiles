# State File Parsing

Reading and parsing Terraform state files for inventory generation.

## State Format Versions

### Pre-0.12 Format (Version 3)

```json
{
  "version": 3,
  "terraform_version": "0.11.14",
  "modules": [
    {
      "path": ["root"],
      "resources": {
        "aws_instance.web": {
          "type": "aws_instance",
          "primary": {
            "id": "i-abc123",
            "attributes": {
              "id": "i-abc123",
              "public_ip": "203.0.113.1",
              "tags.Name": "web-server"
            }
          }
        }
      },
      "child_modules": [
        {
          "path": ["root", "child"],
          "resources": {
            "aws_instance.child": {
              "type": "aws_instance",
              "primary": {
                "id": "i-child456",
                "attributes": {
                  "id": "i-child456",
                  "public_ip": "203.0.113.2"
                }
              }
            }
          }
        }
      ]
    }
  ]
}
```

Version 3 modules can contain a `child_modules` array for resources nested in sub-modules.
Each child module has its own `path` and `resources`, enabling recursive traversal.

### 0.12+ Format (Version 4)

```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_instance.web",
          "type": "aws_instance",
          "values": {
            "id": "i-abc123",
            "public_ip": "203.0.113.1",
            "tags": { "Name": "web-server" }
          }
        }
      ]
    }
  }
}
```

### Version Differences

| Field | Version 3 | Version 4 |
|-------|-----------|-----------|
| `format_version` | Not present (version field only) | `version: 4` |
| Resource container | `modules[].resources` (map) | `values.root_module.resources` (array) |
| Module nesting | `modules[].child_modules[]` (recursive) | `values.root_module.child_modules[]` (recursive) |
| Attribute format | Dot-path keys like `tags.Name` | Nested objects like `tags: { Name: ... }` |
| `terraform_version` | Optional, when written by 0.11+ | Always present, written by 0.12+ |

## Error Handling

| Scenario | Detection | Behavior |
|----------|-----------|----------|
| Malformed JSON (syntax error) | `json.Unmarshal` returns syntax error | Return error wrapped with context: "failed to parse state file" |
| Non-Terraform JSON (valid JSON but no state) | `version` field missing or `modules`/`values` absent | Return error: "not a valid Terraform state file" |
| Unsupported format version (< 3 or > 4) | Check `version` field after unmarshal | Return error: "unsupported state format version N (supported: 3, 4)" |
| Empty state file (0 bytes) | `os.ReadFile` returns empty slice | Return error: "state file is empty" |
| Truncated state file (incomplete JSON) | `json.Unmarshal` returns unexpected EOF | Return error: "state file appears truncated" |
| State with missing `version` field | JSON parses but no `version` key | Return error: "state file missing version field" |
| State with `values` but no `root_module` | Version 4 structure but `values.root_module` is nil | Return error: "state file missing root_module" |
| Resource with missing `type` field | Resource entry has no `type` key | Skip resource, log warning: "resource at index N missing type field, skipping" |

```go
func parseState(data []byte) (*Inventory, error) {
    if len(data) == 0 {
        return nil, errors.New("state file is empty")
    }

    // Check for malformed JSON before structural parsing
    if !json.Valid(data) {
        return nil, errors.New("failed to parse state file: invalid JSON")
    }

    // Pre-check version field
    var versionCheck struct {
        Version int `json:"version"`
    }
    if err := json.Unmarshal(data, &versionCheck); err != nil {
        return nil, fmt.Errorf("failed to parse state file: %w", err)
    }
    if versionCheck.Version == 0 {
        return nil, errors.New("state file missing version field")
    }
    if versionCheck.Version < 3 || versionCheck.Version > 4 {
        return nil, fmt.Errorf(
            "unsupported state format version %d (supported: 3, 4)",
            versionCheck.Version)
    }

    // Try 0.12+ format first
    // ... rest of parsing ...
}
```

## Detection Algorithm

```go
// Try 0.12+ format first
var state12 stateTerraform0dot12
if err := json.Unmarshal(data, &state12); err == nil {
  if state12.Values.RootModule != nil {
    return parse12(&state12)
  }
}
// Fall back to pre-0.12
var state03 state
if err := json.Unmarshal(data, &state03); err == nil {
  return parse03(&state03)
}
```

## Resource Key Parsing

```go
// Key format: type.name.index
// Examples: aws_instance.web.0, aws_instance.web["name"]
re := regexp.MustCompile(`^([\w\-]+)\.([\w\-]+)(?:\.(\d+|[\S+]+))?$`)
```

| Format | Example | Index type |
|--------|---------|------------|
| `type.name.N` | `aws_instance.web.0` | Numeric (count) |
| `type.name["key"]` | `aws_instance.web["main"]` | String (for_each) |

### Module Prefix Handling

Resources nested inside modules include the module path as a prefix on the address. The
key parser must handle these prefixed addresses to correctly strip the module path and
extract the resource type, name, and index.

| Address format | Parsed resource key | Module path |
|----------------|---------------------|-------------|
| `module.foo.aws_instance.web` | `aws_instance.web` | `["root", "foo"]` |
| `module.foo.module.bar.aws_instance.db` | `aws_instance.db` | `["root", "foo", "bar"]` |
| `module.foo.aws_instance.web.0` | `aws_instance.web.0` | `["root", "foo"]` |

```go
// Regex for stripping module prefix from resource address
// Matches: "module.X." repeated zero or more times, then type.name.index
moduleRe := regexp.MustCompile(`^(?:module\.([\w\-]+)\.)+`)
resourceKeyRe := regexp.MustCompile(`^([\w\-]+)\.([\w\-]+)(?:\.(\d+|\["\S+"\]))?$`)

func parseResourceKey(address string) (modulePath []string, resourceType, name, index string) {
    // Strip module prefix
    for {
        matches := moduleRe.FindStringSubmatch(address)
        if matches == nil {
            break
        }
        modulePath = append(modulePath, matches[1])
        address = strings.TrimPrefix(address, "module."+matches[1]+".")
    }
    // Parse remaining as type.name.index
    parts := resourceKeyRe.FindStringSubmatch(address)
    if parts != nil {
        resourceType = parts[1]
        name = parts[2]
        index = parts[3]
    }
    return
}
```

### Counter Field for Duplicate Tracking

When a key has a numeric index (e.g., `aws_instance.web.0`, `aws_instance.web.1`),
the parser uses a counter map to track how many instances of each (type, name) pair
have been seen. This produces unique host names:

```go
type keyCounter struct {
    resourceKeys map[string]int // "type.name" -> count
}

func (kc *keyCounter) uniqueName(resourceType, name, index string) string {
    key := resourceType + "." + name
    kc.resourceKeys[key]++
    count := kc.resourceKeys[key]
    if index != "" && count == 1 {
        return name + "-" + index // Use existing index on first occurrence
    }
    return fmt.Sprintf("%s-%d", name, count-1) // Disambiguate duplicates
}
```

## Provider Resource Mapping

Resources are mapped to inventory hosts based on type. IP address is extracted from a provider-specific attribute lookup order:

```go
// Example IP lookup key order for AWS
ipKeys := []string{"public_ip", "private_ip",
  "access_ip_v4", "ipv4_address", "network_interface.0.access_config.0.assigned_nat_ip"}

// Each provider has a different set of IP key names
```

### Supported Providers

The tool supports 43+ providers with provider-specific IP key mappings. Key providers:

| Provider | IP Keys |
|----------|---------|
| AWS | `public_ip`, `private_ip`, `network_interface.*` |
| Azure | `public_ip_address`, `private_ip_address` |
| GCP | `network_interface.0.access_config.0.nat_ip`, `network_ip` |
| OpenStack | `access_ip_v4`, `network.*` |
| VMware | `ip`, `ip_address` |
| DigitalOcean | `ipv4_address`, `ipv4` |
| Hetzner Cloud | `ip`, `public_ip` |
