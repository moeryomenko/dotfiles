# Golden Image Patterns for QEMU/KVM

Practical guide to building golden VM images with Packer's QEMU builder. All examples target the `qemu` source with `accelerator = "kvm"`.

---

## 1. Golden Image Strategy for QEMU/KVM

A **golden image** is a pre-hardened, pre-configured VM disk image used as a repeatable base for deploying virtual machines. In the QEMU/KVM context, this is typically a qcow2 file containing the root filesystem with all desired packages, users, security settings, and cleanup applied.

### Immutable Infrastructure Principle

Golden images embody the immutable infrastructure pattern: you never patch a running VM configuration — you rebuild the image, redeploy, and discard the old instance. This eliminates configuration drift and ensures every deployment starts from a known-good state.

### Base Images vs. Derived Images

| Concept | Description | QEMU Mechanism |
|---|---|---|
| **Base image** | A sealed golden image from a build pipeline. Read-only, never modified after creation. | `output_directory` artifact |
| **Derived image** | A clone that inherits the base while recording only its own changes. | `use_backing_file` with backing file pointing to base |

Derived images use QEMU's qcow2 backing file feature: a thin overlay that stores only blocks written since the base. This drastically reduces disk usage when many VMs share the same base.

### QEMU Disk Image Formats

| Format | Use Case | Notes |
|---|---|---|
| `qcow2` | Default for golden images. Supports compression, snapshots, backing files. | `format = "qcow2"` (default) |
| `raw` | Maximum performance, no features. Not recommended for golden image workflows. | `format = "raw"` — disables compaction and compression |

Packer uses qcow2 by default. The `disk_compression` option applies qcow2 compression during the final `qemu-img convert` step.

### ISO Installation vs. Disk Image Boot

Two distinct boot modes for the QEMU builder:

**ISO installation** (`disk_image = false`, the default):
- Boots from an ISO installer and runs through an automated installation (preseed, kickstart, autoinstall).
- Requires `iso_url`, `iso_checksum`, and a `boot_command` to navigate the installer.
- Produces a fresh disk image from scratch.
- Preferred for golden images because it produces a clean, reproducible OS install.

**Disk image boot** (`disk_image = true`):
- Boots an existing disk image directly (e.g., a cloud image or pre-installed OS).
- Useful for customizing an existing base without reinstalling.
- The source at `iso_url` is a bootable disk image, not an installer ISO.
- Can use `use_backing_file` to create a thin overlay on the source.

```hcl
# ISO installation (default) — clean golden image build
source "qemu" "ubuntu-golden" {
  iso_url          = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
  iso_checksum     = "sha256:..."
  boot_command     = ["<wait>e<wait><down><down><end><wait> autoinstall ds=nocloud;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ <f10>"]
  boot_wait        = "5s"
  disk_image       = false   # default — build from ISO
  format           = "qcow2"
  disk_size        = "40G"
  accelerator      = "kvm"
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "30m"
}

# Disk image boot — customize an existing cloud image
source "qemu" "customize-cloud" {
  iso_url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  iso_checksum     = "sha256:..."
  disk_image       = true
  use_backing_file = true
  format           = "qcow2"
  disk_size        = "40G"
  accelerator      = "kvm"
  ssh_username     = "ubuntu"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  ssh_timeout      = "30m"
}
```

---

## 2. Provisioner Orchestration for QEMU

All provisioning targets the QEMU guest over SSH. Packer's QEMU builder sets up user-mode networking with automatic port forwarding (host port `{{ .SSHHostPort }}` to guest port 22).

### SSH Configuration

The QEMU builder connects to the guest via SSH. Configure credentials in the source block:

```hcl
source "qemu" "hardened-image" {
  # ...
  ssh_username       = "packer"          # user created during install or pre-existing
  ssh_password       = "packer"          # temporary password, changed during provisioning
  # Or use key-based auth:
  ssh_private_key_file = "~/.ssh/packer"
  ssh_timeout        = "30m"             # how long to wait for SSH to become available
  ssh_handshake_attempts = 100           # retry on slow-booting VMs
  ssh_clear_authorized_keys = true       # remove Packer's key before sealing
}
```

