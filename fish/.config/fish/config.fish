set -U fish_greeting ""

# Source local overrides if they exist (not tracked in git)
if test -f ~/.config/fish/config.local.fish
    source ~/.config/fish/config.local.fish
end

fzf_configure_bindings --directory=\cf --git_log=\ct --git_status=\cs --history=\cy --processes=\cp

# Key binding for editing command line with Option+E (Alt+E)
bind \ce edit_command_buffer

starship init fish | source
direnv hook fish | source
zoxide init fish | source
fx --comp fish | source
mise activate fish | source
atuin init fish | source
task --completion fish | source

# bind to ctrl-r in normal and insert mode, add any other bindings you want here too
bind \cr _atuin_search
bind -M insert \cr _atuin_search

# Start Hyprland on tty1 unless something is already running there.
# XDG_VTNR is set by agetty and survives shell startup, unlike (tty),
# which is unreliable when stdin is not the controlling terminal.
if status is-interactive
    and test "$XDG_VTNR" = 1
    and test -z "$WAYLAND_DISPLAY"
    and test -z "$HYPRLAND_INSTANCE_SIGNATURE"
    export RADV_VIDEO_DECODE=1
    export SDL_VIDEODRIVER=wayland
    export GDK_BACKEND=wayland
    export MOZ_ENABLE_WAYLAND=1
    exec start-hyprland
end
