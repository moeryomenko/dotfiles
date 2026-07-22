# Terraform Plugin Framework

Terraform Plugin Framework for provider development. Covers Framework types, resource server, Configure pattern, and schema attributes.

## Package Structure

### Core Packages

| Package | Purpose | Key Types |
|---------|---------|-----------|
| `provider` | Provider interface | `Provider`, `ProviderWithMetadata`, `ProviderWithValidateConfig` |
| `provider/schema` | Provider schema | `Schema`, `Attribute`, `Block` |
| `resource` | Resource interface | `Resource`, `ResourceWithConfigure`, `ResourceWithValidateConfig`, `ResourceWithImportState` |
| `resource/schema` | Resource schema | `StringAttribute`, `BoolAttribute`, `Int64Attribute`, `ListNestedAttribute`, `SingleNestedAttribute` |
| `resource/schema/planmodifier` | Plan modifiers | `UseStateForUnknown`, `RequiresReplace`, `UseStateForUnknown` |
| `datasource` | Data source interface | `DataSource`, `DataSourceWithValidateConfig` |
| `datasource/schema` | Data source schema | Same attribute types as resources |
| `types` | Type system | `String`, `Bool`, `Int64`, `Float64`, `List`, `Map`, `Object`, `Set` |
| `diag` | Diagnostics | `Diagnostic`, `Diagnostics`, `Summary`/`Detail` |
| `path` | Attribute paths | `Path`, `RootAtPath`, `AtName` |

### Additional Packages

| Package | Purpose |
|---------|---------|
| `tfsdk` | Lower-level SDK types (State, Plan, Config) |
| `function` | Provider-defined functions (1.8+) |
| `ephemeral` | Ephemeral resources |
| `validators` | `terraform-plugin-framework-validators` — stringvalidator, listvalidator, etc. |
| `tflog` | Structured logging via `terraform-plugin-log` |

## Provider Implementation

### Basic Provider Structure

```go
type exampleProvider struct {
  version string
}

func (p *exampleProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
  resp.TypeName = "example"
  resp.Version = p.version
}

func (p *exampleProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
  resp.Schema = provider_schema.Schema{
    Attributes: map[string]provider_schema.Attribute{
      "endpoint": provider_schema.StringAttribute{
        Optional: true,
      },
    },
  }
}

func (p *exampleProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
  // Parse config, set up API clients
  var config struct {
    Endpoint types.String `tfsdk:"endpoint"`
  }
  diags := req.Config.Get(ctx, &config)
  resp.Diagnostics.Append(diags...)
  // Store client in provider instance for resources to use
}

func (p *exampleProvider) Resources(ctx context.Context) []func() resource.Resource {
  return []func() resource.Resource{
    NewExampleResource,
  }
}

func (p *exampleProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
  return []func() datasource.DataSource{
    NewExampleDataSource,
  }
}
```

### Server Wiring

```go
func main() {
  opts := providerserver.ServeOpts{
    Address: "registry.terraform.io/namespace/example",
  }
  err := providerserver.Serve(context.Background(), func() provider.Provider {
    return &exampleProvider{version: "1.0.0"}
  }, opts)
  if err != nil {
    log.Fatal(err)
  }
}
```

## Resource Implementation

### Resource Interface

```go
type exampleResource struct {
  client *api.Client
}

func NewExampleResource() resource.Resource {
  return &exampleResource{}
}

func (r *exampleResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
  resp.TypeName = "example_widget"
}

func (r *exampleResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
  resp.Schema = resource_schema.Schema{
    Attributes: map[string]resource_schema.Attribute{
      "name": resource_schema.StringAttribute{
        Required: true,
        PlanModifiers: []planmodifier.String{
          stringplanmodifier.RequiresReplace(),
        },
      },
      "color": resource_schema.StringAttribute{
        Optional: true,
        Computed: true,
        PlanModifiers: []planmodifier.String{
          stringplanmodifier.UseStateForUnknown(),
        },
      },
    },
  }
}

func (r *exampleResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
  var plan ExampleModel
  resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
  if resp.Diagnostics.HasError() {
    return
  }
  // Call API to create resource
  // Store result in state
  state := plan
  resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *exampleResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
  // Read from API, populate state
}

func (r *exampleResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
  // Update existing resource
}

func (r *exampleResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
  // Delete resource
}
```

## Schema Attribute Types

### Attribute Options
| Option | Meaning | Use |
|--------|---------|-----|
| `Required` | User must provide | Identity-defining attributes |
| `Optional` | User can provide | Configurable settings |
| `Computed` | Provider populates | Read-only outputs (ARNs, IDs) |
| `Sensitive` | Masked in output | Secrets, passwords |
| `DeprecationMessage` | Warns on use | Deprecated attributes |

### Nested Attributes vs Blocks

| Pattern | Framework type | Use case |
|---------|---------------|----------|
| Single nested object | `SingleNestedAttribute` | One object (config block) |
| List of objects | `ListNestedAttribute` | Ordered list of objects |
| Set of objects | `SetNestedAttribute` | Unordered set of objects |
| Blocks (legacy) | `ListNestedBlock` / `SetNestedBlock` | Legacy patterns, prefer attributes |

**Framework best practice**: Use nested attributes over blocks. Blocks are retained for backward compatibility.

## Plan Modifiers

### Built-in Plan Modifiers
| Modifier | Effect |
|----------|--------|
| `RequiresReplace()` | Marks attribute for force-new recreation |
| `UseStateForUnknown()` | Preserves prior value when new value is unknown |
| `RequiresReplaceIf()` | Conditional force-new based on comparison |
| `UseStateForUnknown()` | Common for computed attributes during update |

### Custom Plan Modifiers

```go
var _ planmodifier.String = &myModifier{}

type myModifier struct{}

func (m *myModifier) Description(ctx context.Context) string {
  return "Ensures value is lowercase"
}

func (m *myModifier) MarkdownDescription(ctx context.Context) string {
  return m.Description(ctx)
}

func (m *myModifier) PlanModifyString(ctx context.Context, req planmodifier.StringRequest, resp *planmodifier.StringResponse) {
  if req.StateValue.IsNull() {
    return
  }
  resp.PlanValue = types.StringValue(strings.ToLower(req.PlanValue.ValueString()))
}
```

## Defaults

```go
&resource_schema.Schema{
  Attributes: map[string]resource_schema.Attribute{
    "name": resource_schema.StringAttribute{
      Optional: true,
      Computed: true,
      Default:  stringdefault.StaticString("default-name"),
    },
    "enabled": resource_schema.BoolAttribute{
      Optional: true,
      Computed: true,
      Default:  booldefault.StaticBool(true),
    },
  },
}
```

## Validators

```go
resource_schema.StringAttribute{
  Required: true,
  Validators: []validator.String{
    stringvalidator.LengthAtLeast(3),
    stringvalidator.LengthAtMost(63),
    stringvalidator.RegexMatches(regexp.MustCompile(`^[a-z]`), "must start with lowercase letter"),
  },
}

resource_schema.Int64Attribute{
  Optional: true,
  Validators: []validator.Int64{
    int64validator.Between(1, 65535),
  },
}
```
