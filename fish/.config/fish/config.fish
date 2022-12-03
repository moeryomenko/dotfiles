if not test -f ~/.config/fish/fish_plugins
	curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
	fisher install IlanCosman/tide@v5
end

set -U EDITOR nvim
set -U NPM_CONFIG_PREFIX $HOME/.npm-global

fish_add_path $NPM_CONFIG_PREFIX/bin
fish_add_path $HOME/.config/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
set -U MANPAGER "sh -c 'col -bx | bat -l man -p'"

set -U tide_git_icon 
set -U tide_pwd_icon 
set -U tide_pwd_icon_home 

alias ll='exa -l -h --git --classify --icons'
alias la='ll -a'
alias g='git'

if set -q KITTY_INSTALLATION_DIR
    set --global KITTY_SHELL_INTEGRATION enabled
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end

if status is-login
    keychain --clear --quiet
end

if test -f ~/.keychain/(prompt_hostname)-gpg-fish
    source ~/.keychain/(prompt_hostname)-gpg-fish
end

if test -f ~/.keychain/(prompt_hostname)-fish
    source ~/.keychain/(prompt_hostname)-fish
end

if status is-interactive
	keychain --eval --agents ssh -Q --quiet ~/.ssh/id_moeryomenko
	keychain --eval --agents gpg --quiet --gpg2 BDEFC42C5E88B8C5
end
