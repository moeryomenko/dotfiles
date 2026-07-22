# Boot and Automation (QEMU/KVM)

Automated OS installation patterns for the Packer QEMU builder. This document covers boot command keyboard automation via VNC, boot timing, HTTP serving, floppy/CDROM injection, and distribution-specific automated install methods.

QEMU-specific field names and defaults are sourced from `builder/qemu/config.go` and `github.com/hashicorp/packer-plugin-sdk/bootcommand`.

---

## 1. QEMU VNC Boot Command Syntax

The QEMU builder "types" the boot command character-by-character over VNC into the virtual machine. Each keystroke is sent as a separate key-down/key-up event with a default 100 ms delay between events.

All special keys are enclosed in angle brackets: `<keyname>`.

### Timing

| Special Key | Effect |
|---|---|
| `<wait>` | Pause 1 second |
| `<wait5>` | Pause 5 seconds |
| `<wait10>` | Pause 10 seconds |
| `<waitXX>` | Pause arbitrary duration. `XX` is a Go duration string: `300ms`, `1.5h`, `2h45m`, `1m20s` |

### Navigation

| Special Key | RFB Keysym |
|---|---|
| `<enter>` / `<return>` | 0xFF0D |
| `<tab>` | 0xFF09 |
| `<spacebar>` | 0x0020 |
| `<bs>` | 0xFF08 |
| `<del>` | 0xFFFF |
| `<esc>` | 0xFF1B |

### Function Keys

| Special Key | RFB Keysym |
|---|---|
| `<f1>` ... `<f12>` | 0xFFBE ... 0xFFC9 |

### Modifier Keys

| Special Key | RFB Keysym |
|---|---|
| `<leftAlt>` | 0xFFE9 |
| `<rightAlt>` | 0xFFEA |
| `<leftCtrl>` | 0xFFE3 |
| `<rightCtrl>` | 0xFFE4 |
| `<leftShift>` | 0xFFE1 |
| `<rightShift>` | 0xFFE2 |
| `<leftSuper>` | 0xFFEB |
| `<rightSuper>` | 0xFFEC |

macOS (verified against built-in VNC server):

| Special Key | RFB Keysym |
|---|---|
| `<leftCommand>` | 0xFFE9 |
| `<rightCommand>` | 0xFFEA |
| `<leftOption>` | 0xFFE7 |
| `<rightOption>` | 0xFFE8 |

### Arrow Keys

| Special Key | RFB Keysym |
|---|---|
| `<up>` | 0xFF52 |
| `<down>` | 0xFF54 |
| `<left>` | 0xFF51 |
| `<right>` | 0xFF53 |

### Editing and Navigation Keys

| Special Key | RFB Keysym |
|---|---|
| `<home>` | 0xFF50 |
| `<end>` | 0xFF57 |
| `<pageUp>` | 0xFF55 |
| `<pageDown>` | 0xFF56 |
| `<insert>` | 0xFF63 |
| `<menu>` | 0xFF67 |

### Hold/Release Modifiers

Any printable character or special key (except `<wait>` types) can be toggled on or off:

- `<leftCtrlOn>c<leftCtrlOff>` — sends Ctrl+C (hold left Ctrl, press c, release left Ctrl)
- `<cOn>hello<cOff>` — holds the `c` key down while typing "hello", then releases
- `<leftShiftOn>HELLO<leftShiftOff>` — shifts for uppercase without toggle

**Important**: Released keys stay released. Held keys stay held until explicitly released or the VM reboots.

### Custom Key Intervals

Two timing controls for slow guests:

- `boot_key_interval` — per-keypress delay in milliseconds. Default: `100ms` (from `PACKER_KEY_INTERVAL` env var or builder default).
- `boot_keygroup_interval` — delay between groups of key presses. Format: duration string like `"5s"`, `"500ms"`.

```hcl
source "qemu" "slow-guest" {
  boot_key_interval       = "200ms"
  boot_keygroup_interval  = "3s"
  # ...
}
```

The `PACKER_KEY_INTERVAL` environment variable overrides the per-key delay globally:

```shell
PACKER_KEY_INTERVAL=50ms packer build template.pkr.hcl
```

---

## 2. Boot Timing Configuration

### boot_wait

Wait before typing the boot command to give the VM firmware time to initialize.

```hcl
source "qemu" "example" {
  boot_wait = "10s"   # default
}
```

- Default: `10s` (from SDK `BootConfig.Prepare()`)
- Set to `"-1s"` for zero wait
- Increase for slow firmware (UEFI, verbose BIOS) or large ISO loading
- Decrease for fast-booting ISOs (lightweight distros, custom images)

