export XDG_CONFIG_HOME=$HOME/.config
export GPG_TTY=$(tty)

if test -S ~/.gnupg/S.gpg-agent
    set -gx GPG_AGENT_INFO ~/.gnupg/S.gpg-agent
end
export OLLAMA_API_BASE=http://127.0.0.1:11434

set -Ux EDITOR nvim
set -Ux GOPATH (go env GOPATH)
set NPM_PACKAGES "$HOME/.npm-packages"
set PATH $PATH $NPM_PACKAGES/bin
set MANPATH $NPM_PACKAGES/share/man $MANPATH

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/projects/flutter/bin
fish_add_path $HOME/.opencode/bin

set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share