### OS Package Update Patterns

Apply updates early in provisioning so all follow-on steps work against the latest packages.

```hcl
# Debian / Ubuntu
build {
  sources = ["source.qemu.hardened-image"]

  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "apt-get upgrade -y -qq",
      "apt-get dist-upgrade -y -qq",
    ]
  }
}
```

```hcl
# RHEL / Rocky / Alma / CentOS
build {
  sources = ["source.qemu.hardened-image"]

  provisioner "shell" {
    inline = [
      "yum update -y -q",
      "yum install -y -q epel-release",
    ]
  }
}
```

```hcl
# Alpine Linux
build {
  sources = ["source.qemu.hardened-image"]

  provisioner "shell" {
    inline = [
      "apk update",
      "apk upgrade",
    ]
  }
}
```

### User Creation and SSH Key Injection

Create a non-root administrative user for post-build access. Remove the temporary Packer user if desired.

```hcl
provisioner "shell" {
  inline = [
    # Create admin user
    "useradd -m -s /bin/bash -G sudo admin",
    "mkdir -p /home/admin/.ssh",
    "chmod 700 /home/admin/.ssh",
    # Inject public key for SSH access
    "echo 'ssh-ed25519 AAAAC3...' > /home/admin/.ssh/authorized_keys",
    "chmod 600 /home/admin/.ssh/authorized_keys",
    "chown -R admin:admin /home/admin/.ssh",
    # Optionally remove the temporary Packer user
    # "userdel -r packer",
  ]
}
```

### Security Hardening

Apply hardening steps after package updates and before cleanup.

#### CIS Kernel Parameters via sysctl

```hcl
provisioner "shell" {
  inline = [
    "cat >> /etc/sysctl.d/99-hardening.conf << 'EOF'",
    "# IP forwarding — disable unless acting as router",
    "net.ipv4.ip_forward = 0",
    "net.ipv6.conf.all.forwarding = 0",
    "# Source routing — disable",
    "net.ipv4.conf.all.accept_source_route = 0",
    "net.ipv6.conf.all.accept_source_route = 0",
    "# ICMP redirects — disable",
    "net.ipv4.conf.all.accept_redirects = 0",
    "net.ipv6.conf.all.accept_redirects = 0",
    "net.ipv4.conf.all.secure_redirects = 0",
    "# SYN flood protection",
    "net.ipv4.tcp_syncookies = 1",
    "net.ipv4.tcp_syn_retries = 2",
    "# Kernel panic on OOM",
    "vm.panic_on_oom = 1",
    "kernel.panic = 10",
    "EOF",
    "sysctl --system",
  ]
}
```

#### SSH Daemon Hardening

```hcl
provisioner "shell" {
  inline = [
    "sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config",
    "sed -i 's/^#\\?ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config",
    # Restart sshd to apply changes
    "systemctl restart sshd || service sshd restart || service ssh restart",
  ]
}
```

#### Firewall Rules (iptables/nftables)

```hcl
provisioner "shell" {
  inline = [
    # iptables default deny with SSH exception
    "iptables -P INPUT DROP",
    "iptables -P FORWARD DROP",
    "iptables -P OUTPUT ACCEPT",
    "iptables -A INPUT -i lo -j ACCEPT",
    "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 22 -j ACCEPT",
    # Save rules
    "iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/sysconfig/iptables 2>/dev/null || true",
  ]
}

# For Alpine using iptables or nftables:
provisioner "shell" {
  only = ["qemu.alpine-image"]
  inline = [
    "apk add iptables",
    "iptables -P INPUT DROP",
    "iptables -A INPUT -i lo -j ACCEPT",
    "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 22 -j ACCEPT",
    "rc-service iptables save",
  ]
}
```

#### Remove Unnecessary Packages

Strip the image of packages not needed at runtime. This reduces image size and attack surface.

```hcl
provisioner "shell" {
  inline = [
    # Debian/Ubuntu
    "apt-get purge -y -qq snapd lxd lxc cloud-init nano 2>/dev/null || true",
    # RHEL
    "yum remove -y -q cloud-init nano 2>/dev/null || true",
    # Alpine
    "apk del nano vim 2>/dev/null || true",
  ]
}
```

