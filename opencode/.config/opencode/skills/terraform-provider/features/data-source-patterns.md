# Data Source Patterns

Read semantics, schema design, and multi-attribute filtering for Terraform provider data sources.

## Data Source Interface (Framework)

```go
type exampleDataSource struct{}

func NewExampleDataSource() datasource.DataSource {
  return &exampleDataSource{}
}

func (d *exampleDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
  resp.TypeName = "example_widgets"
}

func (d *exampleDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
  resp.Schema = datasource_schema.Schema{
    Attributes: map[string]datasource_schema.Attribute{
      "id": datasource_schema.StringAttribute{
        Computed: true,
      },
      "name": datasource_schema.StringAttribute{
        Optional: true,
      },
      "widgets": datasource_schema.ListNestedAttribute{
        Computed: true,
        NestedObject: datasource_schema.NestedAttributeObject{
          Attributes: map[string]datasource_schema.Attribute{
            "id":    datasource_schema.StringAttribute{ Computed: true },
            "name":  datasource_schema.StringAttribute{ Computed: true },
            "color": datasource_schema.StringAttribute{ Computed: true },
          },
        },
      },
    },
  }
}

func (d *exampleDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
  var config struct {
    Name types.String `tfsdk:"name"`
  }
  resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
  if resp.Diagnostics.HasError() {
    return
  }

  // Filter based on config
  results, err := d.client.List(ctx, api.ListInput{
    NameFilter: config.Name.ValueString(),
  })
  if err != nil {
    resp.Diagnostics.AddError("Read failed", err.Error())
    return
  }

  // Map results to state
  state := struct {
    Id      types.String `tfsdk:"id"`
    Widgets []WidgetModel `tfsdk:"widgets"`
  }{
    Id: types.StringValue("all"),
  }
  for _, w := range results {
    state.Widgets = append(state.Widgets, WidgetModel{
      Id:    types.StringValue(w.ID),
      Name:  types.StringValue(w.Name),
      Color: types.StringValue(w.Color),
    })
  }

  resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}
```

## Schema Differences from Resources

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| Attributes | Required + Optional + Computed | Optional (filter) + Computed (output) |
| Write operations | Create, Update, Delete | None (Read-only) |
| Plan modifiers | `RequiresReplace`, `UseStateForUnknown` | Not needed |
| Import | Supported | N/A |
| Lifecycle | CRUD | Single Read |
| `ForceNew` | Common | Not applicable |

## Filtering Patterns

### Single Attribute Filter

```go
resp.Schema = datasource_schema.Schema{
  Attributes: map[string]datasource_schema.Attribute{
    "name": datasource_schema.StringAttribute{
      Optional: true,
      Description: "Filter widgets by name",
    },
    "widgets": datasource_schema.ListNestedAttribute{
      Computed: true,
      NestedObject: datasource_schema.NestedAttributeObject{
        Attributes: map[string]datasource_schema.Attribute{
          "id":   datasource_schema.StringAttribute{ Computed: true },
          "name": datasource_schema.StringAttribute{ Computed: true },
        },
      },
    },
  },
}
```

### Multi-Attribute Filter

```go
type WidgetFilter struct {
  Name   types.String `tfsdk:"name"`
  Color  types.String `tfsdk:"color"`
  Region types.String `tfsdk:"region"`
  Tags   types.Map    `tfsdk:"tags"`
}
```

## Data Source vs Resource with `terraform_remote_state`

| Aspect | Data Source | `terraform_remote_state` |
|--------|-------------|-------------------------|
| Data source | Provider API call | State file read |
| Dependency | Requires provider config | Requires state backend config |
| Plan-time data | Yes (with `default` in schema) | Yes (with `default` config) |
| Use case | Reading cloud resources | Cross-module state access |
| Provider coupling | Yes | No |

## SDK v2 Data Source

```go
func dataSourceExampleWidgets() *schema.Resource {
  return &schema.Resource{
    ReadContext: dataSourceExampleWidgetsRead,
    Schema: map[string]*schema.Schema{
      "name": {
        Type:     schema.TypeString,
        Optional: true,
      },
      "widgets": {
        Type:     schema.TypeList,
        Computed: true,
        Elem: &schema.Resource{
          Schema: map[string]*schema.Schema{
            "id":    { Type: schema.TypeString, Computed: true },
            "name":  { Type: schema.TypeString, Computed: true },
            "color": { Type: schema.TypeString, Computed: true },
          },
        },
      },
    },
  }
}
```
