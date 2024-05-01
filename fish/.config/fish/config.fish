if status is-interactive
	set -lx SHELL fish
	keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
	keychain --eval --agents gpg --quiet --gpg2 -Q DA18DB431829C349 | source
end

set -U XDG_CONFIG_HOME $HOME/.config

fzf_configure_bindings --directory=\cf --git_log=\cl --git_status=\cs --history=\ch --processes=\cp

starship init fish | source
direnv hook fish | source
zoxide init fish | source

set -U EDITOR nvim

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.local/share/coursier/bin

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share

abbr --add ll         "eza -l -h --git --classify --icons"
abbr --add la         "eza -l -h --git --classify --icons -a"
abbr --add tree       "eza -l -h --git --classify --icons --long --tree"
abbr --add g          "git"
abbr --add lg         "lazygit"
abbr --add glog       "git dlog"
abbr --add ur         "ls | xargs -P10 -I{} git -C {} pull"
abbr --add nv         "nvim"
abbr --add fz         "sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%"
abbr --add check_ping "ping -c 1 -W 3 google.com"
abbr --add vf         "vim (sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"
abbr --add nf         "nvim (sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"
abbr --add pkgclean   "sudo pacman -Rncs (pacman -Qdtq)"
abbr --add pkgcache   "sudo pacman -Scc"

alias hx='helix'

function cscope_gen
	find . -regex '.*\.\(c\|h\|cc\|hh\|cpp\|hpp\|hlsl\|glsl\|comp\|vert\|frag\)' > cscope.files
	cscope -b -q -k
end

function compress
	XZ_OPT=-9 tar cJF $argv.tar.xz $argv
end

function replace_all
	rg -l $argv[1] . | xargs sed -i "s/$argv[1]/$argv[2]/g"
end

if test (tty) = /dev/tty1
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec Hyprland
end