### Cleanup Before Shutdown

These steps must run **last**, immediately before shutdown. They erase unique identifiers, cached data, and transient files so every clone of the image starts fresh.

```hcl
provisioner "shell" {
  inline = [
    # Package manager caches
    "apt-get clean -qq 2>/dev/null || true",
    "yum clean all -q 2>/dev/null || true",
    "rm -rf /var/cache/apt/* /var/cache/yum/* /var/lib/apt/lists/* 2>/dev/null || true",

    # Temporary files
    "rm -rf /tmp/* /var/tmp/*",

    # Machine ID — systemd will regenerate on next boot
    "rm -f /etc/machine-id /var/lib/dbus/machine-id",
    "touch /etc/machine-id",

    # Audit logs and shell history
    "rm -f ~packer/.bash_history ~root/.bash_history",
    "rm -f /var/log/auth.log /var/log/syslog /var/log/messages 2>/dev/null || true",
    "truncate -s 0 /var/log/wtmp 2>/dev/null || true",
    "truncate -s 0 /var/log/lastlog 2>/dev/null || true",

    # SSH host keys — regenerated on first boot
    "rm -f /etc/ssh/ssh_host_*",
  ]
}
```

### Zero Free Disk Space

Writing zeroes to all free space lets qcow2's sparse storage reclaim those blocks. The final `qemu-img convert` step (triggered by Packer) will not write zero-filled regions, producing a smaller image.

```hcl
provisioner "shell" {
  inline = [
    # Fill free space with zeroes, then remove the file
    "dd if=/dev/zero of=/zero bs=1M || true",
    "rm -f /zero",
  ]
}
```

This step increases build time (I/O-bound) but typically reduces final image size by 20-50%.

### QEMU Guest Agent

Install and enable `qemu-guest-agent` for better VM integration (graceful shutdown, network info, file system freeze).

```hcl
# Debian / Ubuntu
provisioner "shell" {
  inline = [
    "apt-get install -y -qq qemu-guest-agent",
    "systemctl enable qemu-guest-agent",
  ]
}

# RHEL / Rocky / Alma
provisioner "shell" {
  inline = [
    "yum install -y -q qemu-guest-agent",
    "systemctl enable qemu-guest-agent",
  ]
}

# Alpine
provisioner "shell" {
  inline = [
    "apk add qemu-guest-agent",
    "rc-update add qemu-guest-agent default",
  ]
}
```

### Complete Provisioning Orchestration Example

```hcl
build {
  sources = ["source.qemu.hardened-image"]

  # 1. Package updates (early)
  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "apt-get upgrade -y -qq",
      "apt-get dist-upgrade -y -qq",
    ]
  }

  # 2. Security hardening
  provisioner "shell" {
    script = "scripts/harden-sysctl.sh"
  }
  provisioner "shell" {
    script = "scripts/harden-sshd.sh"
  }

  # 3. QEMU guest agent
  provisioner "shell" {
    inline = [
      "apt-get install -y -qq qemu-guest-agent",
      "systemctl enable qemu-guest-agent",
    ]
  }

  # 4. Cleanup before sealing (last shell provisioner)
  provisioner "shell" {
    script = "scripts/cleanup-seal.sh"
  }

  # 5. Zero free space (final I/O step)
  provisioner "shell" {
    inline = [
      "dd if=/dev/zero of=/zero bs=1M || true",
      "rm -f /zero",
    ]
  }
}
```

---

## 3. Ansible with QEMU

Use the `ansible-local` provisioner to run Ansible playbooks inside the VM. This avoids the overhead of a separate Ansible control machine.

### ansible-local Pattern

The `ansible-local` provisioner copies a playbook directory into the VM and runs `ansible-playbook` locally. No inventory management needed — the target is always localhost.

```hcl
build {
  sources = ["source.qemu.ubuntu-golden"]

  # Install Ansible in the VM before running ansible-local
  provisioner "shell" {
    inline = [
      "apt-get install -y -qq ansible",
    ]
  }

  # Run the playbook locally inside the VM
  provisioner "ansible-local" {
    playbook_dir   = "provisioning/playbooks"
    playbook_file  = "provisioning/playbooks/golden.yml"
    role_paths     = [
      "provisioning/roles/common",
      "provisioning/roles/hardening",
    ]
    extra_arguments = [
      "--extra-vars", "distro_family=debian",
    ]
  }
}
```

