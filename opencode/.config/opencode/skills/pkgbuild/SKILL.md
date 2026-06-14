---
name: pkgbuild
description: Write and maintain Arch Linux PKGBUILD build scripts for pacman/makepkg. Covers required fields, build functions, common patterns, VCS sources, split packages, and Arch packaging standards.
when_to_use: "When creating or fixing a PKGBUILD for Arch Linux, adding VCS (git/svn/hg/bzr) sources, or converting a build script to Arch packaging format. NOT for writing RPM spec files, Debian control files, or non-Arch packages."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
effort: medium
---

# PKGBUILD — Arch Linux Package Build Scripts

> A PKGBUILD is a Bash script that tells makepkg how to build and package software for Arch Linux. Correct PKGBUILDs follow a strict format, use standard functions, and adhere to the Arch Packaging Standards.

## Overview

Arch Linux packages are built from PKGBUILD files using `makepkg`. The PKGBUILD is a Bash script with predefined variables and functions. Building produces a `.pkg.tar.zst` archive that `pacman` can install. This skill covers the complete specification: mandatory/optional variables, build functions, dependency management, VCS sources, split packages, and quality assurance with `namcap`.

## When to Use

**Good for:**
- Creating a PKGBUILD from scratch for new software
- Updating an existing PKGBUILD (new version, new dependencies)
- Packaging software from VCS sources (git, svn, hg, bzr) with `pkgver()` auto-bump
- Creating split packages (multiple packages from one PKGBUILD)
- Submitting or reviewing AUR packages
- Fixing common packaging mistakes (missing dependencies, wrong install paths)

**Not for:**
- Building C/C++ software (that is what the PKGBUILD orchestrates — use `cmake`/`meson` skills for the build logic *inside* functions)
- Non-Arch packaging formats (RPM .spec, Debian control, Flatpak manifests)
- Configuring makepkg itself (use `/etc/makepkg.conf` for that)

---

## Protocol

### Step 1: Determine Package Metadata

Identify these from upstream before writing:

| Field | Source |
|-------|--------|
| `pkgname` | Project name (lowercase, no hyphens at start, match tarball name) |
| `pkgver` | Upstream release version (no hyphens — replace with underscores) |
| `pkgrel` | Start at `1`, increment per PKGBUILD change, reset on version bump |
| `arch` | `x86_64` for compiled, `any` for noarch (scripts, themes, fonts) |
| `url` | Project homepage or repository |
| `license` | SPDX identifier (GPL3, MIT, Apache, BSD-2-Clause, custom:...) |
| `depends` | Runtime shared library deps from `ldd` |
| `makedepends` | Build tools (cmake, meson, python, go, rust, git) |
| `source` | Release tarball URL using `$pkgname` and `$pkgver` |
| `sha256sums` | Generate with `makepkg -g` or `updpkgsums` |

> **Rule**: `base-devel` is assumed installed by makepkg. Do NOT list its members in `makedepends`.

### Step 2: Write the PKGBUILD in Canonical Field Order

Maintain the standard field ordering established by `PKGBUILD(5)` so other maintainers can read it immediately. The canonical order is:

```
# Maintainer: name <email>
# Contributor: name <email>

pkgname=
pkgver=
pkgrel=
epoch=
pkgdesc=
arch=()
url=
license=()
groups=()
depends=()
makedepends=()
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=()
noextract=()
b2sums=()           # sha224sums sha256sums sha384sums sha512sums md5sums
validpgpkeys=()
```

### Step 3: Implement Required Functions

Every PKGBUILD needs at minimum a `package()` function. The build pipeline runs:

```
prepare() → build() → check() → package()
```

#### `prepare()` — Source preparation

Apply patches, modify source before build:

```bash
prepare() {
    cd "$srcdir/$pkgname-$pkgver"
    patch -Np1 -i "$srcdir/fix-build.patch"
    # Or for autotools with git:
    autoreconf -fi
}
```

#### `build()` — Compilation

Build the software. `$srcdir` is the working directory at start. Common build systems:

```bash
# Autotools
build() {
    cd "$srcdir/$pkgname-$pkgver"
    ./configure --prefix=/usr --sysconfdir=/etc
    make
}

# CMake
build() {
    cmake -B build -S "$srcdir/$pkgname-$pkgver" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -Wno-dev
    cmake --build build
}

# Meson
build() {
    arch-meson "$srcdir/$pkgname-$pkgver" build \
        -Dprefix=/usr
    meson compile -C build
}

# Go
build() {
    cd "$srcdir/$pkgname-$pkgver"
    go build -o . -ldflags="-s -w" .
}

# Python (PEP 517)
build() {
    cd "$srcdir/$pkgname-$pkgver"
    python -m build --wheel --no-isolation
}

# Rust
build() {
    cd "$srcdir/$pkgname-$pkgver"
    cargo build --release --locked
}

# Node.js / npm
build() {
    cd "$srcdir/$pkgname-$pkgver"
    npm run build
}
```

> **Always use `--prefix=/usr`** — never install to `/usr/local` in Arch packages.

#### `check()` — Run tests

