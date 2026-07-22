# Core Architecture Technical Patterns

Internal architecture of Terraform and OpenTofu — graph engine, state management, plans, backends, config loading, and provider resolution.

## Package Architecture

### Terraform Core Packages

```
internal/
├── terraform/         # Core engine (graph builder, apply, plan walk)
│   ├── graph.go       # Graph construction entry point
│   ├── apply.go       # Apply walk implementation
│   ├── plan.go        # Plan walk implementation
│   ├── walk.go        # Graph walk infrastructure
│   ├── node_*.go      # Graph node types (resources, datasources, provisioners)
│   └── transform_*.go # Graph transformers
├── dag/               # Directed Acyclic Graph engine
│   ├── graph.go       # Graph data structure
│   ├── walk.go        # Topological walk
│   └── set.go         # Graph set operations
├── states/            # State representation
│   ├── state.go       # State struct, InstanceObjectSyncer
│   ├── instance.go    # ResourceInstanceObject
│   └── statemgr/      # State manager interface
├── plans/             # Plan representation
│   ├── plan.go        # Plan struct, Change, Action
│   └── objchange/     # Proposed state calculation
├── backend/           # Backend abstraction
│   ├── backend.go     # Backend interface
│   └── local/         # Local backend (operation execution)
├── configs/           # Config parsing
│   └── config.go      # Config struct, Module, Resource
└── getproviders/      # Provider resolution
    ├── provider.go    # Provider struct
    └── registry.go    # Registry client
```

### OpenTofu Differences

OpenTofu mirrors Terraform's structure with these changes:
- `internal/tofu/` instead of `internal/terraform/`
- `internal/encryption/` — State encryption (feature not in Terraform)
- `internal/engine/` — Experimental runtime (gated by `TOFU_X_EXPERIMENTAL_RUNTIME=1`)
- `internal/oci/` — OCI registry for provider distribution

**Module path difference**: Terraform uses `github.com/hashicorp/terraform` as its Go module path; OpenTofu uses `github.com/opentofu/opentofu`. All internal imports must use the correct path for the target codebase. When porting code between the two, update every `internal/` import prefix.

## Graph Engine

### Graph Construction Phases

1. **Config loading** — Parse HCL into `configs.Config` tree
2. **Resource counting** — Evaluate `count`/`for_each` expressions
3. **Graph building** — Create vertices for each resource instance
4. **Edge creation** — Add dependency edges from references and `depends_on`
5. **Transformer application** — Dynamic expansion (`GraphNodeDynamicExpandable`)
6. **Validation** — Cycle detection, missing dependencies

### Graph Walk

```go
// WalkOperation type
type WalkOperation byte
const (
  WalkInvalid  WalkOperation = iota
  WalkApply
  WalkPlan
  WalkPlanDestroy
  WalkRefresh
  WalkValidate
  WalkDestroy
  WalkImport
)
```

- Topological sort executes operations in dependency order
- Independent vertices execute concurrently (provisioner-defined)
- Destroy walks in reverse topological order

### Dynamic Expansion

Resources with `count` or `for_each` implement `GraphNodeDynamicExpandable`:

```go
type GraphNodeDynamicExpandable interface {
  DynamicExpand(ctx EvalContext) (*Graph, error)
}
```

At walk time, the graph calls `DynamicExpand` to replace the placeholder vertex with N instance vertices.

## State Management

### State Manager Interface

```go
type Full interface {
  State() *State                         // Read current state
  WriteState(*State) error               // Write state
  RefreshState() error                   // Refresh from backend
  Lock(info *LockInfo) (string, error)   // Acquire lock
  Unlock(id string) error                // Release lock
}
```

### State Operations
- **Refresh**: Calls provider `ReadResource` for each managed resource, updates state
- **Plan**: Compares refreshed state to desired config, produces planned changes
- **Apply**: Executes planned changes, persists new state

## Plan Representation

```go
type Plan struct {
  VariableValues   map[string]DynamicValue
  Changes          *Changes
  TargetAddrs     []addrs.Targetable
  ProviderSHA256s map[string][]byte
  Backend          BackendState
  UIMode           UIMode
}

type Changes struct {
  Resources []*ResourceInstanceChange
  Outputs   []*OutputChange
}

type ResourceInstanceChange struct {
  Addr          addrs.AbsResourceInstance
  DeposedKey    states.DeposedKey
  ProviderAddr  addrs.AbsProviderConfig
  Change        *Change
  RequiredMove  *bool
}
```

## Backend Interface

```go
type Backend interface {
  // State management
  StateMgr(name string) (statemgr.Full, error)

  // Operation execution (only local/remote/cloud)
  Operation(ctx context.Context, op *Operation) (*State, error)
}
```

**Important**: Only `local` and `remote`/`cloud` backends implement `Operation`. All other backends (S3, GCS, AzureRM, etc.) implement only `StateMgr` for state storage.

## Config Loading Pipeline

1. `getmodules` — Download remote modules
2. `configs.NewParser(dir)` — Parse HCL files in directory
3. `configs.BuildConfig(root, children)` — Build config tree
4. `ReferenceTransformer` — Resolve cross-config references
5. `ModuleWalker` — Walk module tree, validate inputs

```go
// Config loading in terraform core
import (
    "github.com/hashicorp/terraform/internal/configs"     // Terraform
    // "github.com/opentofu/opentofu/internal/configs"    // OpenTofu
)

func loadConfig(dir string) (*configs.Config, tfdiags.Diagnostics) {
    parser := configs.NewParser(dir)
    mod, diags := parser.LoadConfigDir(dir)
    if diags.HasErrors() {
        return nil, diags
    }
    config, diags := configs.BuildConfig(mod, configs.RootModuleCall)
    if diags.HasErrors() {
        return nil, diags
    }
    return config, nil
}
```

## Provider Resolution Pipeline

1. `getproviders.Query()` — Resolve version constraints
2. `providercache.Installer()` — Download/cache provider plugins
3. `plugin.Client()` — Start provider process
4. `grpcwrap` — Wrap gRPC for protocol v5/v6

```go
import (
    "github.com/hashicorp/terraform/internal/getproviders"  // Terraform
    // "github.com/opentofu/opentofu/internal/getproviders" // OpenTofu
)

func resolveAndInstall(ctx context.Context, reqs getproviders.Requirements) error {
    available, err := getproviders.Query(ctx, reqs, getproviders.DefaultPlatform)
    if err != nil {
        return err
    }
    installer := providercache.NewInstaller(cache)
    _, err = installer.EnsureProviderVersions(ctx, available)
    return err
}
```

## Build & Test

### Terraform
```bash
# Dev build
go install .

# Release build
go build -ldflags "-w -s -X 'github.com/hashicorp/terraform/version.dev=no'" -o bin/ .

# Run tests
go test ./...
go test -race ./internal/terraform ./internal/command ./internal/states

# Acceptance tests
TF_ACC=1 go test -v ./internal/command/e2etest
```

### OpenTofu
```bash
# Build
go build ./cmd/tofu

# Experimental engine
make build-experimental

# Unit tests
go test ./...

# Integration tests
make test-s3  # or test-pg, test-consul, test-kubernetes
```