### Template Variables in boot_command

Available for interpolation in boot commands:

| Variable | Description | Example Value |
|---|---|---|
| `{{ .HTTPIP }}` | IP of the Packer HTTP server | `10.0.2.2` (user networking) or bridge IP |
| `{{ .HTTPPort }}` | Port of the Packer HTTP server | `8999` |
| `{{ .Name }}` | VM name from config | `packer-example` |
| `{{ .SSHPublicKey }}` | SSH public key for temporary key-based auth | `ssh-ed25519 AAAA...` |

```hcl
boot_command = [
  "<tab><wait>",
  " ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"
]
```

---

## 3. boot_steps Format

The QEMU builder supports `boot_steps` — a newer alternative to `boot_command` that adds descriptive labels for debug output. Mutually exclusive with `boot_command`.

```hcl
source "qemu" "netbsd" {
  boot_steps = [
    ["1<enter><wait5>",        "Install NetBSD"],
    ["a<enter><wait5>",        "Installation messages in English"],
    ["a<enter><wait5>",        "Keyboard type: unchanged"],
    ["a<enter><wait5>",        "Install NetBSD to hard disk"],
    ["b<enter><wait5>",        "Yes"],
  ]
}
```

Each step is a two-element list: `["<keys-to-type>", "<description>"]`. The description is logged during debug mode (`PACKER_LOG=1`) to help trace where a boot sequence fails.

When `boot_command` is set and `boot_steps` is empty, the builder wraps the entire command as a single step with no description.

---

## 4. Preseed (Debian/Ubuntu)

Preseed automates Debian and Ubuntu installation. Packer serves the preseed file via its built-in HTTP server, and the boot command passes the URL on the kernel command line.

### preseed.cfg for QEMU

```hcl
# Partitioning on virtio disk
d-i grub-installer/bootdev string /dev/vda
d-i partman-auto/disk string /dev/vda
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic

# LVM on virtio (optional)
# d-i partman-auto/method string lvm

# Mirror selection for QEMU user networking
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string

# Minimal package selection
tasksel tasksel/first multiselect ubuntu-server
d-i pkgsel/include string openssh-server cloud-init qemu-guest-agent

# Post-install script via late_command
d-i preseed/late_command string \
    in-target wget -O /tmp/postinstall.sh http://{{ .HTTPIP }}:{{ .HTTPPort }}/postinstall.sh && \
    in-target chmod +x /tmp/postinstall.sh && \
    in-target /tmp/postinstall.sh
```

### HTTP Server Configuration

```hcl
source "qemu" "ubuntu" {
  http_directory = "http"
  http_port_min  = 8000
  http_port_max  = 9000

  boot_command = [
    "<esc><esc><enter><wait>",
    "/install/vmlinuz noapic ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US auto locale=en_US kbd-chooser/method=us ",
    "hostname={{ .Name }} ",
    "fb=false debconf/frontend=noninteractive ",
    "keyboard-configuration/modelcode=SKIP ",
    "keyboard-configuration/layout=USA ",
    "keyboard-configuration/variant=USA console-setup/ask_detect=false ",
    "initrd=/install/initrd.gz -- <enter>"
  ]
}
```

**QEMU networking note**: With default user networking, the guest reaches the host at `10.0.2.2`. The `{{ .HTTPIP }}` variable is automatically set to `10.0.2.2` when no bridge is configured. With a bridge (`net_bridge`), `{{ .HTTPIP }}` is discovered from the bridge interface.

---

## 5. Kickstart (RHEL/CentOS/Fedora/Alma/Rocky)

### ks.cfg for QEMU

```hcl
# Disk partitioning for virtio
clearpart --all --initlabel
part /boot --fstype=ext4 --size=1024 --ondisk=vda
part pv.01 --size=1 --grow --ondisk=vda
volgroup vg0 pv.01
logvol / --fstype=ext4 --name=root --vgname=vg0 --size=4096
logvol swap --name=swap --vgname=vg0 --size=2048
logvol /var --fstype=ext4 --name=var --vgname=vg0 --size=2048

# Package selection
%packages
@^server-product
@core
openssh-server
cloud-init
qemu-guest-agent
%end

# Pre-install script
%pre
#!/bin/bash
# Log to serial console for debugging
exec >/dev/ttyS0 2>&1
echo "Starting kickstart installation..."
%end

# Post-install script
%post --log=/root/post-install.log
#!/bin/bash
# Create a postinstall marker
touch /root/.packer-built
# Configure SSH
sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
%end

# Network config for QEMU user networking
network --bootproto=dhcp --device=link
firewall --enabled --service=ssh
services --enabled=sshd,cloud-init
```