Called after `build()` only when running `makepkg --check`:

```bash
check() {
    cd "$srcdir/$pkgname-$pkgver"
    make check
}
```

#### `package()` — Install files into `$pkgdir`

Copy the built files into the package directory. `$pkgdir` mirrors the root filesystem:

```bash
# Autotools
package() {
    cd "$srcdir/$pkgname-$pkgver"
    make DESTDIR="$pkgdir" install
}

# CMake
package() {
    DESTDIR="$pkgdir" cmake --install build
}

# Meson
package() {
    DESTDIR="$pkgdir" meson install -C build
}

# Manual install
package() {
    cd "$srcdir/$pkgname-$pkgver"
    install -Dm755 "$pkgname" "$pkgdir/usr/bin/$pkgname"
    install -Dm644 "$pkgname.desktop" "$pkgdir/usr/share/applications/$pkgname.desktop"
    install -Dm644 "$pkgname.png" "$pkgdir/usr/share/pixmaps/$pkgname.png"
}
```

> **Never install to `/usr/local`** inside `$pkgdir`. Use `/usr` prefix consistently.

### Step 4: Validate with namcap

```bash
# Validate PKGBUILD static analysis
namcap PKGBUILD

# After building, validate the package
makepkg --install   # builds the package
namcap <pkgname>-<pkgver>-<pkgrel>-<arch>.pkg.tar.zst
```

### Step 5: Test the Build

```bash
# Clean build
makepkg -C

# Build with checks
makepkg --check

# Install the resulting package
sudo pacman -U <package>.pkg.tar.zst

# Update checksums after changing source URL
updpkgsums
```

---

## Common Patterns

### 1. VCS Packages (git, svn, hg)

Name the package with a `-git`, `-svn`, `-hg` suffix. Use `pkgver()` function for auto-bump:

```bash
# Git — latest commit on default branch
pkgname=foobar-git
pkgver=1.0
pkgrel=1
arch=('x86_64')
depends=('libfoo')
makedepends=('git')
source=("$pkgname::git+https://github.com/example/foobar.git")

pkgver() {
    cd "$srcdir/$pkgname"
    git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
    cd "$srcdir/$pkgname"
    # build from checkout
}

package() {
    cd "$srcdir/$pkgname"
    make DESTDIR="$pkgdir" install
}

# Use #tag= or #commit= fragments for pinned versions:
source=("$pkgname::git+https://github.com/example/foobar.git#tag=v1.0.0")
```

| VCS | Source URL prefix | `pkgver()` command | `makedepends` |
|-----|-------------------|-------------------|---------------|
| Git | `git+https://...` | `git describe --long --tags \| sed 's/\([^-]*-g\)/r\1/;s/-/./g'` | `('git')` |
| Mercurial | `hg+https://...` | `hg identify -n` | `('mercurial')` |
| Subversion | `svn+https://...` | `svnversion \| tr -d :` | `('subversion')` |
| Bazaar | `bzr+https://...` | `bzr revno` | `('bazaar')` |

> VCS sources in `source=()` support `folder`, `vcs+` prefix, and `#fragment` options. See PKGBUILD(5) § USING VCS SOURCES.

### 2. Split Packages

One PKGBUILD produces multiple packages. Override per-package variables in each `package_*()`:

```bash
pkgname=('libfoo' 'libfoo-docs' 'libfoo-dev')
pkgver=2.0
pkgrel=1
arch=('x86_64')
depends=('glibc')
makedepends=('doxygen' 'cmake')
source=("https://example.com/$pkgname-$pkgver.tar.gz")

build() {
    cmake -B build -S "$srcdir/libfoo-$pkgver" \
        -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build
}

check() {
    cmake --build build --target test
}

package_libfoo() {
    depends=('glibc')
    DESTDIR="$pkgdir" cmake --install build
}

package_libfoo-docs() {
    depends=()
    pkgdesc="Documentation for libfoo"
    install -Dm644 "$srcdir/libfoo-$pkgver/README" \
        "$pkgdir/usr/share/doc/libfoo/README"
}

package_libfoo-dev() {
    depends=('libfoo')
    pkgdesc="Development headers for libfoo"
    # headers already installed by package_libfoo, copy here
    # or use install targets with COMPONENT=development
}
```

Variables overridable per split package: `pkgdesc`, `arch`, `url`, `license`, `groups`, `depends`, `optdepends`, `provides`, `conflicts`, `replaces`, `backup`, `options`, `install`, `changelog`.

### 3. Custom License Files

For non-standard licenses, use `LicenseRef-` or `custom:` identifier and install the license:

```bash
license=('LicenseRef-MyLicense' 'GPL3')

package() {
    cd "$srcdir/$pkgname-$pkgver"
    make DESTDIR="$pkgdir" install
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
```

### 4. optdepends with Descriptions

Annotate optional dependencies with a short description:

```bash
optdepends=(
    'python: Python bindings'
    'ffmpeg: video support'
    'libnotify: desktop notifications'
    'bash-completion: bash completion support'
)
```

### 5. Using `prepare()` with Patch Files

