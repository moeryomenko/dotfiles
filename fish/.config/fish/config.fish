if status --is-interactive
    set -lx SHELL fish
    keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
    keychain --eval --agents gpg --quiet --gpg2 -Q BDEFC42C5E88B8C5 | source
end

if not test -f ~/.config/fish/fish_plugins
  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
  fisher install IlanCosman/tide@v5
end

if not test -d $HOME/.asdf
  git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.11.3
end
source $HOME/.asdf/asdf.fish
source $HOME/.asdf/completions/asdf.fish
kind completion fish | source

set -U EDITOR nvim
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

fish_add_path $NPM_CONFIG_PREFIX/bin
fish_add_path $HOME/.config/git-commands
fish_add_path $HOME/.local/bin
fish_add_path (rustup show home)/bin

set -U tide_git_icon 󰊢
set -U tide_pwd_icon 󰉋
set -U tide_pwd_icon_home 󱂵

# wayland env vars.
set -U GDK_BACKEND wayland
set -U XDG_SESSION_TYPE wayland
set -U XDG_CURRENT_DESKTOP sway
set -U MOZ_ENABLE_WAYLAND 1

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share

for flatpakdir in ~/.local/share/flatpak/exports/bin /var/lib/flatpak/exports/bin
    if test -d $flatpakdir
        contains $flatpakdir $PATH; or set -a PATH $flatpakdir
    end
end

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

if test (tty) = /dev/tty1
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec sway
end


alias vf='nvim (fz)'