### Sample Playbook Structure for Image Baking

```
provisioning/
  playbooks/
    golden.yml
    derived.yml
  roles/
    common/
      tasks/
        main.yml
      handlers/
        main.yml
    hardening/
      tasks/
        main.yml
    cleanup/
      tasks/
        main.yml
```

**`provisioning/playbooks/golden.yml`:**

```yaml
---
- hosts: all
  gather_facts: yes
  vars:
    distro_family: "{{ ansible_os_family | lower }}"
    admin_user: "admin"
  roles:
    - common
    - hardening
    - cleanup
  post_tasks:
    - name: Zero free space for better qcow2 compression
      shell: dd if=/dev/zero of=/zero bs=1M || true && rm -f /zero
      changed_when: false
```

### Galaxy Role Installation

Install Ansible Galaxy roles in a shell provisioner before the `ansible-local` step.

```hcl
# Install Galaxy roles into the local roles path on the build host,
# then the ansible-local provisioner will transfer them to the VM.
provisioner "shell-local" {
  inline = [
    "ansible-galaxy install -r provisioning/requirements.yml --force",
  ]
}

provisioner "ansible-local" {
  playbook_dir   = "provisioning/playbooks"
  playbook_file  = "provisioning/playbooks/golden.yml"
  galaxy_file    = "provisioning/requirements.yml"  # auto-installs inside VM
}
```

**`provisioning/requirements.yml`:**

```yaml
---
roles:
  - name: devsec.hardening
  - name: geerlingguy.docker
```

---

## 4. Multi-Distribution Builds

The same QEMU template can build images for multiple Linux distributions by using variables to select the ISO, preseed/kickstart/autoinstall file, and package manager commands.

### Variable-Based Distribution Selection

```hcl
variable "distro" {
  type    = string
  default = "ubuntu"
}

variable "distro_family" {
  type    = string
  default = "debian"
}

variable "os_package_manager" {
  type    = string
  default = "apt"
}

locals {
  iso_urls = {
    ubuntu = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
    debian = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"
    rocky  = "https://dl.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-x86_64-minimal.iso"
    alpine = "https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-standard-3.20.3-x86_64.iso"
  }

  preseed_paths = {
    ubuntu = "http/ubuntu-autoinstall.yaml"
    debian = "http/debian-preseed.cfg"
    rocky  = "http/rocky-kickstart.ks"
    alpine = "http/alpine-answerfile"
  }
}

source "qemu" "golden" {
  iso_url          = local.iso_urls[var.distro]
  iso_checksum     = var.distro == "ubuntu" ? "sha256:..." : "..."
  disk_image       = false
  format           = "qcow2"
  disk_size        = "40960M"
  accelerator      = "kvm"
  ssh_username     = "packer"
  ssh_password     = "packer"
  ssh_timeout      = "30m"

  # Per-distribution boot commands
  boot_command     = var.distro == "ubuntu" ? [
    "<wait>e<wait><down><down><end><wait> autoinstall ds=nocloud;...",
  ] : var.distro == "debian" ? [
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debian-preseed.cfg<wait>",
  ] : []
  boot_wait        = "5s"
}
```

### Conditional Provisioning via Variables

```hcl
build {
  sources = ["source.qemu.golden"]

  # Install qemu-guest-agent — command varies by distro
  provisioner "shell" {
    environment_vars = [
      "DISTRO_FAMILY=${var.distro_family}",
    ]
    inline = [
      "case $DISTRO_FAMILY in",
      "  debian)",
      "    apt-get install -y -qq qemu-guest-agent",
      "    ;;",
      "  redhat)",
      "    yum install -y -q qemu-guest-agent",
      "    ;;",
      "  alpine)",
      "    apk add qemu-guest-agent",
      "    ;;",
      "esac",
    ]
  }

  # Package update — uses variable for command
  provisioner "shell" {
    environment_vars = [
      "PKG_MGR=${var.os_package_manager}",
    ]
    inline = [
      "case $PKG_MGR in",
      "  apt)",
      "    apt-get update -qq && apt-get upgrade -y -qq",
      "    ;;",
      "  yum)",
      "    yum update -y -q",
      "    ;;",
      "  apk)",
      "    apk update && apk upgrade",
      "    ;;",
      "esac",
    ]
  }
}
```