### Boot Command with Kickstart

```hcl
source "qemu" "rhel" {
  http_directory = "http"

  boot_command = [
    "<tab><wait>",
    " ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    " console=ttyS0",
    "<enter>"
  ]
}
```

---

## 6. Autoinstall (Ubuntu 20.04+)

### user-data for QEMU

```yaml
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ubuntu-server
    username: ubuntu
    password: "$6$rounds=4096$..."   # hashed password
  ssh:
    install-server: true
    authorized-keys:
      - "ssh-ed25519 AAAAC3... user@host"
    allow-pw: false
  storage:
    layout:
      name: lvm
      match:
        size: largest
  packages:
    - qemu-guest-agent
    - cloud-init
    - htop
  late-commands:
    - echo "packer-built" > /target/.packer-complete
    - curtin in-target --target=/target -- systemctl enable qemu-guest-agent
```

### Boot Command for Autoinstall

```hcl
source "qemu" "ubuntu-autoinstall" {
  http_directory = "http"

  boot_command = [
    "<tab><wait>",
    " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    " console=ttyS0",
    "<enter>"
  ]
}
```

### NoCloud Datasource Seeding

Autoinstall can also be seeded via the NoCloud datasource using `meta-data` + `user-data` served from the HTTP directory:

```yaml
# meta-data
instance-id: ubuntu-autoinstall
local-hostname: ubuntu-server
```

---

## 7. Alpine Linux Automation

### answers file for setup-alpine

```hcl
# /etc/answers/setup-answers
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n alpine-vm"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS="-d example.com 8.8.8.8"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"                    # Use closest mirror for QEMU user networking
SSHDOPTS="-c openssh"
NTPOPTS="-c busybox"
DISKOPTS="-m sys /dev/vda"           # syslinux on virtio disk
LBUOPTS="none"
EOF
```

### Boot Command for Alpine

```hcl
source "qemu" "alpine" {
  http_directory = "http"

  boot_command = [
    "root<enter>",
    "setup-alpine -f /etc/answers/setup-answers<enter>",
    "<wait10>",
    # Post-install SSH key injection
    "echo 'ssh-ed25519 AAAAC3...' > /root/.ssh/authorized_keys<enter>"
  ]
}
```

Custom APK mirror selection for QEMU (user networking):

```hcl
APKREPOSOPTS="-f http://{{ .HTTPIP }}:{{ .HTTPPort }}/alpine"
```

---

## 8. cloud-init for QEMU

### NoCloud Datasource via Seed ISO

Create a seed ISO with `cloud-localds` (from `cloud-utils` package):

```shell
cloud-localds seed.iso user-data meta-data [network-config]
```

Three files needed:

**meta-data**:
```yaml
instance-id: vm-001
local-hostname: golden-image
```

**user-data**:
```yaml
#cloud-config
users:
  - name: packer
    ssh_authorized_keys:
      - "ssh-ed25519 AAAAC3... user@host"
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
package_update: true
packages:
  - qemu-guest-agent
  - cloud-init
```

**network-config** (optional):
```yaml
version: 2
ethernets:
  id0:
    match:
      driver: virtio_net
    dhcp4: true
```

### Attaching to QEMU

**Option A**: Via `cd_files` — Packer creates an ISO from the files automatically:

```hcl
source "qemu" "cloud-image" {
  cd_files = [
    "./seed/user-data",
    "./seed/meta-data",
    "./seed/network-config"
  ]
  cd_label = "cidata"

  boot_command = [
    "<wait>"
  ]
}
```

The `cd_label = "cidata"` is required for the NoCloud datasource to auto-detect the CDROM.

**Option B**: Pre-built seed ISO as a separate disk (requires pre-creating with `cloud-localds`):

```hcl
source "qemu" "cloud-image" {
  iso_url      = "https://cloud-images.ubuntu.com/.../ubuntu-24.04-server-cloudimg-amd64.img"
  iso_checksum = "sha256:..."
  disk_image   = true

  # Attach seed ISO as additional drive
  qemuargs = [
    ["-drive", "file=seed.iso,format=raw,if=virtio,index=1"]
  ]
}
```

**Option C**: Via `floppy_files` — some older distros detect NoCloud on floppy:

```hcl
source "qemu" "cloud-image" {
  floppy_files = [
    "./seed/user-data",
    "./seed/meta-data"
  ]
  floppy_label = "cidata"
}
```

