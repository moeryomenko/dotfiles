# Network Transport

Connection dialer options for connecting to libvirt daemons.

## URI Parsing

```
qemu[+transport]://[user@]hostname[:port]/[path][?extraoptions]

Examples:
qemu:///system                                  # Local socket (system)
qemu:///session                                 # Local socket (session)
qemu+ssh://user@host/system                     # SSH tunnel
qemu+sshcmd://user@host:2222/system             # Native SSH with port
qemu+tcp://host:16509/system                    # TCP
qemu+tls://host:16514/system                    # TLS
```

## Dialer Interface

Dialer implementations follow a common interface:

```go
// Dialer abstracts connection creation across transport types.
type Dialer interface {
    // Connect establishes a libvirt connection from a parsed URI.
    Connect(uri *url.URL) (*go-libvirt.Libvirt, error)
    // Scheme returns the transport scheme this dialer handles (e.g., "ssh", "tls").
    Scheme() string
}
```

## Factory Pattern

A `NewDialerFromURI` factory selects the appropriate dialer based on the URI scheme:

```go
func NewDialerFromURI(uri *url.URL) (Dialer, error) {
    switch uri.Scheme {
    case "qemu":
        return &LocalDialer{}, nil
    case "qemu+tcp":
        return &TCPDialer{}, nil
    case "qemu+tls":
        return &TLSDialer{}, nil
    case "qemu+ssh":
        return &SSHDialer{}, nil
    case "qemu+sshcmd":
        return &SSHCmdDialer{}, nil
    default:
        return nil, fmt.Errorf("unsupported transport: %s", uri.Scheme)
    }
}
```

### SSH Authentication Query Parameters

When using SSH transports (`qemu+ssh`, `qemu+sshcmd`), authentication is configured via URI query parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `keyfile` | Path to SSH private key | `?keyfile=~/.ssh/id_libvirt` |
| `known_hosts` | Path to known_hosts file | `?known_hosts=~/.ssh/known_hosts` |
| `password` | Password for keyboard-interactive auth | `?password=secret` (avoid in command history) |
| `no_verify` | Skip host key verification | `?no_verify=1` (testing only, discouraged) |
| `sshauth` | Auth method: `agent`, `key`, `password`, `key+password` | `?sshauth=agent` (default: agent then key) |

## Dialer Implementations

### Local (Unix Socket)

```go
// Default connection method
// Paths:
//   system:  /var/run/libvirt/libvirt-sock
//   session: /run/user/$UID/libvirt/libvirt-sock

import "github.com/digitalocean/go-libvirt"

conn, err := libvirt.Connect("qemu:///system")
```

### Go SSH

```go
// Pure Go SSH client (crypto/ssh)
// Supports:
// - Key-based auth
// - Password auth
// - known_hosts verification
// - Key exchange algorithms

import (
  "golang.org/x/crypto/ssh"
  "github.com/digitalocean/go-libvirt"
)

conn, err := libvirt.Connect("qemu+ssh://user@host/system")
```

### SSH Cmd (Native SSH)

```go
// Uses native ssh CLI binary
// Respects ~/.ssh/config settings (Host, ProxyJump, etc.)
// Three proxy modes:

type ProxyMode int
const (
  ModeAuto    ProxyMode = iota // Try virt-ssh-helper, fallback to netcat
  ModeNative                   // virt-ssh-helper only
  ModeNetcat                   // Direct netcat through SSH
)

// Config:
// - ssh_port (default: 22)
// - ssh_key (custom key path)
// - known_hosts verification
// - no_verify flag
```

### TCP

```go
// Plain TCP connection
// Port: 16509 (default for libvirt TCP)
// No encryption or authentication (use with caution)
conn, err := libvirt.Connect("qemu+tcp://host:16509/system")
```

### TLS

```go
// TLS-encrypted connection with PKI
// Port: 16514 (default for libvirt TLS)
// Options:
// - pki_path (path to CA/cert/key files)
// - no_verify (skip certificate verification, discouraged)

conn, err := libvirt.Connect("qemu+tls://host:16514/system")
```

## Connection Security

| Transport | Encryption | Authentication | Use case |
|-----------|-----------|---------------|----------|
| Local socket | None (filesystem) | Unix user | Local development |
| Go SSH | SSH channel | SSH key | Remote management |
| SSH Cmd | SSH channel | SSH key + agent | Complex SSH configs |
| TCP | None | Optional SASL | Internal network |
| TLS | TLS | X.509 certs | Production remote |

## Testing Connections

```bash
# Test connection with virsh
virsh -c qemu:///system list --all
virsh -c qemu+ssh://user@host/system list --all

# Verify connectivity before running provider
LIBVIRT_TEST_URI=qemu:///system make testacc
```