### Multi-Distribution Build Block

Build all distributions in a single template using `build` with multiple sources:

```hcl
source "qemu" "ubuntu" {
  # ... ubuntu-specific config ...
  boot_command = ["...ubuntu autoinstall..."]
}

source "qemu" "rocky" {
  # ... rocky-specific config ...
  boot_command = ["...rocky kickstart..."]
}

source "qemu" "alpine" {
  # ... alpine-specific config ...
  boot_command = ["...alpine answerfile..."]
}

build {
  sources = [
    "source.qemu.ubuntu",
    "source.qemu.rocky",
    "source.qemu.alpine",
  ]

  # Shared provisioning — use variables to branch
  provisioner "shell" {
    environment_vars = ["PKG_MGR=apt"]
    only             = ["qemu.ubuntu"]
    inline           = ["apt-get update -qq && apt-get upgrade -y -qq"]
  }

  provisioner "shell" {
    environment_vars = ["PKG_MGR=yum"]
    only             = ["qemu.rocky"]
    inline           = ["yum update -y -q"]
  }

  provisioner "shell" {
    environment_vars = ["PKG_MGR=apk"]
    only             = ["qemu.alpine"]
    inline           = ["apk update && apk upgrade"]
  }

  # Shared hardening roles (same Ansible for everyone)
  provisioner "ansible-local" {
    playbook_file  = "provisioning/golden.yml"
    extra_arguments = ["--extra-vars", "distro_family=${var.distro_family}"]
  }
}
```

---

## 5. Disk Optimization for QEMU

These options control how QEMU's disk image is created and finalized. All fields map directly to fields in the QEMU builder config.

### qcow2 Compression

```hcl
source "qemu" "optimized" {
  format            = "qcow2"
  disk_compression  = true   # apply qcow2 compression via qemu-img convert
  skip_compaction   = false  # do not skip the convert step (default)
  skip_resize_disk  = false  # allow automatic resize (default)
}
```

- `disk_compression = true`: passes `-c` to `qemu-img convert`, compressing the output qcow2. Effective after zero-fill cleanup in the guest, since zero blocks compress well.
- `skip_compaction = true`: skips the final `qemu-img convert` entirely. The image is used as-is from the VM's working directory. Incompatible with `use_backing_file` (which forces `skip_compaction` to `true` automatically).
- `skip_resize_disk = true`: skips `qemu-img resize`. Only usable when `disk_image = true` (booting an existing image). Useful when the source image is already the correct size.

### Disk Interface

```hcl
source "qemu" "optimized" {
  disk_interface = "virtio-scsi"  # recommended for performance
}
```

| Interface | Notes |
|---|---|
| `virtio` | Default. Paravirtualized, good performance, widely compatible. |
| `virtio-scsi` | Recommended. Better I/O performance, supports more devices, SCSI pass-through. Preferred for production golden images. |
| `ide` | Legacy. Use only for very old guest OS compatibility. |
| `sata` | Emulated SATA. Higher CPU overhead. |
| `scsi` | Disabled on Red Hat builds due to a known bug (RHEL/CentOS forbid this). |

### Disk Size Planning

```hcl
source "qemu" "optimized" {
  disk_size            = "40960M"   # 40 GB — Packer default
  disk_additional_size = ["100G"]   # extra data disk
}
```

- `disk_size`: defaults to `40960M` (40 GB). Without a unit suffix, Packer appends `M` (megabytes).
- `disk_additional_size`: creates extra disks appended to `vm_name` as `-1`, `-2`, etc.
- Right-size for the image content: a minimal Ubuntu server with no GUI might need only 8-16 GB; a full desktop or build server may need 40-80 GB.

### Derived Images with `use_backing_file`

For space-efficient cloning from a base golden image:

```hcl
# Build the base golden image
source "qemu" "ubuntu-base" {
  iso_url          = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
  iso_checksum     = "sha256:..."
  disk_image       = false
  format           = "qcow2"
  disk_size        = "40960M"
  accelerator      = "kvm"
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "30m"
}

# Derive from the base using backing file
source "qemu" "ubuntu-derived" {
  iso_url          = "./output-ubuntu-base/packer-ubuntu-base.qcow2"
  iso_checksum     = "none"
  disk_image       = true             # boot an existing disk
  use_backing_file = true             # create thin overlay
  format           = "qcow2"          # backing file requires qcow2
  accelerator      = "kvm"
  ssh_username     = "ubuntu"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  ssh_timeout      = "30m"

  # No disk_size needed — inherits from backing file
}
```

When `use_backing_file = true`:
- Packer creates a new qcow2 overlay that records only blocks differing from the base.
- `skip_compaction` is forced to `true` automatically (the overlay would be useless after conversion).
- The base image must remain at the original path for the overlay to work.
- Space savings are proportional to how much the overlay changes: a Docker host with 2 GB of overlay changes on a 40 GB base uses only 2 GB per derived image.

---

## 6. Image Testing

Validate the produced image before promoting it for use.

### Post-Build Validation with `shell-local`

The `shell-local` post-processor runs a script on the build host after the artifact is created.

```hcl
build {
  sources = ["source.qemu.ubuntu-golden"]

  post-processor "shell-local" {
    inline = [
      "echo '=== Image artifact ==='",
      "ls -lh ${artifact}",
      "qemu-img info ${artifact}",
    ]
  }
}
```

### QEMU Image Inspection

Inspect image metadata directly with `qemu-img`:

```bash
qemu-img info output-ubuntu-golden/packer-ubuntu-golden.qcow2
```

Example output:

```
image: packer-ubuntu-golden.qcow2
file format: qcow2
virtual size: 40 GiB (42949672960 bytes)
disk size: 1.8 GiB               # actual on-disk size (sparse)
cluster_size: 65536
Format specific information:
    compat: 1.1
    compression type: zlib      # set when disk_compression = true
    lazy refcounts: true
    refcount bits: 16
    corrupt: false
```

The `disk size` line reveals the true storage footprint. After zero-fill cleanup and compression, a 40 GB virtual image typically occupies 1-3 GB on disk.

### Boot Testing the Resulting Image

Launch a test QEMU instance from the golden image outside Packer to confirm it boots and SSH works:

```bash
#!/usr/bin/env bash
# test-boot.sh — smoke-test a golden qcow2 image
# Usage: test-boot.sh output-ubuntu-golden/packer-ubuntu-golden.qcow2

IMAGE="${1:?usage: $0 <qcow2-image>}"
SSH_PORT=2222

qemu-system-x86_64 \
  -machine type=q35,accel=kvm \
  -m 2048 \
  -smp 2 \
  -drive file="${IMAGE}",format=qcow2,if=virtio \
  -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
  -device virtio-net,netdev=net0 \
  -nographic \
  -display none \
  -daemonize

echo "Booting image ${IMAGE}..."
echo "SSH available at localhost:${SSH_PORT}"

# Wait for SSH and run a smoke check
for i in $(seq 1 30); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 \
         -p ${SSH_PORT} admin@localhost 'uname -a && id' 2>/dev/null; then
    echo "SMOKE TEST PASSED"
    exit 0
  fi
  sleep 2
done

echo "SMOKE TEST FAILED — could not connect within 60s"
exit 1
```

### Full Build-and-Test Pipeline (shell-local)

```hcl
build {
  sources = ["source.qemu.ubuntu-golden"]

  # Provisioning steps here...

  post-processor "shell-local" {
    environment_vars = [
      "IMAGE_PATH=${build.Sources[0].Type}.${build.Sources[0].Name}",
    ]
    inline = [
      "ARTIFACT=$(ls -t output-*/packer-*.qcow2 | head -1)",
      "echo 'Verifying artifact: '${ARTIFACT}",
      "qemu-img info ${ARTIFACT}",
      "test-boot.sh ${ARTIFACT}",
    ]
  }
}
```

---