---

## 9. HTTP Directory for Automation Files

Packer starts an HTTP server during the build to serve automation files to the guest.

### Configuration

```hcl
source "qemu" "example" {
  http_directory = "http"           # serve files from this directory
  http_port_min  = 8000             # default: 8000
  http_port_max  = 9000             # default: 9000
}
```

### http_content (inline content)

For small files, embed content directly instead of maintaining separate files:

```hcl
source "qemu" "example" {
  http_content = {
    "/preseed.cfg"  = templatefile("preseed.cfg.tpl", { ... })
    "/postinst.sh"  = "#!/bin/sh\necho done\n"
  }
}
```

### Guest Access via QEMU Networking

| Networking Mode | Guest Reaches Host At | Variable |
|---|---|---|
| User (default) | `10.0.2.2` | `{{ .HTTPIP }}` = `10.0.2.2` |
| Bridge (`net_bridge`) | Bridge interface IP | Auto-discovered |

The HTTP server port is available as `{{ .HTTPPort }}`.

### Example: Full Kickstart via HTTP

```hcl
source "qemu" "rocky" {
  http_directory = "kickstart"

  boot_command = [
    "<tab><wait>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    " console=ttyS0",
    "<enter>"
  ]
}
```

---

## 10. Floppy and CDROM Injection

When HTTP serving is not available (early boot, UEFI without network stack, or minimal initramfs):

### Floppy Injection

```hcl
source "qemu" "floppy-boot" {
  # Files to copy onto a virtual floppy
  floppy_files = [
    "config/ks.cfg",
    "config/drivers.img"
  ]
  # Inline content (key=path, value=content)
  floppy_content = {
    "autounattend.xml" = templatefile("autounattend.xml.tpl", { ... })
  }
  floppy_dirs = ["config/drivers"]
  floppy_label = "CONFIG"
}
```

Packer attaches the floppy via `-fda`.

### CDROM Injection

```hcl
source "qemu" "cd-boot" {
  cd_files = [
    "config/user-data",
    "config/meta-data",
    "config/network-config"
  ]
  cd_content = {
    "extra/readme.txt" = "Custom cloud image seed"
  }
  cd_label = "cidata"
}
```

Packer attaches the CD via `-cdrom` (virtio-scsi device).

### Floppy vs CDROM Decision Table

| Factor | Floppy | CDROM |
|---|---|---|
| Max size | ~1.44 MB | ISO limit |
| Label support | Yes (`floppy_label`) | Yes (`cd_label`) |
| Directory injection | Yes (`floppy_dirs`) | No |
| Inline content | Yes (`floppy_content`) | Yes (`cd_content`) |
| UEFI support | Rare | Common |
| Modern distros | Legacy | Preferred |

---

## 11. QEMU Serial Console

Adding `console=ttyS0` to the kernel boot parameters enables serial output, which Packer can capture if configured.

### Boot Command with Serial Console

```hcl
source "qemu" "serial-boot" {
  boot_command = [
    "<tab><wait>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    " console=ttyS0,115200",
    " console=tty0",
    "<enter>"
  ]
}
```

### QEMU Serial Device

Packer does not add a serial device by default for the QEMU builder. Use `qemuargs` to add one:

```hcl
source "qemu" "serial-debug" {
  qemuargs = [
    ["-serial", "stdio"],
    ["-display", "none"]
  ]
}
```

With `-serial stdio`, the guest's serial output is forwarded to Packer's stdout. Combine with `console=ttyS0` in the kernel cmdline for full visibility.

---

## 12. Debugging QEMU Boot

### PACKER_LOG

The most important debugging tool:

```shell
PACKER_LOG=1 packer build template.pkr.hcl
```

This logs every key sent over VNC, HTTP requests from the guest, and SSH connection attempts.

### VNC Connection During Build

Connect to the VNC display while the build is running to see what the guest displays:

```shell
vncviewer -Shared 127.0.0.1:5900
```

The display number is logged during the build:
```
==> qemu.example: Looking for available port between 5900 and 6000 on 127.0.0.1
```

### VNC Configuration

```hcl
source "qemu" "debug-build" {
  # Bind VNC to all interfaces (default: 127.0.0.1)
  vnc_bind_address = "0.0.0.0"

  # Port range to scan for available display
  vnc_port_min = 5900          # default
  vnc_port_max = 6000          # default

  # Password-protect VNC (auto-enables QMP socket)
  vnc_use_password = true
  vnc_password     = "secret"

  # Minimum port is 5900 (QEMU quirk)
  # Ports map to VNC displays: 5900 = :0, 5901 = :1, etc.
}
```

