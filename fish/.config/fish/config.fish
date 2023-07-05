if status is-interactive
	set -lx SHELL fish
	keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
	keychain --eval --agents gpg --quiet --gpg2 -Q BDEFC42C5E88B8C5 | source
end

if not test -d $HOME/.asdf
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.11.3
end
source $HOME/.asdf/asdf.fish
source $HOME/.asdf/completions/asdf.fish

if not test -d $HOME/.sdkman
		curl -s "https://get.sdkman.io" | bash
		fisher install reitzig/sdkman-for-fish@v1.4.0
		fisher install PatrickF1/fzf.fish
end

fzf_configure_bindings --directory=\cf --git_log=\cl --git_status=\cs --history=\ch --processes=\cp

if test -d $HOME/.sdkman
        export SDKMAN_DIR="$HOME/.sdkman"
        export JAVA_HOME=$(sdk home java current)
end

set -U EDITOR nvim
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -U GOPATH (go env GOPATH)

fish_add_path $HOME/.config/git-commands
fish_add_path $HOME/.local/bin
fish_add_path (go env GOPATH)/bin
# fish_add_path (rustup show home)/bin

set -U tide_git_icon 󰊢
set -U tide_pwd_icon 󰉋
set -U tide_pwd_icon_home 󱂵

alias ll='exa -l -h --git --classify --icons'
alias la='ll -a'
alias g='git'

if set -q KITTY_INSTALLATION_DIR
    set --global KITTY_SHELL_INTEGRATION enabled
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end

function fz
  sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%
end

alias vf='nvim (fz)'