## Appendix A: Complete Golden Image Template

A standalone golden image template combining all patterns above:

```hcl
# variables.pkr.hcl
variable "distro" {
  type    = string
  default = "ubuntu"
}

variable "distro_family" {
  type    = string
  default = "debian"
}

variable "os_package_manager" {
  type    = string
  default = "apt"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

# sources/qemu.pkr.hcl
locals {
  iso_map = {
    ubuntu = {
      url      = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
      checksum = "sha256:..."
    }
  }
}

source "qemu" "golden" {
  # ISO installation
  iso_url          = local.iso_map[var.distro].url
  iso_checksum     = local.iso_map[var.distro].checksum
  disk_image       = false

  # Disk
  format           = "qcow2"
  disk_size        = "40960M"
  disk_interface   = "virtio-scsi"
  disk_compression = true
  disk_cache       = "writeback"
  disk_discard     = "unmap"

  # Hardware
  accelerator      = "kvm"
  machine_type     = "q35"
  cpus             = 2
  memory           = 2048
  net_device       = "virtio-net"

  # SSH
  ssh_username     = "packer"
  ssh_password     = "packer"
  ssh_timeout      = "30m"
  ssh_clear_authorized_keys = true

  # Boot automation
  boot_wait        = "5s"
  boot_command     = ["..."]
}

# builds/golden.pkr.hcl
build {
  sources = ["source.qemu.golden"]

  provisioner "shell" {
    environment_vars = ["PKG_MGR=${var.os_package_manager}"]
    inline = [
      "apt-get update -qq",
      "apt-get upgrade -y -qq",
      "apt-get install -y -qq qemu-guest-agent",
      "systemctl enable qemu-guest-agent",
    ]
  }

  provisioner "ansible-local" {
    playbook_file  = "provisioning/golden.yml"
    extra_arguments = [
      "--extra-vars", "distro_family=${var.distro_family}",
    ]
  }

  # Cleanup and seal
  provisioner "shell" {
    script = "scripts/cleanup-seal.sh"
  }

  provisioner "shell" {
    inline = [
      "dd if=/dev/zero of=/zero bs=1M || true",
      "rm -f /zero",
    ]
  }

  # Test
  post-processor "shell-local" {
    inline = [
      "ARTIFACT=$(ls -t output-*/packer-*.qcow2 | head -1)",
      "echo 'Golden image: '${ARTIFACT}",
      "qemu-img info ${ARTIFACT}",
    ]
  }
}
```

## Appendix B: Key QEMU Builder Fields Reference

| HCL Field | Type | Default | Description |
|---|---|---|---|
| `accelerator` | string | `kvm` (or `tcg`) | `kvm`, `tcg`, `none` |
| `format` | string | `qcow2` | `qcow2` or `raw` |
| `disk_size` | string | `40960M` | Virtual disk size |
| `disk_interface` | string | `virtio` | `virtio`, `virtio-scsi`, `ide`, `sata` |
| `disk_cache` | string | `writeback` | Cache mode for disk |
| `disk_discard` | string | `ignore` | `unmap` or `ignore` |
| `disk_compression` | bool | `false` | Apply qcow2 compression |
| `skip_compaction` | bool | `false` | Skip qemu-img convert |
| `skip_resize_disk` | bool | `false` | Skip resize (requires `disk_image`) |
| `disk_image` | bool | `false` | Boot existing disk instead of ISO |
| `use_backing_file` | bool | `false` | Create qcow2 overlay on source |
| `disk_additional_size` | list(string) | `[]` | Extra data disks |
| `machine_type` | string | `pc` | QEMU machine type (`pc`, `q35`) |
| `headless` | bool | `false` | Run without GUI console |
| `net_device` | string | `virtio-net` | Network driver |
| `qemu_binary` | string | `qemu-system-x86_64` | QEMU binary path |
| `cpu_model` | string | `""` | CPU model (e.g., `host`) |
| `vm_name` | string | `packer-{BUILDNAME}` | Output image filename |

All defaults from `builder/qemu/config.go` unless otherwise noted. Use `cpus`, `sockets`, `cores`, `threads` for SMP topology and `memory` for RAM in MB.
