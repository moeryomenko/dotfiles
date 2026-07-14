# State Management Internals

Terraform/OpenTofu state file format, serialization, locking mechanisms, and backend protocol internals.

## State File Format

### JSON Structure (0.12+, Format Version 4)

```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 42,
  "lineage": "uuid-v4",
  "outputs": {
    "vpc_id": {
      "value": "vpc-abc123",
      "type": "string",
      "sensitive": false
    }
  },
  "resources": [
    {
      "module": "root.module.child",
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"].us-east-1",
      "instances": [
        {
          "index_key": 0,
          "schema_version": 1,
          "attributes": {
            "id": "i-abc123",
            "instance_type": "t3.micro"
          },
          "private": "base64-encoded-binary",
          "dependencies": ["aws_vpc.main"]
        }
      ]
    }
  ],
  "check_results": null
}
```

### Key Fields

- `version`: State file format version (currently 4)
- `serial`: Monotonically increasing integer for change tracking and conflict detection
- `lineage`: UUID identifying the state file's lifetime. Changes when state is recreated
- `module`: Full module path (dot-separated, root = `""`)
- `mode`: `managed` (resource) or `data` (data source)
- `index_key`: For count/for_each instances — numeric index or string key
- `private`: Provider-specific binary data (schema version, sensitive attributes, metadata)
- `dependencies`: Resource addresses this instance depends on (used for destroy ordering)

### Pre-0.12 Format

Older format used `modules` array instead of `values`:

```json
{
  "version": 3,
  "modules": [
    {
      "path": ["root"],
      "resources": {
        "aws_instance.web": {
          "type": "aws_instance",
          "primary": {
            "id": "i-abc123",
            "attributes": {}
          }
        }
      }
    }
  ]
}
```

## State Operations

### State Acquisition

```bash
# Pull from remote backend
terraform state pull

# Push to remote backend (dangerous — manual override)
terraform state push <file>

# Show state in readable form
terraform show -json
```

### State Mutation Commands

| Command | Purpose | Use case |
|---------|---------|----------|
| `terraform state mv` | Rename resource address | Refactoring without recreation |
| `terraform state rm` | Remove from state | Orphan detection, removal |
| `terraform state pull/push` | Direct state manipulation | Recovery, migration |
| `terraform import` | Add existing resource | Bringing resources under management |
| `terraform state replace-provider` | Provider rename | Provider migration |

## Backend Protocol

### Backend Interface

```go
type Backend interface {
  // State management
  StateMgr(name string) (statemgr.Full, error)
  // Operation execution (only local/remote/cloud)
  Operation(context.Context, *Operation) (*State, error)
}
```

### Backend Types

| Backend | Executes operations | State storage | Locking |
|---------|-------------------|---------------|---------|
| `local` | Yes | Local file | File lock |
| `remote` | Yes | TFC/TFE | TFC API |
| `cloud` | Yes | TFC/TFE | TFC API |
| `s3` | No | S3 | DynamoDB or native lock-file (1.10+) |
| `gcs` | No | GCS | GCS object lock |
| `azurerm` | No | Azure Storage | Azure blob lease |
| `consul` | No | Consul KV | Consul session |
| `http` | No | HTTP endpoint | External |
| `pg` | No | PostgreSQL | Postgres advisory lock |
| `kubernetes` | No | Kubernetes secrets | K8s lease |
| `cos` | No | IBM Cloud COS | COS lock |
| `oss` | No | Alibaba OSS | OSS lock |

### Locking Mechanisms

| Lock type | Backend | Min version | Characteristics |
|-----------|---------|-------------|-----------------|
| DynamoDB table | S3 | All | Extra resource to manage |
| S3 native lock-file | S3 | 1.10+ | No extra resources |
| Blob lease | AzureRM | All | Automatic |
| Object lock | GCS | All | Automatic |
| Advisory lock | PostgreSQL | All | Database-level |

## State Migration

### Backend Migration

```bash
# Migrate state between backends
terraform init -migrate-state

# Force copy without confirmation
terraform init -force-copy -migrate-state
```

### Resource Refactoring

```hcl
# moved block — rename without recreation (1.1+)
moved {
  from = aws_instance.web_old
  to   = aws_instance.web
}
```

### Resource Removal

```hcl
# removed block — intentionally destroy and remove from state (1.7+)
removed {
  from = aws_instance.deprecated

  lifecycle {
    destroy = true  # false to orphan
  }
}
```

## State Security

### State File Contains

- All resource attribute values (including secrets)
- Provider configuration values
- Module output values
- Resource dependency graph

### Hardening Practices

- Enable state file encryption at rest (S3 SSE, GCS encryption, Azure encryption)
- Restrict state file access with IAM
- Use DynamoDB (or native lock-file) for locking — prevents concurrent writes
- Enable state versioning for rollback
- Cross-region replication for DR
- Use `write_only` arguments (1.11+) to keep secrets out of state
- Audit state access via CloudTrail/Azure Monitor/GCP Audit Logs
