# Go Patterns in Terraform/OpenTofu Core

Design patterns, conventions, and idiomatic Go used in the Terraform and OpenTofu codebases.

## Interface Patterns

### Plugin Model
Terraform uses a provider-plugin architecture where providers are separate processes:

```go
// Provider interface (simplified)
type ProviderInterface interface {
  GetProviderSchema() (*ProviderSchema, error)
  ValidateDataSourceConfig(ValidateDataSourceConfigRequest) (ValidateDataSourceConfigResponse, error)
  ValidateResourceConfig(ValidateResourceConfigRequest) (ValidateResourceConfigResponse, error)
  PlanResourceChange(PlanResourceChangeRequest) (PlanResourceChangeResponse, error)
  ApplyResourceChange(ApplyResourceChangeRequest) (ApplyResourceChangeResponse, error)
  ReadResource(ReadResourceRequest) (ReadResourceResponse, error)
  ReadDataSource(ReadDataSourceRequest) (ReadDataSourceResponse, error)
  Stop() error
}
```

### Graph Node Interface

```go
type GraphNode interface {
  Name() string
}

type GraphNodeResource interface {
  GraphNode
  ResourceAddr() addrs.AbsResourceInstance
}

type GraphNodeDynamicExpandable interface {
  GraphNode
  DynamicExpand(EvalContext) (*Graph, error)
}

type GraphNodeModuleInstance interface {
  GraphNode
  ModuleInstance() addrs.ModuleInstance
}
```

## Graph Walk Semantics

### Walk Phases

```go
// Each walk phase processes the graph differently
type Walker struct {
  Operation       WalkOperation
  StopContext     context.Context
  Config         *configs.Config
  State          *states.State
  ProviderCache  *providercache.Cache

  // Callbacks per vertex
  EnterPath      func(addrs.ModuleInstance) WalkResult
  EnterEvalTree  func(GraphNode) EvalNode
  EnterVertex    func(GraphNode) WalkResult
  ExitVertex     func(GraphNode, interface{}) WalkResult
}
```

### EvalNode Pattern

Each graph node produces an `EvalNode` tree that defines execution:

```go
type EvalApply struct {
  Addr       addrs.ResourceInstance
  Config     *configs.Resource
  Provider   *providers.Interface
  State      **states.ResourceInstanceObject

  // Output
  NewState   **states.ResourceInstanceObject
}

func (n *EvalApply) Eval(ctx EvalContext) (interface{}, error) {
  provider := *n.Provider
  req := providers.ApplyResourceChangeRequest{
    PlannedState:   n.PlannedState,
    Config:         n.Config,
    ProviderMeta:   n.ProviderMeta,
  }
  resp := provider.ApplyResourceChange(req)
  *n.NewState = resp.NewState
  return nil, nil
}
```

## Testing Patterns

### Test Helpers

```go
// Mock provider
type MockProvider struct {
  providers.ProviderInterface
  GetProviderSchemaFn    func() (*providers.ProviderSchema, error)
  PlanResourceChangeFn   func(providers.PlanResourceChangeRequest) (providers.PlanResourceChangeResponse, error)
  ApplyResourceChangeFn  func(providers.ApplyResourceChangeRequest) (providers.ApplyResourceChangeResponse, error)
}

func (m *MockProvider) GetProviderSchema() (*providers.ProviderSchema, error) {
  return m.GetProviderSchemaFn()
}
```

### Plan/Apply Test Pattern

```go
func TestResourceCreate(t *testing.T) {
  provider := &MockProvider{
    PlanResourceChangeFn: func(req providers.PlanResourceChangeRequest) (providers.PlanResourceChangeResponse, error) {
      // Return planned state
    },
    ApplyResourceChangeFn: func(req providers.ApplyResourceChangeRequest) (providers.ApplyResourceChangeResponse, error) {
      // Verify correct values passed to provider
      return providers.ApplyResourceChangeResponse{
        NewState: req.PlannedState,
      }, nil
    },
  }

  // Configure test context
  ctx := testContext(t, provider)

  // Execute plan and apply
  plan, diags := ctx.Plan(config, state)
  if diags.HasErrors() {
    t.Fatal(diags.Err())
  }

  state, diags = ctx.Apply(plan)
  if diags.HasErrors() {
    t.Fatal(diags.Err())
  }
}
```

## Config Loading Pipeline

The HCL-to-internal-config pipeline follows a well-defined sequence:

### Flow

```
getmodules → configs.NewParser → configs.BuildConfig → ReferenceTransformer → ModuleWalker
```

1. **`getmodules`** — Download remote modules referenced by `source` arguments
2. **`configs.NewParser(dir)`** — Parse HCL files in a directory, produce `*configs.Module`
3. **`configs.BuildConfig(root, children)`** — Assemble the module tree from root and child modules
4. **`ReferenceTransformer`** — Resolve cross-config references between resources, outputs, and variables
5. **`ModuleWalker`** — Walk the module tree and validate input variable types against their declarations

### Internal gRPC Wiring

Config loading does not directly interact with the gRPC layer, but `internal/grpcwrap/` provides
the bridge between core's `providers.Interface` and the provider plugin gRPC protocol. After
config loading produces the module tree, the graph walk phase uses `grpcwrap` to send provider
calls.

### Cross-References

For provider resolution details, see [`provider-resolution.md`](provider-resolution.md).
For test harness patterns using this pipeline, see [`testing.md`](testing.md).

```go
func loadAndBuildConfig(dir string) (*configs.Config, error) {
    parser := configs.NewParser(dir)
    mod, diags := parser.LoadConfigDir(dir)
    if diags.HasErrors() {
        return nil, diags.Err()
    }
    config, diags := configs.BuildConfig(mod, configs.RootModuleCall)
    if diags.HasErrors() {
        return nil, diags.Err()
    }
    return config, nil
}
```

## Code Conventions

### Imports
```go
import (
  "fmt"
  "sort"

  "github.com/hashicorp/terraform/internal/..."
  "github.com/zclconf/go-cty/cty"
)
```

Standard ordering: stdlib -> external -> internal. `goimports` enforces this.

### Error Handling
- No testify assertions — use standard `testing.T` methods
- Use `github.com/google/go-cmp/cmp` for deep comparison
- Diagnostics use `tfdiags` package for structured errors

### Build Tags
```go
//go:build !enterprise
// +build !enterprise
```

### Version Embedding
```go
//go:embed VERSION
var versionFile string
```
