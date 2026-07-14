# Core Testing Patterns

Testing infrastructure for Terraform and OpenTofu core — test helpers, mock providers, plan/apply test patterns.

## Test Structure

### Test Packages

```go
// Unit test — no external dependencies
package terraform
func TestResourceApply(t *testing.T) { ... }

// Acceptance test — requires real infrastructure
package command
func TestAccPlan(t *testing.T) { ... }

// E2E test — full binary test
package e2etest
func TestE2EBasicPlan(t *testing.T) { ... }
```

### Test Helpers

```go
// Create a test context with mock providers
func testContext(t *testing.T, providers map[string]providers.Interface) *Context {
  t.Helper()
  // Returns a Context configured for testing
}

// Create a test plan
func testPlan(t *testing.T, config string, state *states.State) *plans.Plan {
  t.Helper()
  ctx := testContext(t, nil)
  plan, diags := ctx.Plan(config, state)
  if diags.HasErrors() {
    t.Fatal(diags.Err())
  }
  return plan
}
```

## Mock Providers

### Basic Mock

```go
type simpleMockProvider struct {
  providers.ProviderInterface
  schema *providers.ProviderSchema
}

func (m *simpleMockProvider) GetProviderSchema() (*providers.ProviderSchema, error) {
  return m.schema, nil
}

func (m *simpleMockProvider) PlanResourceChange(req providers.PlanResourceChangeRequest) (providers.PlanResourceChangeResponse, error) {
  return providers.PlanResourceChangeResponse{
    PlannedState: req.ProposedNewState,
  }, nil
}
```

### Recording Mock

```go
type recordingProvider struct {
  simpleMockProvider
  Creates []providers.ApplyResourceChangeRequest
  Reads   []providers.ReadResourceRequest
}

func (p *recordingProvider) ApplyResourceChange(req providers.ApplyResourceChangeRequest) (providers.ApplyResourceChangeResponse, error) {
  p.Creates = append(p.Creates, req)
  return providers.ApplyResourceChangeResponse{
    NewState: req.PlannedState,
  }, nil
}

func (p *recordingProvider) ReadResource(req providers.ReadResourceRequest) (providers.ReadResourceResponse, error) {
  p.Reads = append(p.Reads, req)
  return providers.ReadResourceResponse{
    NewState: req.CurrentState,
  }, nil
}
```

## Plan Testing Patterns

### Verify No Changes

```go
func TestNoChanges(t *testing.T) {
  state := testStateFromConfig(t, testConfig)
  plan := testPlan(t, testConfig, state)
  if plan.Changes.Empty() {
    t.Log("expected: no changes")
  }
  for _, change := range plan.Changes.Resources {
    t.Errorf("unexpected change: %s %s", change.Addr, change.Action)
  }
}
```

### Verify Specific Change

```go
func TestResourceCreate(t *testing.T) {
  plan := testPlan(t, createConfig, nil)
  var found bool
  for _, change := range plan.Changes.Resources {
    if change.Addr.String() == "test_resource.test" {
      found = true
      if change.Action != plans.Create {
        t.Errorf("expected Create action, got %s", change.Action)
      }
    }
  }
  if !found {
    t.Error("expected test_resource.test in plan changes")
  }
}
```

## Test Provider Patterns

### Built-in Test Providers

The codebase includes pre-built test providers under `internal/terraform/providers/`:

- **`provider-simple/`** — Minimal provider stub implementing `providers.Interface` for unit tests.
  Supports basic CRUD lifecycle without real infrastructure.
- **`provider-simple-v6/`** — Same as `provider-simple/` but implements the gRPC protocol v6
  provider interface. Used for testing the protocol translation layer in `internal/grpcwrap/`.

Both are imported in test files via:

```go
import (
    _ "github.com/hashicorp/terraform/internal/terraform/providers/provider-simple"
    // _ "github.com/opentofu/opentofu/internal/tofu/providers/provider-simple-v6"
)
```

## Test Harness: terraform.Test

The `terraform.Test` harness provides an end-to-end config-to-apply test pattern:

```go
func TestResourceBasic(t *testing.T) {
    provider := &simpleMockProvider{}

    // terraform.Test parses config, creates mock context, runs plan+apply
    terraform.Test(t, terraform.TestConfig{
        Providers: map[string]providers.Interface{
            "test": provider,
        },
        Steps: []terraform.TestStep{
            {
                Config: `resource "test_resource" "a" { value = "hello" }`,
                Check: func(s *terraform.TestState) error {
                    if s.RootModule().Resources["test_resource.a"].Primary.Attributes["value"] != "hello" {
                        return fmt.Errorf("bad value")
                    }
                    return nil
                },
            },
        },
    })
}
```

## Graph Walk Test Patterns

Tests for graph walk behavior use the `Walker` struct directly:

```go
func TestGraphWalkOrder(t *testing.T) {
    g := dag.NewGraph()
    g.Add(&dag.Vertex{Name: "root"})
    g.Add(&dag.Vertex{Name: "child"})
    g.Connect(dag.BasicEdge("child", "root"))

    walker := &dag.Walker{Callback: walkFn}
    walker.Update(g)
    walker.Wait()

    // Verify topological order: root before child
}
```

Common graph walk test patterns:
- **Dependency ordering** — Test that dependent vertices execute after their dependencies
- **Concurrent execution** — Test that independent vertices execute concurrently using `sync.WaitGroup`
- **Error propagation** — Test that a failing vertex stops the walk
- **Reverse destroy order** — Test that destroy walks execute in reverse topological order

## State Mutation Test Patterns

State mutation tests verify the state manager behavior:

```go
func TestStateMgrReadWrite(t *testing.T) {
    mgr := statemgr.NewTestStateMgr()

    // Write initial state
    s := states.NewState()
    mgr.WriteState(s)

    // Read back and compare
    got := mgr.State()
    if !reflect.DeepEqual(s, got) {
        t.Errorf("state round-trip mismatch")
    }
}
```

Common state mutation test patterns:
- **Read-after-write** — Verify state persistence round-trip
- **Lock acquisition** — Verify `Lock`/`Unlock` pairing with `LockInfo`
- **Concurrent access** — Verify `Lock` blocks concurrent writes (use `-race` detector)
- **Force-unlock** — Verify `Unlock` with stolen lock ID

## Test Conventions by Codebase

### Terraform
```bash
# Run unit tests
go test ./...

# Run with race detector on critical packages
go test -race ./internal/terraform ./internal/command ./internal/states ./internal/promising

# Acceptance tests
TF_ACC=1 go test -v ./internal/command/e2etest

# Full CI check
make fmtcheck importscheck vetcheck copyright generate staticcheck exhaustive protobuf
```

- No testify — use `github.com/go-test/deep`
- Test data in `testdata/` directories
- Staticcheck config in `staticcheck.conf`

### OpenTofu
```bash
# Run unit tests
go test ./...

# Acceptance tests
TF_ACC=1 go test ./...

# Integration tests
make test-s3
make test-pg
make test-consul

# Lint
make golangci-lint
```

- Mock stubs via `go tool go.uber.org/mock/mockgen`
- DCO sign-off on every commit (`git commit -s`)
- golangci-lint v2.6.0
