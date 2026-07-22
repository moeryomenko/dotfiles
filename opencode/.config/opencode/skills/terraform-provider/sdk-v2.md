# Terraform Plugin SDK v2

Legacy Terraform Plugin SDK v2 patterns for maintaining existing providers. New providers should use the Plugin Framework; this reference is for migration and maintenance.

## Package Structure

| Package | Purpose | Key Types |
|---------|---------|-----------|
| `helper/schema` | Core provider framework | `Resource`, `Schema`, `ResourceData` |
| `helper/validation` | Field validators | `StringInSlice`, `IntBetween`, `NoZeroValues` |
| `helper/customdiff` | Custom diff composers | `ComposedIf`, `IfChange`, `Sequence` |
| `helper/resource` | Acceptance test framework | `TestCase`, `TestStep`, `ResourceAttr` |
| `helper/structure` | Flattening/expansion utilities | `ExpandJson`, `FlattenJson` |
| `plugin` | Provider server | `ServeOpts`, `Provider` |
| `terraform` | Provider interface types | `ResourceProvider`, `InstanceState` |

## Provider Structure

```go
func Provider() *schema.Provider {
  return &schema.Provider{
    Schema: map[string]*schema.Schema{
      "endpoint": {
        Type:        schema.TypeString,
        Optional:    true,
        DefaultFunc: schema.EnvDefaultFunc("ENDPOINT", nil),
      },
    },
    ResourcesMap: map[string]*schema.Resource{
      "example_widget": resourceExampleWidget(),
    },
    DataSourcesMap: map[string]*schema.Resource{
      "example_widgets": dataSourceExampleWidgets(),
    },
    ConfigureFunc: providerConfigure,
  }
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
  endpoint := d.Get("endpoint").(string)
  return api.NewClient(endpoint), nil
}
```

## Resource Structure

```go
func resourceExampleWidget() *schema.Resource {
  return &schema.Resource{
    Create: resourceExampleWidgetCreate,
    Read:   resourceExampleWidgetRead,
    Update: resourceExampleWidgetUpdate,
    Delete: resourceExampleWidgetDelete,
    Importer: &schema.ResourceImporter{
      State: schema.ImportStatePassthrough,
    },
    Timeouts: &schema.ResourceTimeout{
      Create: schema.DefaultTimeout(10 * time.Minute),
      Delete: schema.DefaultTimeout(5 * time.Minute),
    },
    Schema: map[string]*schema.Schema{
      "name": {
        Type:     schema.TypeString,
        Required: true,
        ForceNew: true,
      },
      "color": {
        Type:     schema.TypeString,
        Optional: true,
        Computed: true,
      },
      "tags": {
        Type: schema.TypeMap,
        Elem: &schema.Schema{Type: schema.TypeString},
        Optional: true,
      },
    },
  }
}
```

## CRUD Operations

```go
func resourceExampleWidgetCreate(d *schema.ResourceData, m interface{}) error {
  client := m.(*api.Client)
  name := d.Get("name").(string)
  color := d.Get("color").(string)

  widget, err := client.CreateWidget(name, color)
  if err != nil {
    return err
  }

  d.SetId(widget.ID)
  d.Set("color", widget.Color)
  return nil
}

func resourceExampleWidgetRead(d *schema.ResourceData, m interface{}) error {
  client := m.(*api.Client)
  id := d.Id()

  widget, err := client.GetWidget(id)
  if err != nil {
    if strings.Contains(err.Error(), "404") {
      d.SetId("")
      return nil
    }
    return err
  }

  d.Set("name", widget.Name)
  d.Set("color", widget.Color)
  return nil
}

func resourceExampleWidgetUpdate(d *schema.ResourceData, m interface{}) error {
  client := m.(*api.Client)
  id := d.Id()

  if d.HasChange("color") {
    _, err := client.UpdateWidget(id, d.Get("color").(string))
    if err != nil {
      return err
    }
  }

  return resourceExampleWidgetRead(d, m)
}

func resourceExampleWidgetDelete(d *schema.ResourceData, m interface{}) error {
  client := m.(*api.Client)
  id := d.Id()
  return client.DeleteWidget(id)
}
```

## CustomizeDiff

```go
func resourceExampleWidget() *schema.Resource {
  return &schema.Resource{
    CustomizeDiff: customdiff.All(
      customdiff.ValidateValue("name", func(ctx context.Context, value, meta interface{}) error {
        name := value.(string)
        if len(name) < 3 {
          return fmt.Errorf("name must be at least 3 characters")
        }
        return nil
      }),
      customdiff.ComputedIf("color", func(ctx context.Context, d *schema.ResourceDiff, meta interface{}) bool {
        return d.HasChange("name")
      }),
    ),
  }
}
```

## StateFunc and Timeouts

```go
"memory": {
  Type:     schema.TypeInt,
  Optional: true,
  Default:  1024,
  StateFunc: func(val interface{}) string {
    return fmt.Sprintf("%dMB", val.(int))
  },
},

Timeouts: &schema.ResourceTimeout{
  Create: schema.DefaultTimeout(30 * time.Minute),
  Delete: schema.DefaultTimeout(30 * time.Minute),
  Update: schema.DefaultTimeout(30 * time.Minute),
  Default: schema.DefaultTimeout(20 * time.Minute),
},
```

## Migration to Plugin Framework

### Key Differences
| Aspect | SDK v2 | Plugin Framework |
|--------|--------|-----------------|
| Schema definition | `map[string]*Schema` with type constants | Go types + attributes |
| Type handling | Loose (`schema.TypeString`) | Strong (`types.String`) |
| Nested objects | Blocks (`Elem: Resource`) | Nested attributes (`SingleNestedAttribute`) |
| Plan modification | `CustomizeDiff` | Plan modifiers |
| Defaults | `DefaultFunc` | `Default` field |
| Validation | `ValidateFunc` | Validators |
| Diagnostics | Single error return | `diag.Diagnostics` type |
| State access | `d.Get("name")` string keys | `plan.Get(ctx, &model)` typed structs |
| Protocol | v5 (or v6 via grpcwrap) | v6 native |

### Migration Strategy
1. Create Framework provider alongside SDK v2 provider (dual registration)
2. Migrate resources one at a time
3. Test with `TF_ACC=1` against real infrastructure
4. Remove SDK v2 provider when all resources migrated
5. Update docs/examples for Framework
