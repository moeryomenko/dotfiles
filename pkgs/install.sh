#!/usr/bin/env bash
# install.sh -- install all packages listed in this directory
# Usage: ./install.sh
# Run on a fresh Arch Linux install after cloning dotfiles.
set -euo pipefail

DOTFILES_PKGS="$(cd "$(dirname "$0")" && pwd)"

# ================================================================
# Step 1: Install paru (AUR helper)
# ================================================================
install_paru() {
    echo "==> Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    if command -v paru &>/dev/null; then
        echo "    paru already installed, skipping build."
        return
    fi
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    cd "$tmpdir/paru"
    makepkg -si --noconfirm
    cd "$DOTFILES_PKGS"
    rm -rf "$tmpdir/paru"
    echo "    paru installed."
}

# ================================================================
# Step 2: Install official packages from pkglist.txt
# ================================================================
install_pacman_packages() {
    echo "==> Installing packages from pkglist.txt..."
    local pkglist
    # Strip comments and blank lines, extract bare package names
    pkglist="$(grep -vE '^\s*(#|$)' "$DOTFILES_PKGS/pkglist.txt" | sed 's/\s*#.*//')"
    # --batch: no prompt per package when --noconfirm is effective
    echo "$pkglist" | paru -S --needed --noconfirm --batch -
    echo "    done."
}

# ================================================================
# Step 3: Install AUR packages from pkglist-aur.txt
# ================================================================
install_aur_packages() {
    echo "==> Installing AUR packages from pkglist-aur.txt..."
    local aurlist
    aurlist="$(grep -vE '^\s*(#|$)' "$DOTFILES_PKGS/pkglist-aur.txt" | sed 's/\s*#.*//')"
    if [[ -z "$aurlist" ]]; then
        echo "    (none)"
        return
    fi
    echo "$aurlist" | paru -S --needed --noconfirm --batch -
    echo "    done."
}

# ================================================================
# Step 4: Install Go tools
# ================================================================
install_go_tools() {
    echo "==> Installing Go tools from pkglist-go-tools.txt..."
    if ! command -v go &>/dev/null; then
        echo "    WARNING: go not found -- skipping. (Install 'go' from pkglist.txt first and re-run.)"
        return
    fi
    while IFS= read -r pkg; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        echo "    go install $pkg"
        go install "$pkg@latest" || echo "    WARNING: $pkg failed (non-fatal)"
    done < "$DOTFILES_PKGS/pkglist-go-tools.txt"
    echo "    done."
}

# ================================================================
# Step 5: Install Rust/Cargo tools
# ================================================================
install_rust_tools() {
    echo "==> Installing Rust tools from pkglist-rust-tools.txt..."
    if ! command -v cargo &>/dev/null; then
        echo "    WARNING: cargo not found -- skipping. (Install 'rust' from pkglist.txt first and re-run.)"
        return
    fi
    while IFS= read -r pkg; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        echo "    cargo install $pkg"
        cargo install "$pkg" 2>/dev/null || echo "    WARNING: $pkg failed (non-fatal)"
    done < "$DOTFILES_PKGS/pkglist-rust-tools.txt"
    echo "    done."
}

# ================================================================
# Step 6: Install npm global packages
# ================================================================
install_npm_packages() {
    echo "==> Installing npm global packages from pkglist-npm.txt..."
    if ! command -v npm &>/dev/null; then
        echo "    WARNING: npm not found -- skipping. (Install 'nodejs' from pkglist.txt first and re-run.)"
        return
    fi
    while IFS= read -r pkg; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        echo "    npm install -g $pkg"
        npm install -g "$pkg" || echo "    WARNING: $pkg failed (non-fatal)"
    done < "$DOTFILES_PKGS/pkglist-npm.txt"
    echo "    done."
}

# ================================================================
# Main
# ================================================================
main() {
    echo "========================================"
    echo "  Arch Linux package installer"
    echo "  Source: $DOTFILES_PKGS"
    echo "========================================"
    echo ""

    install_paru
    echo ""
    install_pacman_packages
    echo ""
    install_aur_packages
    echo ""
    install_go_tools
    echo ""
    install_rust_tools
    echo ""
    install_npm_packages
    echo ""
    echo "========================================"
    echo "  All done!"
    echo "  You may want to stow your dotfiles:"
    echo "    cd $DOTFILES_PKGS/.. && stow ."
    echo "========================================"
}

main "$@"
