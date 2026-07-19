set -gx XDG_CONFIG_HOME $HOME/.config
set -gx GPG_TTY (tty)

if test -S ~/.gnupg/S.gpg-agent
    set -gx GPG_AGENT_INFO ~/.gnupg/S.gpg-agent
end

set -gx DOCKER_HOST unix:///run/user/(id -u)/podman/podman.sock

set -Ux EDITOR nvim
set -Ux VISUAL nvim
set -Ux GOPATH (go env GOPATH)
set NPM_PACKAGES "$HOME/.npm-packages"
set PATH $PATH $NPM_PACKAGES/bin
set MANPATH $NPM_PACKAGES/share/man $MANPATH
set -Ux HF_TOKEN (pass show hf/access_token)
set -Ux BUN_INSTALL "$HOME/.bun"

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/projects/flutter/bin
fish_add_path $HOME/.opencode/bin
fish_add_path $BUN_INSTALL/bin

# Use wild linker for all C/C++ builds (GCC/Clang driver flag)
set -gx LDFLAGS "-fuse-ld=wild"

# Disable legacy ccache; sccache handles caching instead
set -gx CCACHE_DISABLE 1

set -Ux OPENCODE_EXPERIMENTAL_LSP_TOOL true
set -Ux OPENCODE_ENABLE_EXA 1
set -gx CODEGRAPH_TELEMETRY 0

set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share
