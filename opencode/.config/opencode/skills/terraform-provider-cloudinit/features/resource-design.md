# Resource & Data Source Design

Design patterns for the cloudinit provider — shared model, resource vs data source lifecycle, schema patterns.

## Provider Structure

```go
type cloudinitProvider struct {
  version string
}

func (p *cloudinitProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
  resp.TypeName = "cloudinit"
}

func (p *cloudinitProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
  // No provider-level config needed
  resp.Schema = provider_schema.Schema{}
}

// Empty Configure — no API clients needed
func (p *cloudinitProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {}

func (p *cloudinitProvider) Resources(ctx context.Context) []func() resource.Resource {
  return []func() resource.Resource{
    NewCloudinitConfigResource,
  }
}

func (p *cloudinitProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
  return []func() datasource.DataSource{
    NewCloudinitConfigDataSource,
  }
}
```

## Shared Model

Both resource and data source use the same model and rendering logic:

```go
type configModel struct {
  Id          types.String `tfsdk:"id"`
  Parts       types.List   `tfsdk:"part"`
  Gzip        types.Bool   `tfsdk:"gzip"`
  Base64Encode types.Bool  `tfsdk:"base64_encode"`
  Boundary    types.String `tfsdk:"boundary"`
  Rendered    types.String `tfsdk:"rendered"`
}
```

## Resource Lifecycle

### Create — Generate Config

```go
func (r *configResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
  var data configModel
  resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  // Render MIME message
  update(&data)

  // Copy plan to state
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Read — No-Op (state is the source of truth)

```go
func (r *configResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
  // Content is stored in state, no external system to query
  // State already contains the rendered config
  // Nothing to refresh
}
```

### Update — Regenerate

```go
func (r *configResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
  var data configModel
  resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  update(&data)
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Delete — No-Op

```go
func (r *configResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
  // Nothing to delete — content was generated, not created externally
}
```

## Data Source Lifecycle

```go
func (d *configDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
  var data configModel
  resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  update(&data)
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

No plan modifiers needed (data sources don't have plan operations).

## Schema Design

```go
func configSchemaAttributes() map[string]datasource_schema.Attribute {
  return map[string]datasource_schema.Attribute{
    "gzip": datasource_schema.BoolAttribute{
      Optional: true,
      Computed: true,
      Default:  booldefault.StaticBool(true),
    },
    "base64_encode": datasource_schema.BoolAttribute{
      Optional: true,
      Computed: true,
      Default:  booldefault.StaticBool(true),
    },
    "boundary": datasource_schema.StringAttribute{
      Optional: true,
      Computed: true,
      Default:  stringdefault.StaticString("MIMEBOUNDARY"),
    },
    "part": datasource_schema.ListNestedBlock{
      // Uses blocks (not nested attributes) for backward compatibility
      // This is an exception to the "prefer attributes" rule
    },
    "rendered": datasource_schema.StringAttribute{
      Computed: true,
      Sensitive: false,
    },
    "id": datasource_schema.StringAttribute{
      Computed: true,
    },
  }
}
```

## Resource vs Data Source Differences

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| Create | Renders + stores in state | N/A |
| Read | No-op (state is truth) | Renders from config |
| Update | Regenerates on change | N/A |
| Delete | No-op | N/A |
| Plan | RequiresReplace on all changes | Plan-time evaluation |
| Use case | Track as managed resource | Generate per-apply |

## Testing

```go
func TestAccCloudinitConfig(t *testing.T) {
  resource.Test(t, resource.TestCase{
    ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
    Steps: []resource.TestStep{
      {
        Config: testAccCloudinitConfig_basic,
        Check: resource.ComposeTestCheckFunc(
          resource.TestCheckResourceAttrSet("data.cloudinit_config.test", "rendered"),
          resource.TestCheckResourceAttr("data.cloudinit_config.test", "gzip", "true"),
        ),
      },
    },
  })
}
```
