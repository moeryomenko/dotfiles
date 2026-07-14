# RNG Schema Consultation

How to consult libvirt's RELAX NG schema files for XML structure validation and HCL mapping.

> **Warning**: libvirt does NOT auto-generate RNG schemas. They must be read from the installed libvirt package (`libvirt` on Arch, `libvirt-daemon` on Fedora, `libvirt-clients` on Debian). Always consult the installed schemas at `/usr/share/libvirt/schemas/`.

## Schema Location

```bash
ls /usr/share/libvirt/schemas/
# basictypes.rng  domain.rng  network.rng  nwfilter.rng  ...
```

## Key Schema Files

| Schema | Purpose | Resources |
|--------|---------|-----------|
| `domain.rng` | Virtual machine domain XML | `libvirt_domain` |
| `network.rng` | Virtual network XML | `libvirt_network` |
| `storagepool.rng` | Storage pool XML | `libvirt_pool` |
| `storagevol.rng` | Storage volume XML | `libvirt_volume` |
| `nwfilter.rng` | Network filter XML | (future) |
| `interface.rng` | Host interface XML | (future) |

## How to Read RNG

### Element Definition

```xml
<define name="domain">
  <interleave>
    <optional>
      <attribute name="type">
        <choice>
          <value>qemu</value>
          <value>kvm</value>
          <value>xen</value>
        </choice>
      </attribute>
    </optional>
    <element name="name">
      <text/>
    </element>
    <optional>
      <element name="memory">
        <ref name="memory"/>
      </element>
    </optional>
  </interleave>
</define>
```

### Mapping RNG to HCL

| RNG construct | HCL mapping |
|---------------|-------------|
| `<element name="name"><text/></element>` | `name = schema.StringAttribute{ Required: true }` |
| `<optional><element name="memory">...</element></optional>` | `memory = schema.SingleNestedAttribute{ Optional: true }` |
| `<attribute name="type"><choice><value>...</value></choice></attribute>` | `type = schema.StringAttribute{ ... validators = [stringvalidator.OneOf(...)] }` |
| `<zeroOrMore><element name="disk">...</element></zeroOrMore>` | `disk = schema.ListNestedAttribute{ ... }` |
| `<interleave>` | Nested attributes on single object (order-independent) |
| `<ref name="someType"/>` | Reference to another defined type -> separate nested object |

### Common RNG Patterns

1. **Interleave containers**: Elements can appear in any order. HCL fields are order-independent, so this maps naturally to nested attributes
2. **Choice values**: Enums. Map to `stringvalidator.OneOf()` in HCL
3. **Optional elements**: Map to `Optional: true` in schema
4. **ZeroOrMore elements**: Map to `ListNestedAttribute` (lists) or `SetNestedAttribute` (if order doesn't matter)
5. **Ref subtypes**: Map to separate nested objects or interface-based fields

## Searching RNG Schemas

Use grep to find element definitions and their structure within RNG schema files:

```bash
# Find a specific element definition with surrounding context
grep -A 5 -B 5 '<element name="disk">' /usr/share/libvirt/schemas/domain.rng

# Find all top-level element definitions in a schema
grep -n '<define name=' /usr/share/libvirt/schemas/domain.rng

# Find where a specific type is referenced
grep -n '<ref name="disk">' /usr/share/libvirt/schemas/domain.rng

# Search across all schemas
grep -l '<define name="domain">' /usr/share/libvirt/schemas/*.rng
```

This is faster than reading the full RNG file end-to-end when checking specific element structure. Use `-A` and `-B` to see parent context (e.g., whether the element is inside `<optional>`, `<interleave>`, or `<choice>`).