Validation rules (from `config.go`):
- `vnc_port_min` cannot be below 5900
- Both ports must be below 65535
- `vnc_port_min` must be less than `vnc_port_max`

### Headless vs GUI

```hcl
source "qemu" "debug-build" {
  headless = false    # show QEMU window (default: false)
}
```

When `headless = false`, QEMU opens a display window. The display option determines the backend:

```hcl
source "qemu" "display-options" {
  # Display backend: "gtk" (default), "none", "sdl", "spice-app"
  display = "gtk"

  # Let QEMU choose the default display
  use_default_display = true

  # VGA emulation type
  vga = "virtio"
}
```

**Display behavior matrix** (from `step_run.go`):

| `headless` | `display` | `use_default_display` | Result |
|---|---|---|---|
| `true` | — | — | No display (VNC still active) |
| `false` | `""` | `false` | `-display gtk` |
| `false` | `"none"` | `false` | `-display gtk` (FIXME: "none" treated as unset) |
| `false` | `"sdl"` | `false` | `-display sdl` |
| `false` | `""` | `true` | No `-display` flag (QEMU selects default) |

### Disabling VNC

```hcl
source "qemu" "no-vnc" {
  disable_vnc   = true
  boot_command  = []    # boot_command cannot be used with VNC disabled
}
```

When VNC is disabled, the boot command step is skipped entirely.

### Debug Mode

Packer debug mode pauses at each step, allowing manual VNC inspection:

```shell
packer build --debug template.pkr.hcl
```

In debug mode, the builder pauses before typing the boot command, giving you time to connect with `vncviewer` and observe the boot screen.

---

## Quick Reference: Field Summary

| Config Field | Type | Default | Description |
|---|---|---|---|
| `boot_command` | `[]string` | `[]` | Keys to type via VNC at boot |
| `boot_steps` | `[][]string` | `[]` | Boot command with descriptions (mutually exclusive with `boot_command`) |
| `boot_wait` | `string` (duration) | `"10s"` | Wait before typing boot command |
| `boot_key_interval` | `string` (duration) | per-key delay in ms | Delay between individual keystrokes |
| `boot_keygroup_interval` | `string` (duration) | SDK default | Delay between groups of key presses |
| `disable_vnc` | `bool` | `false` | Skip VNC/boot command entirely |
| `http_directory` | `string` | `""` | Directory to serve via HTTP |
| `http_content` | `map(string)` | `{}` | Inline files to serve via HTTP |
| `http_port_min` | `int` | `8000` | Minimum HTTP server port |
| `http_port_max` | `int` | `9000` | Maximum HTTP server port |
| `floppy_files` | `[]string` | `[]` | Files to copy onto virtual floppy |
| `floppy_content` | `map(string)` | `{}` | Inline floppy file content |
| `floppy_label` | `string` | `""` | Floppy volume label |
| `cd_files` | `[]string` | `[]` | Files to include on virtual CD |
| `cd_content` | `map(string)` | `{}` | Inline CD file content |
| `cd_label` | `string` | `""` | CD volume label |
| `vnc_bind_address` | `string` | `"127.0.0.1"` | IP to bind VNC server |
| `vnc_port_min` | `int` | `5900` | Minimum VNC port (inclusive) |
| `vnc_port_max` | `int` | `6000` | Maximum VNC port (inclusive) |
| `vnc_use_password` | `bool` | `false` | Enable VNC password auth |
| `vnc_password` | `string` | `""` | VNC password |
| `headless` | `bool` | `false` | Run without GUI window |
| `display` | `string` | `""` | QEMU display backend |
| `use_default_display` | `bool` | `false` | Let QEMU choose display |
| `vga` | `string` | `""` | VGA card emulation type |

### Template Variables

| Variable | Available In | Description |
|---|---|---|
| `{{ .HTTPIP }}` | `boot_command`, `boot_steps`, `qemuargs` | HTTP server IP |
| `{{ .HTTPPort }}` | `boot_command`, `boot_steps`, `qemuargs` | HTTP server port |
| `{{ .Name }}` | `boot_command`, `boot_steps` | VM name |
| `{{ .SSHPublicKey }}` | `boot_command`, `boot_steps` | Temporary SSH public key |

---

> [Check] All special keys documented match QEMU VNC driver implementation from `vnc_driver.go`
> [Check] Config field names and defaults from `config.go` and SDK `bootcommand/config.go`
> [Check] No references to VirtualBox, VMware, or non-QEMU builders
