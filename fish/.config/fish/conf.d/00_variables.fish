if test -S ~/.gnupg/S.gpg-agent
    set -gx GPG_AGENT_INFO ~/.gnupg/S.gpg-agent
end

set -Ux EDITOR hx
set -Ux VISUAL hx
set -Ux GOPATH (go env GOPATH)
set NPM_PACKAGES "$HOME/.npm-packages"
set PATH $PATH $NPM_PACKAGES/bin
set MANPATH $NPM_PACKAGES/share/man $MANPATH
set -Ux BUN_INSTALL "$HOME/.bun"

# proto
set -gx PROTO_HOME "$HOME/.proto"
set -gx PATH "$PROTO_HOME/shims" "$PROTO_HOME/bin" $PATH

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/projects/flutter/bin
fish_add_path $HOME/.opencode/bin
fish_add_path $BUN_INSTALL/bin

set -gx PATH $PATH /Users/eryoma/.lmstudio/bin
set -Ux OPENCODE_EXPERIMENTAL_LSP_TOOL true
set -Ux OPENCODE_ENABLE_EXA 1
set -gx CODEGRAPH_TELEMETRY 0

set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share
