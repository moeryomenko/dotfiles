if status is-interactive
	set -lx SHELL fish
	keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
	keychain --eval --agents gpg --quiet --gpg2 -Q 12A5CF1067A4958B | source
end

if not test -d $HOME/.asdf
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.11.3
end
source $HOME/.asdf/asdf.fish
source $HOME/.asdf/completions/asdf.fish

fzf_configure_bindings --directory=\cf --git_log=\cl --git_status=\cs --history=\ch --processes=\cp

direnv hook fish | source

starship init fish | source

set -U EDITOR nvim
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -U GOPATH (go env GOPATH)

fish_add_path $HOME/.config/git-commands
fish_add_path $HOME/.local/bin
fish_add_path (go env GOPATH)/bin
fish_add_path $HOME/.cargo/bin

set -U tide_git_icon 󰊢
set -U tide_pwd_icon 󰉋
set -U tide_pwd_icon_home 󱂵

abbr --add ll         "exa -l -h --git --classify --icons"
abbr --add la         "exa -l -h --git --classify --icons -a"
abbr --add tree       "exa -l -h --git --classify --icons --long --tree"
abbr --add g          "git"
abbr --add glog       "git dlog"
abbr --add ur         "ls | xargs -P10 -I{} git -C {} pull"
abbr --add nv         "nvim"
abbr --add fz         "sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%"
abbr --add check_ping "ping -c 1 -W 3 google.com"
abbr --add vf         "nvim (sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"

alias hx='helix'

if set -q KITTY_INSTALLATION_DIR
    set --global KITTY_SHELL_INTEGRATION enabled
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end

function cscope_gen
	find . -regex '.*\.\(c\|h\|cc\|hh\|cpp\|hpp\|hlsl\|glsl\)' > cscope.files
	cscope -b -q -k
end
