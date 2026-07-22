# Libvirt Provider Technical Patterns

Codegen pipeline, XML-to-HCL mapping, connection transports, and resource patterns.

## Codegen Pipeline

### Pipeline Stages

```
libvirtxml structs  --[reflection]-->  StructIR  --[templates]-->  .gen.go
                                           |
                                    [policy application]
                                           |
                                [doc injection from YAML]
```

### Stage 1: Reflection

```go
// parser.NewLibvirtXMLReflector uses Go reflection to inspect
// libvirtxml.Domain, libvirtxml.Network, libvirtxml.StoragePool,
// libvirtxml.StorageVolume structs
reflector := parser.NewLibvirtXMLReflector()
structs := collector.CollectAll()
// Produces StructIR: a type-description intermediate representation
```

### Stage 2: Policy Application

```go
// internal/codegen/policy/field_policy.go
// Applies Terraform semantics after reflection:
// - Computed: fields that are always read from API
// - RequiresReplace: fields that force recreation
// - Optional: fields user can set
// - Required: fields user must set
policy.ApplyFieldPolicies(structs)
```

### Stage 3: Template Rendering

Three templates produce three files per struct:

| Template | Output | Purpose |
|----------|--------|---------|
| `model.go.tmpl` | `{resource}_model.gen.go` | Go struct with `tfsdk` tags |
| `schema.go.tmpl` | `{resource}_schema.gen.go` | Framework schema attribute defs |
| `convert.go.tmpl` | `{resource}_convert.gen.go` | XML <-> model conversion funcs |

```go
// Example generated model
type DomainModel struct {
  Id      types.String `tfsdk:"id"`
  Name    types.String `tfsdk:"name"`
  Vcpu    types.Int64  `tfsdk:"vcpu"`
  Memory  types.Int64  `tfsdk:"memory"`
  Xml     DomainXml   `tfsdk:"xml"`
}
```

### Running Codegen

```bash
# Auto-run on build/test
make generate
# or manual
go run ./internal/codegen
```

Generated files are gitignored (`internal/generated/*.gen.go`). Always regenerate before committing.

## XML -> HCL Mapping Rules

| XML | HCL | Example |
|-----|-----|---------|
| Element | Nested attribute | `<memory>` -> `memory` |
| Attribute | Scalar field | `<interface type="bridge">` -> `type = "bridge"` |
| Repeated elements | List of nested objects | `<disk><disk>` -> `disk = [{}, {}]` |
| Container elements | Nested object | `<cpu><topology/></cpu>` -> `cpu { topology {} }` |
| Presence elements | Boolean | `<acpi/>` -> `acpi = true` |
| Value + 1 unit attr | Flattened | `<memory unit="KiB">` -> `memory { value, unit }` |
| Value + 2+ extra attrs | Nested object | `<vcpu placement="static">` -> `vcpu { value, placement }` |
| Union/variant branches | Nested object with optional fields | `source = { file, network }` |

### Naming Conventions
- snake_case naming
- Common acronyms intact (`mac_address`, `uuid`, `nvram`)
- No abbreviations that lose meaning

### Validation Source
Always consult `/usr/share/libvirt/schemas/*.rng` for:
- Element hierarchy
- Required vs optional attributes
- Allowed values for enums
- Default values
- Type constraints

## Connection Transports

### Dialer Architecture

```
Provider Config
    |
    v
URI Parsing
    |
    +---> Local Socket  (qemu:///system)
    +---> Go SSH        (qemu+ssh://...)
    +---> SSH Cmd       (qemu+sshcmd://...)
    +---> TCP           (qemu+tcp://...)
    +---> TLS           (qemu+tls://...)
```

### Dialers

| Dialer | Transport | Key Features |
|--------|-----------|--------------|
| Local | Unix socket | `/var/run/libvirt/libvirt-sock` (system) or `/run/user/$UID/libvirt/libvirt-sock` (session) |
| Go SSH | `crypto/ssh` | Supports keyfile, known_hosts, password. Pure Go SSH client. |
| SSH Cmd | Native `ssh` CLI | Respects `~/.ssh/config`. 3 proxy modes: auto, native, netcat |
| TCP | Plain TCP | Direct TCP connection |
| TLS | TLS with PKI | Configurable cert paths, no_verify option |

### SSH Cmd Proxy Modes

| Mode | Description |
|------|-------------|
| `auto` | Try virt-ssh-helper first, fallback to netcat |
| `native` | virt-ssh-helper only (libvirt-native protocol) |
| `netcat` | Direct netcat (socat) through SSH tunnel |

## Resource Schema Patterns

### Nested Attributes (Not Blocks)

```go
// CORRECT — nested attributes
"disk": schema.ListNestedAttribute{
  Optional: true,
  NestedObject: schema.NestedAttributeObject{
    Attributes: map[string]schema.Attribute{
      "device": schema.StringAttribute{ Optional: true },
      "type":   schema.StringAttribute{ Optional: true },
    },
  },
}

// AVOID — blocks (legacy, backward compat only)
"disk": schema.ListNestedBlock{ ... }
```

### Field Read Semantics

```go
// Computed-only — always read from API
"uuid": schema.StringAttribute{
  Computed: true,
}

// Optional — only populate if user specified via plan
"memory": schema.Int64Attribute{
  Optional: true,
  Default:  int64default.StaticInt64(1048576),
}

// Required — always in state
"name": schema.StringAttribute{
  Required: true,
}
```

### golibvirt Constants

```go
// Use constants, not magic numbers
golibvirt.DomainRunning        // domain is running
golibvirt.DomainShutoff        // domain is off
golibvirt.DomainStartPaused    // start in paused state
golibvirt.DomainStartAutodestroy  // auto-destroy on connection close
```
