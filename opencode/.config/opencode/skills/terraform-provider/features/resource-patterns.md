# Resource Patterns

CRUD lifecycle, import, plan modifiers, and migration patterns for Terraform provider resources.

## CRUD Lifecycle (Framework)

### Create
```go
func (r *exampleResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
  var data ExampleModel
  resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  result, err := r.client.Create(ctx, &api.CreateInput{
    Name:  data.Name.ValueString(),
    Color: data.Color.ValueString(),
  })
  if err != nil {
    resp.Diagnostics.AddError("Create failed", err.Error())
    return
  }

  data.Id = types.StringValue(result.ID)
  data.Color = types.StringValue(result.Color)
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Read
```go
func (r *exampleResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
  var data ExampleModel
  resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  result, err := r.client.Get(ctx, data.Id.ValueString())
  if err != nil {
    if strings.Contains(err.Error(), "404") || strings.Contains(err.Error(), "not found") {
      resp.State.RemoveResource(ctx)
      return
    }
    resp.Diagnostics.AddError("Read failed", err.Error())
    return
  }

  data.Name = types.StringValue(result.Name)
  data.Color = types.StringValue(result.Color)
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Update
```go
func (r *exampleResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
  var data ExampleModel
  resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  result, err := r.client.Update(ctx, data.Id.ValueString(), &api.UpdateInput{
    Color: data.Color.ValueString(),
  })
  if err != nil {
    resp.Diagnostics.AddError("Update failed", err.Error())
    return
  }

  data.Color = types.StringValue(result.Color)
  resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}
```

### Delete
```go
func (r *exampleResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
  var data ExampleModel
  resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
  if resp.Diagnostics.HasError() {
    return
  }

  err := r.client.Delete(ctx, data.Id.ValueString())
  if err != nil {
    resp.Diagnostics.AddError("Delete failed", err.Error())
    return
  }
}
```

## ImportState

### Framework (Simple)

```go
func (r *exampleResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
  resource.ImportStatePassthroughID(ctx, path.Root("id"), req, resp)
}
```

### Framework (Custom)

```go
func (r *exampleResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
  parts := strings.Split(req.ID, "/")
  if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
    resp.Diagnostics.AddError("Invalid import ID", "Expected format: name/color")
    return
  }
  resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("name"), parts[0])...)
  resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("color"), parts[1])...)
}
```

### SDK v2

```go
Importer: &schema.ResourceImporter{
  StateContext: func(ctx context.Context, d *schema.ResourceData, m interface{}) ([]*schema.ResourceData, error) {
    idParts := strings.Split(d.Id(), ":")
    if len(idParts) != 2 {
      return nil, fmt.Errorf("expected ID in format name:color")
    }
    d.Set("name", idParts[0])
    d.Set("color", idParts[1])
    d.SetId(idParts[0] + "-" + idParts[1])
    return []*schema.ResourceData{d}, nil
  },
},
```

## Plan Modifier Patterns

### Suppress Diff on Normalization

When the API normalizes values (e.g., `q35` -> `pc-q35-10.1`), preserve user input:

```go
// Preserve user input on readback
resp.Diagnostics.Append(resp.State.SetAttribute(ctx, path.Root("machine"), types.StringValue(planMachine))...)
// But store the API-normalized value internally or skip set
```

### State Migration Between Schema Versions

```go
// Framework: use schema version field in model
type WidgetModelV0 struct {
  Id      types.String `tfsdk:"id"`
  OldName types.String `tfsdk:"old_name"`
}

type WidgetModelV1 struct {
  Id   types.String `tfsdk:"id"`
  Name types.String `tfsdk:"name"`
}

// In resource Schema
resp.Schema = resource_schema.Schema{
  Version: 1,
  // V1 schema
}
```

## Error Handling Patterns

### Resource Not Found During Plan

```go
func (r *exampleResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
  // ... API call fails with 404
  // Remove from state so Terraform recreates it
  resp.State.RemoveResource(ctx)
}
```

### Retry on API Errors

```go
// SDK v2 — retry on 429/503
func resourceExampleWidgetRead(d *schema.ResourceData, m interface{}) error {
  return resource.Retry(2*time.Minute, func() *resource.RetryError {
    widget, err := client.GetWidget(d.Id())
    if err != nil {
      if isRetryable(err) {
        return resource.RetryableError(err)
      }
      return resource.NonRetryableError(err)
    }
    return nil
  })
}
```
