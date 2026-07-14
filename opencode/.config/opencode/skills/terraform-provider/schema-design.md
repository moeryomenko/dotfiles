# Provider Schema Design

Attribute types, semantic options, plan modifiers, and validators for Terraform provider schemas. Covers both Plugin Framework and SDK v2.

## Attribute Semantics

### Required / Optional / Computed Matrix

| Required | Optional | Computed | Behavior |
|----------|----------|----------|----------|
| true | false | false | User MUST provide value |
| false | true | false | User MAY provide value |
| false | false | true | Provider sets value, user cannot set |
| false | true | true | User MAY provide, provider sets default |
| true | false | true | Invalid combination |

### When to Use Each

- **Required**: Identity-defining attributes (name, region), configuration that has no safe default
- **Optional**: User-configurable settings with safe defaults
- **Computed**: Provider-assigned values (ARNs, IDs, generated names, timestamps)
- **Optional+Computed**: User MAY override provider default (common for settings with API defaults)
- **Sensitive**: Secrets, passwords, private keys — masked in logs and plan output

## Schema Structure

### Flat vs Nested

```go
// FLAT — simple, non-repeating attributes
resource_schema.Schema{
  Attributes: map[string]resource_schema.Attribute{
    "name": resource_schema.StringAttribute{ Required: true },
    "count": resource_schema.Int64Attribute{ Optional: true, Computed: true },
  },
}

// NESTED — grouping related attributes
resource_schema.Schema{
  Attributes: map[string]resource_schema.Attribute{
    "name": resource_schema.StringAttribute{ Required: true },
    "network": resource_schema.SingleNestedAttribute{
      Optional: true,
      Attributes: map[string]resource_schema.Attribute{
        "cidr_block": resource_schema.StringAttribute{ Required: true },
        "dns_servers": resource_schema.ListAttribute{
          ElementType: types.StringType,
          Optional: true,
        },
      },
    },
  },
}
```

### List vs Set vs Map

| Collection | Order | Uniqueness | Use case |
|-----------|-------|-----------|----------|
| `ListNestedAttribute` | Preserved | Not required | Ordered items (rules, entries) |
| `SetNestedAttribute` | Not preserved | Required | Unordered items (tags, members) |
| `MapAttribute` | Not preserved | Keys unique | Named items, key-value pairs |

## Plan Modifiers (Framework)

### Semantic Attributes

```go
"force_new_field": resource_schema.StringAttribute{
  Required: true,
  PlanModifiers: []planmodifier.String{
    stringplanmodifier.RequiresReplace(),
  },
},

"optional_with_default": resource_schema.StringAttribute{
  Optional: true,
  Computed: true,
  Default: stringdefault.StaticString("default"),
  PlanModifiers: []planmodifier.String{
    stringplanmodifier.UseStateForUnknown(),
  },
},
```

### Common Plan Modifier Patterns

| Pattern | Implementation | Effect |
|---------|---------------|--------|
| Force new on change | `fieldplanmodifier.RequiresReplace` | Replace resource when field changes |
| Preserve unknown value | `fieldplanmodifier.UseStateForUnknown` | Keep prior value when new value unknown at plan time |
| Force new conditionally | `fieldplanmodifier.RequiresReplaceIf(func(...) bool)` | Replace only when condition met |
| Mark computed only | No modifier needed | Provider computes value on create |

## Validators

### Framework Validators

| Validator | Type | Effect |
|-----------|------|--------|
| `stringvalidator.LengthAtLeast(n)` | String | Minimum length |
| `stringvalidator.LengthAtMost(n)` | String | Maximum length |
| `stringvalidator.RegexMatches(r, msg)` | String | Pattern validation |
| `stringvalidator.OneOf(vals...)` | String | Enum validation |
| `int64validator.AtLeast(n)` | Int64 | Minimum value |
| `int64validator.AtMost(n)` | Int64 | Maximum value |
| `int64validator.Between(min, max)` | Int64 | Range validation |
| `listvalidator.SizeAtLeast(n)` | List | Minimum items |
| `listvalidator.SizeAtMost(n)` | List | Maximum items |
| `listvalidator.UniqueValues()` | List | No duplicates |
| `mapvalidator.SizeAtLeast(n)` | Map | Minimum entries |
| `mapvalidator.SizeAtMost(n)` | Map | Maximum entries |
| `boolvalidator.AlsoRequires(paths...)` | Bool | Conditional requirement |
| `confmapvalidator.RequiredWith(paths...)` | Map | Requires other attributes |

### SDK v2 Validators

```go
"port": {
  Type:     schema.TypeInt,
  Optional: true,
  ValidateFunc: validation.IntBetween(1, 65535),
},

"protocol": {
  Type:     schema.TypeString,
  Required: true,
  ValidateFunc: validation.StringInSlice([]string{"tcp", "udp"}, false),
},
```

## State Migration (SDK v2)

```go
SchemaVersion: 1,
MigrateState: func(v int, is *terraform.InstanceState, meta interface{}) (*terraform.InstanceState, error) {
  switch v {
  case 0:
    is.Attributes["new_field"] = is.Attributes["old_field"]
    delete(is.Attributes, "old_field")
    fallthrough
  default:
    return is, nil
  }
},

// StateUpgraders array (preferred over MigrateState)
StateUpgraders: []schema.StateUpgrader{
  {
    Version: 0,
    Type:    cty.Type{},
    Upgrade: func(ctx context.Context, rawState map[string]interface{}, meta interface{}) (map[string]interface{}, error) {
      rawState["new_field"] = rawState["old_field"]
      delete(rawState, "old_field")
      return rawState, nil
    },
  },
},
```

## Framework Model Types

```go
type WidgetModel struct {
  Id    types.String `tfsdk:"id"`
  Name  types.String `tfsdk:"name"`
  Color types.String `tfsdk:"color"`
  Tags  types.Map    `tfsdk:"tags"`
  Size  types.Int64  `tfsdk:"size"`
}
```

### Null vs Unknown vs Known

| State | `IsNull()` | `IsUnknown()` | `ValueString()` |
|-------|-----------|--------------|-----------------|
| Not set explicitly | true | false | empty string |
| Computed (not yet set) | false | true | empty string |
| Set by user | false | false | actual value |
| Set by provider | false | false | actual value |

Always check `IsNull()` before accessing value, and `IsUnknown()` before using computed values in plan-time logic.