Store patches alongside PKGBUILD and apply in `prepare()`:

```bash
source=("https://example.com/$pkgname-$pkgver.tar.gz"
        "fix-build-with-new-gcc.patch::https://bugs.example.com/attachment?id=123")
sha256sums=('SKIP'
            'abcd1234...')

prepare() {
    cd "$srcdir/$pkgname-$pkgver"
    patch -Np1 -i "$srcdir/fix-build-with-new-gcc.patch"
}
```

### 6. Backwards-Compatible Version Tags

Replace hyphens in upstream versions with underscores:

```bash
# Upstream version: 2.0-beta
pkgver=2.0_beta
source=("https://example.com/$pkgname-${pkgver//_/-}.tar.gz")
```

### 7. install Scripts (.install files)

`.install` files run hooks during `pacman` operations. Reference them with the `install` directive:

```bash
install=("$pkgname.install")
```

Create `$pkgname.install`:
```bash
post_install() {
    echo "Run 'systemctl enable foobar' to enable the service"
}

pre_upgrade() {
    systemctl stop foobar.service 2>/dev/null || true
}

post_upgrade() {
    systemctl daemon-reload
    systemctl try-restart foobar.service
}

pre_remove() {
    systemctl stop foobar.service
}

post_remove() {
    systemctl daemon-reload
}
```

Hook order: `pre_upgrade` → `post_upgrade` (replaces `pre_install`/`post_install` for upgrades).

---

## Dependency Discovery

Dependencies are the most common PKGBUILD error. Use these tools:

```bash
# Find runtime shared library dependencies
ldd --unused --function-relocs /path/to/binary

# Automatic dependency/provide discovery (from devtools)
find-libdeps /path/to/package.pkg.tar.zst
find-libprovides /path/to/package.pkg.tar.zst

# Analyze PKGBUILD with namcap
namcap PKGBUILD

# Analyze built package with namcap
namcap /path/to/package.pkg.tar.zst
```

### Rules

- **List direct dependencies only** — do not rely on transitive deps.
- **Do not add `$pkgname` to `provides`** — it is implicit.
- **Do not add `$pkgname` to `conflicts`** — a package cannot conflict with itself.
- **List shared libraries in `provides`** (e.g. `'libsomething.so'`).
- **`base-devel` members are assumed** — do not list in `makedepends`.

---

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `PKGBUILD: line N: syntax error` | Bash syntax error in PKGBUILD | Check quoting, array brackets, line continuations |
| `pkgver` contains hyphen | Upstream version uses hyphens | Replace `-` with `_` in `pkgver`, fix in `source` URL with `${pkgver//_/-}` |
| `cannot find -lfoo` during build | Missing `makedepends` entry | Add the library's dev package to `makedepends` |
| Files installed to `/usr/local` | Build system default prefix | Override with `--prefix=/usr` or `DESTDIR="$pkgdir"` |
| `sha256sums` mismatch after URL change | Checksums not updated | Run `updpkgsums` |
| Missing runtime libraries at app start | Missing `depends` entry | Run `ldd` on the binary, add missing lib packages to `depends` |
| VCS source not updating | Cache in `$SRCDEST` | Delete `$SRCDEST` cache or use `makepkg -C` to clean |
| `set -e` / pipeline errors ignored | Bash `set -e` not honored in `||` chains | Use `set -o pipefail` or restructure to avoid masked errors |

---

## Quality Checklist

- [ ] `pkgname`, `pkgver`, `pkgrel`, `arch` all present and correct
- [ ] `license` present (prevents `makepkg` warning)
- [ ] `pkgver` contains no hyphens
- [ ] `source` URLs use `$pkgname` and `$pkgver` variables
- [ ] `sha256sums` (or other checksum array) matches `source` count
- [ ] No `/usr/local` paths in `package()` function
- [ ] All `makedepends` entries are build-time-only tools
- [ ] No `base-devel` members in `makedepends`
- [ ] Runtime dependencies verified with `ldd`
- [ ] `namcap PKGBUILD` passes (or warnings are understood/intentional)
- [ ] `makepkg --check` passes all upstream tests
- [ ] Package installs and runs correctly
- [ ] For VCS: `pkgver()` function defined, `pkgver` variable set with latest known value
- [ ] For split packages: each `package_*()` has correct overrides
- [ ] Field ordering follows canonical PKGBUILD(5) order
- [ ] Lines wrapped to ~100 characters
- [ ] Empty arrays removed (e.g. `replaces=()` removed if empty)

---

## Verification Markers

- [ ] Step 1: Package metadata complete (name, version, license, arch, description)
- [ ] Step 2: PKGBUILD skeleton written with canonical field ordering
- [ ] Step 3: Build functions implemented (`prepare`, `build`, `check`, `package`)
- [ ] Step 4: `makepkg -g` or `updpkgsums` produces matching checksums
- [ ] Step 5: `namcap PKGBUILD` produces no errors
- [ ] Step 6: `makepkg` builds the package successfully
- [ ] Step 7: `namcap <built package>` validates the result
- [ ] Step 8: Package installs with `pacman -U` and functions correctly
