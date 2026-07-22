# Provider Resolution

Provider installation, version resolution, registry protocol, and provider cache internals.

## Resolution Pipeline

### Steps

1. **Discovery** — Search `required_providers` in all modules
2. **Query** — Resolve version constraints against registry
3. **Install** — Download or cache appropriate version
4. **Verify** — Check checksums in `.terraform.lock.hcl`
5. **Serve** — Start provider process and connect via gRPC

### Code Flow

```go
// Simplified resolution flow
func resolveProviders(config *configs.Config, cache *providercache.Cache) (map[string]*cachedProvider, error) {
  // 1. Discover requirements
  reqs := getproviders.DiscoverRequirements(config)

  // 2. Query registry for each provider
  for provider, versionConstraints := range reqs {
    available, _ := providercache.Query(provider, versionConstraints)
    // Select best version
  }

  // 3. Install to cache
  installer := providercache.NewInstaller(cache)
  ctx := context.Background()
  installed, err := installer.EnsureProviderVersions(ctx, reqs)

  // 4. Verify checksums
  locks := depsfile.LoadLocks(".terraform.lock.hcl")
  for _, provider := range installed {
    if !locks.ProviderIsChecksummed(provider) {
      // Prompt for trust
    }
  }
}
```

## Source Interface Hierarchy

The `getproviders.Source` interface defines the contract for provider source backends:

```go
type Source interface {
    AvailableVersions(ctx context.Context, provider addrs.Provider) (VersionList, error)
    PackageMeta(ctx context.Context, provider addrs.Provider, version Version, target Platform) (PackageMeta, error)
}
```

### Implementations

| Type | Description |
|------|-------------|
| `getproviders.RegistrySource` | Default — queries the registry API (`registry.terraform.io` or custom) |
| `getproviders.FilesystemSource` | Local filesystem provider cache |
| `getproviders.MirrorSource` | Network mirror that proxies registry packages |
| `getproviders.MultiSource` | Composite — tries multiple sources in priority order |
| `getproviders.HTTPMirrorSource` | HTTP(S)-based mirror supporting the provider mirror protocol |

Sources are composed via `MultiSource` at startup:

```go
sources := getproviders.MultiSource{
    getproviders.NewRegistrySource(...),
    getproviders.NewFilesystemSource(providerDir),
    getproviders.NewHTTPMirrorSource(mirrorURL),
}
```

## Provider Mirror Command

The `terraform providers mirror` (OpenTofu: `tofu providers mirror`) command downloads
provider packages for offline use:

```bash
# Terraform
terraform providers mirror /path/to/mirror

# OpenTofu
tofu providers mirror /path/to/mirror
```

This generates a directory structure compatible with `filesystemMirror` and produces
a `mirror.json` manifest.

## Internal Registry Package

The `internal/registry/` package implements the registry API client used by
`getproviders.RegistrySource`:

```
internal/registry/
├── client.go        # HTTP client for registry API
├── regsrc.go        # Registry source address parsing
└── response.go      # API response types
```

Registry API endpoints:
- `GET /v1/providers/-/{namespace}/{type}/versions` — List available versions
- `GET /v1/providers/-/{namespace}/{type}/{version}/download/{os}/{arch}` — Download URL + checksums

## Internal gRPC Wrapper

The `internal/grpcwrap/` package adapts the raw gRPC provider protocol (v5/v6) to
core's `providers.Interface`. Key types:

```
internal/grpcwrap/
├── provider.go      # grpcwrap.Provider — wraps *grpc.ClientConn into providers.Interface
├── provisioner.go   # grpcwrap.Provisioner — wraps provisioner gRPC
└── server.go        # gRPC server-side adapter
```

Used whenever a provider plugin is launched via `plugin.Client()`:

```go
client := plugin.NewClient(plugin.ClientConfig{
    Cmd: exec.Command(providerPath),
})
conn, _ := client.Dial()
provider := grpcwrap.NewProvider(conn)  // returns providers.Interface
```

## Version Resolution

### Constraint Matching

```go
// Pessimistic constraint: ~> 1.2 = >= 1.2, < 2.0
constraint, _ := version.NewConstraint("~> 1.2")
versions, _ := getproviders.Versions("hashicorp/aws", nil)
matching := constraint.Filter(versions)
// Returns versions 1.x where x >= 2
```

### Selection Algorithm

1. Collect all matching versions
2. Select highest non-prerelease version
3. If `version = "1.0.0"` exact, select exactly that

## Registry Protocol

### Provider Source Address

```go
// Format: hostname/namespace/type
source := addrs.MustParseProviderSourceString("registry.terraform.io/hashicorp/aws")
// hostname: registry.terraform.io
// namespace: hashicorp
// type: aws
```

### Registry API

```go
// Query available versions
versions, _ := registry.QueryVersions(context.Background(), source)

// Download provider package
url, checksums, _ := registry.PackageDownload(context.Background(), source, version, platform)
```

### Provider Mirror Protocol

```go
// Network mirror: provider's package is proxied through a mirror
type Mirror interface {
  providerURL(provider addrs.Provider, version version.Version, platform version.Platform) (*url.URL, error)
  checksumURL(provider addrs.Provider, version version.Version, platform version.Platform) (*url.URL, error)
}
```

## Provider Cache

### Cache Directory Structure

```
.terraform/providers/
└── registry.terraform.io/
    └── hashicorp/
        └── aws/
            └── 5.0.1/
                └── linux_amd64/
                    └── terraform-provider-aws_v5.0.1_x5
```

### Cache Operations

```go
// Installer interface
type Installer interface {
  InstallProvider(ctx context.Context, provider addrs.Provider, version version.Version) (*cachedProvider, error)
  GetInstalledSignature(ctx context.Context, provider addrs.Provider) (*cachedProvider, error)
}

// Cache management
func (c *Cache) Read(provider addrs.Provider, version version.Version) *CachedProvider
func (c *Cache) Register(provider addrs.Provider, path string) *CachedProvider
func (c *Cache) ProviderVersions(provider addrs.Provider) []version.Version
```

## Lock File (.terraform.lock.hcl)

```hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be overwritten.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.0.1"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc123...",
    "h1:def456...",
  ]
}
```

### Lock File Operations

```go
// Load lock file
locks := depsfile.LoadLocks(".terraform.lock.hcl")

// Provider checksum verification
if locks.ProviderIsChecksummed(provider) {
  if !locks.ProviderHasChecksum(provider, packageHash) {
    return fmt.Errorf("checksum mismatch")
  }
}
```

## OpenTofu-Specific

### OCI Registry Support

OpenTofu supports OCI registries as provider sources:

```go
// OpenTofu — OCI provider source
source := addrs.ParseProviderSourceString("oci://registry.example.com/myprovider")
// Uses internal/oci package for registry client
```

### No Terraform Cloud

OpenTofu does not include `internal/cloud/` or `internal/cloudplugin/` — these are Terraform Cloud-specific.
