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
