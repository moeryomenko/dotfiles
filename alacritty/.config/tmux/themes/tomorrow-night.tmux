# Color key:
#   #202020 Background
#   #282a2e Current Line
#   #373b41 Selection
#   #c5c8c6 Foreground
#   #969896 Comment
#   #cc6666 Red
#   #de935f Orange
#   #f0c674 Yellow
#   #b5bd68 Green
#   #8abeb7 Aqua
#   #81a2be Blue
#   #b294bb Purple


## set status bar
set -g status-style bg=default
setw -g window-status-current-style bg="#282a2e"
setw -g window-status-current-style fg="#81a2be"

## highlight active window
setw -g pane-active-border-style ''

## highlight activity in status bar
setw -g window-status-activity-style fg="#8abeb7"
setw -g window-status-activity-style bg="#202020"

## pane border and colors
set -g pane-active-border-style bg=default
set -g pane-active-border-style fg="#373b41"
set -g pane-border-style bg=default
set -g pane-border-style fg="#373b41"

set -g clock-mode-colour "#81a2be"
set -g clock-mode-style 24

set -g message-style bg="#8abeb7"
set -g message-style fg="#000000"

set -g message-command-style bg="#8abeb7"
set -g message-command-style fg="#000000"

# message bar or "prompt"
set -g message-style bg="#2d2d2d"
set -g message-style fg="#cc99cc"

set -g mode-style bg="#202020"
set -g mode-style fg="#de935f"

# background window tab
set-window-option -g window-status-style bg=default
set-window-option -g window-status-style fg=white
set-window-option -g window-status-style none
set-window-option -g window-status-format '#[fg=#6699cc,bg=colour235] #I #[fg=#999999,bg=#2d2d2d] #W #[default]'

# foreground window tab
set-window-option -g window-status-current-style none
set-window-option -g window-status-current-format '#[fg=#b5bd68,bg=#2d2d2d] #I #[fg=#cccccc,bg=#393939] #W #[default]'

# window borders
set -g pane-border-style bg=default
set -g pane-border-style fg="#999999"
set -g pane-active-border-style fg="#b5bd68" # "#f99157"
