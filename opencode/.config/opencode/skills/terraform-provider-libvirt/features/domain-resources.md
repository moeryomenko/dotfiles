# Domain Resource Patterns

Implementation patterns for `libvirt_domain` resource — boot, disk, network device XML, and cloud-init/ignition/combustion integration.

## Domain Resource Structure

### Key Schema Sections

```go
"domain": schema.SingleNestedAttribute{
  Optional: true,
  Attributes: map[string]schema.Attribute{
    "type":     schema.StringAttribute{ Optional: true },
    "name":     schema.StringAttribute{ Required: true },
    "memory":   schema.SingleNestedAttribute{ ... },
    "vcpu":     schema.SingleNestedAttribute{ ... },
    "cpu":      schema.SingleNestedAttribute{ ... },
    "os":       schema.SingleNestedAttribute{ ... },
    "disk":     schema.ListNestedAttribute{ ... },
    "network":  schema.ListNestedAttribute{ ... },
    "console":  schema.ListNestedAttribute{ ... },
    "clock":    schema.SingleNestedAttribute{ ... },
    "features": schema.ListNestedAttribute{ ... },
  },
}
```

### Boot Configuration

```hcl
resource "libvirt_domain" "example" {
  name = "example-vm"

  # Boot from disk
  boot_device {
    dev = ["hd"]
  }

  # Firmware selection
  firmware = "/usr/share/edk2/x64/OVMF_CODE.fd"

  # OS type
  os {
    type = "hvm"
    arch = "x86_64"
    machine = "q35"
  }

  # CPU
  vcpu {
    value    = 2
    placement = "auto"
  }

  # Memory
  memory {
    value = 2048
    unit  = "MiB"
  }
}
```

### Disk Configuration

```hcl
disk {
  device = "disk"
  type   = "file"

  source {
    file = "/var/lib/libvirt/images/example.qcow2"
  }

  target {
    dev = "vda"
    bus = "virtio"
  }
}

# Cloud-init disk
cloudinit_disk = resource.libvirt_cloudinit_disk.ci.id
```

### Network Interface

```hcl
network_interface {
  network_name   = "default"
  model_type     = "virtio"
  mac_address    = "52:54:00:ab:cd:ef"
  hostname       = "example-vm"
  addresses      = ["192.168.122.100"]
  wait_for_lease = true
}
```

## Cloud-Init / Ignition / Combustion Integration

### Cloud-Init

```hcl
resource "libvirt_cloudinit_disk" "ci" {
  name = "ci-disk.iso"
  pool = "default"

  network_config = templatefile("${path.module}/network.cfg", {})

  meta_data = jsonencode({
    "local-hostname": "example-vm",
    "instance-id": "example-vm-001"
  })

  user_data = templatefile("${path.module}/cloud-init.cfg", {
    hostname = "example-vm"
  })
}

resource "libvirt_domain" "vm" {
  cloudinit_disk = libvirt_cloudinit_disk.ci.id
  # ...
}
```

### Ignition

```hcl
resource "libvirt_ignition" "ign" {
  name    = "example.ign"
  pool    = "default"
  content = file("${path.module}/bootstrap.ign")
}

resource "libvirt_domain" "vm" {
  ignition = libvirt_ignition.ign.id
  # ...
}
```

### Combustion

```hcl
resource "libvirt_combustion" "co" {
  name    = "combustion-script"
  pool    = "default"
  content = file("${path.module}/combustion.sh")
}

resource "libvirt_domain" "vm" {
  combustion = libvirt_combustion.co.id
  # ...
}
```

## XML Lifecycle

### Conversion Flow

```go
// 1. HCL model -> XML for API call
model := readFromPlan(ctx, plan)
xmlBytes := convertModelToXML(model)
libvirtConn.DomainCreateXML(xmlBytes, flags)

// 2. XML from API -> HCL model for state
xmlDesc := libvirtConn.DomainGetXMLDesc(domain, flags)
model := convertXMLToModel(xmlDesc)
writeToState(ctx, state, model)
```

### Value Normalization

Libvirt normalizes values on readback. Always preserve user input:

```go
// User specifies: machine = "q35"
// Libvirt returns: "pc-q35-10.1"
// Preserve user's original value in state:
stateMachine = planMachine  // keep user's input
```

## Generated vs Manual Code

The domain resource uses code generation to produce three source files:

| Generated file | Path | Purpose |
|---------------|------|---------|
| `domain_model.gen.go` | `internal/generated/domain_model.gen.go` | Go struct types mirroring domain XML elements |
| `domain_schema.gen.go` | `internal/generated/domain_schema.gen.go` | HCL schema attribute definitions |
| `domain_convert.gen.go` | `internal/generated/domain_convert.gen.go` | Conversion functions between model structs and Terraform types |

### What is generated

- **Schema outlines**: Attribute definitions, type constraints, nesting structure, default values
- **Model structs**: Go type definitions from RNG element structure
- **Round-trip conversions**: Plan-to-model and model-to-state conversion stubs

### What is manual

- **Custom validators**: Cross-field validation (e.g., disk bus compatibility)
- **Plan modifiers**: Value preservation logic (e.g., keeping user's normalized input)
- **XML serialization/deserialization**: `convertModelToXML` and `convertXMLToModel` are hand-written due to libvirt's complex normalization rules
- **Resource lifecycle**: CRUD functions, state migration, import handling
