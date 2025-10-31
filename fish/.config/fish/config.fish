set -U fish_greeting ""

if status is-interactive
    set -lx SHELL fish
    keychain --eval --ssh-allow-forwarded --quiet /home/eryoma/.ssh/id_ed25519 | source
    keychain --eval --ssh-allow-forwarded --quiet /home/eryoma/.ssh/2gis | source
    keychain --eval --quiet --gpg2 5318919FE71A1E81 | source
	keychain --eval --quiet --gpg2 73EFE8958507112E | source
end

export XDG_CONFIG_HOME=$HOME/.config

fzf_configure_bindings --directory=\cf --git_log=\ct --git_status=\cs --history=\cy --processes=\cp

# Key binding for editing command line with Option+E (Alt+E)
bind \ce edit_command_buffer

starship init fish | source
direnv hook fish | source
zoxide init fish | source
fx --comp fish | source

if test (tty) = /dev/tty1
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec Hyprland
end
