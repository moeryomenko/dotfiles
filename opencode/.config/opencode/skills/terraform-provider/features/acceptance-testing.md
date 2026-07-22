# Acceptance Testing

Test patterns for Terraform providers using the acceptance test framework, unit tests, sweepers, and mock providers.

## Acceptance Test Framework

### Basic Test (Framework Provider)

```go
package provider_test

import (
  "testing"
  "github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

func TestAccExampleWidget_basic(t *testing.T) {
  resource.Test(t, resource.TestCase{
    ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
    Steps: []resource.TestStep{
      {
        Config: testAccExampleWidgetConfig_basic(),
        Check: resource.ComposeAggregateTestCheckFunc(
          resource.TestCheckResourceAttr("example_widget.test", "name", "test-widget"),
          resource.TestCheckResourceAttrSet("example_widget.test", "id"),
          resource.TestCheckResourceAttr("example_widget.test", "color", "blue"),
        ),
      },
    },
  })
}

func testAccExampleWidgetConfig_basic() string {
  return `
provider "example" {
  endpoint = "http://localhost:8080"
}

resource "example_widget" "test" {
  name  = "test-widget"
  color = "blue"
}
`
}
```

### Test Setup

```go
var testAccProtoV6ProviderFactories = map[string]func() tfprotov6.ProviderServer{
  "example": providerserver.NewProtocol6WithError(New()),
}
```

### Multi-Step Tests

```go
func TestAccExampleWidget_update(t *testing.T) {
  resource.Test(t, resource.TestCase{
    ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
    Steps: []resource.TestStep{
      // Create
      {
        Config: testAccExampleWidgetConfig("blue"),
        Check: resource.ComposeAggregateTestCheckFunc(
          resource.TestCheckResourceAttr("example_widget.test", "color", "blue"),
        ),
      },
      // Update
      {
        Config: testAccExampleWidgetConfig("green"),
        Check: resource.ComposeAggregateTestCheckFunc(
          resource.TestCheckResourceAttr("example_widget.test", "color", "green"),
        ),
      },
      // Import
      {
        ResourceName:      "example_widget.test",
        ImportState:       true,
        ImportStateVerify: true,
      },
    },
  })
}
```

## Unit Testing (Framework)

### Schema Validation Tests

```go
func TestExampleWidgetSchema(t *testing.T) {
  r := NewExampleResource()
  req := resource.SchemaRequest{}
  resp := resource.SchemaResponse{}
  r.Schema(context.Background(), req, &resp)

  if resp.Schema.Attributes["name"] == nil {
    t.Fatal("expected name attribute")
  }

  nameAttr, ok := resp.Schema.Attributes["name"].(resource_schema.StringAttribute)
  if !ok {
    t.Fatal("expected name to be StringAttribute")
  }
  if !nameAttr.Required {
    t.Fatal("expected name to be required")
  }
}
```

### Plan Modifier Tests

```go
func TestMyPlanModifier(t *testing.T) {
  m := &myModifier{}
  req := planmodifier.StringRequest{
    PlanValue:    types.StringValue("MIXEDCASE"),
    StateValue:   types.StringNull(),
    ConfigValue:  types.StringValue("MIXEDCASE"),
  }
  resp := &planmodifier.StringResponse{}
  m.PlanModifyString(context.Background(), req, resp)

  if resp.PlanValue.ValueString() != "mixedcase" {
    t.Fatalf("expected lowercase, got %s", resp.PlanValue.ValueString())
  }
}
```

## Sweepers

### Sweeper Pattern

```go
func init() {
  resource.AddTestSweepers("example_widget", &resource.Sweeper{
    Name: "example_widget",
    F:    sweepWidgets,
    Dependencies: []string{"example_child"},
  })
}

func sweepWidgets(region string) error {
  client, err := getClientForRegion(region)
  if err != nil {
    return err
  }
  widgets, err := client.ListWidgets()
  if err != nil {
    return err
  }
  for _, w := range widgets {
    if strings.HasPrefix(w.Name, "test-") {
      if err := client.DeleteWidget(w.ID); err != nil {
        log.Printf("Error deleting %s: %s", w.ID, err)
      }
    }
  }
  return nil
}
```

### Running Sweepers

```bash
# Sweep all resources
make sweep

# Sweep specific resource
SWEEP=example_widget make sweep
```

## Test Conventions

### Naming

| Pattern | Example |
|---------|---------|
| `TestAcc<Resource>_basic` | `TestAccExampleWidget_basic` |
| `TestAcc<Resource>_update` | `TestAccExampleWidget_update` |
| `TestAcc<Resource>_import` | `TestAccExampleWidget_import` |
| `TestAcc<Resource>_<variant>` | `TestAccExampleWidget_disappears` |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `TF_ACC=1` | Enable acceptance tests |
| `TF_ACC_TERRAFORM_PATH` | Custom terraform binary |
| `TF_ACC_LOG_PATH` | Test log output |
| `TF_LOG=DEBUG` | Verbose logging |

### Pre-Commit Checklist

- [ ] All resources have test names prefixed `test-`
- [ ] Sweepers clean up leaked resources
- [ ] Tests cover: create, update, import, disappear (external deletion)
- [ ] ImportStateVerify includes all attributes
- [ ] Tests run with `TF_ACC=1` against real API
- [ ] Unit tests (no `TF_ACC`) pass for schema validation
