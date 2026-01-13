# Nord Theme for Fish Shell
# Based on Nord color palette from Alacritty

# Nord color palette
set -l nord0 2E3440
set -l nord1 3B4252
set -l nord2 434C5E
set -l nord3 4C566A
set -l nord4 D8DEE9
set -l nord5 E5E9F0
set -l nord6 ECEFF4
set -l nord7 8FBCBB
set -l nord8 88C0D0
set -l nord9 81A1C1
set -l nord10 5E81AC
set -l nord11 BF616A
set -l nord12 D08770
set -l nord13 EBCB8B
set -l nord14 A3BE8C
set -l nord15 B48EAD

# Syntax Highlighting Colors
set -g fish_color_normal $nord4
set -g fish_color_command $nord9
set -g fish_color_keyword $nord15
set -g fish_color_quote $nord13
set -g fish_color_redirection $nord4
set -g fish_color_end $nord12
set -g fish_color_error $nord11
set -g fish_color_param $nord4
set -g fish_color_comment $nord3
set -g fish_color_selection --background=$nord2
set -g fish_color_search_match --background=$nord2
set -g fish_color_operator $nord14
set -g fish_color_escape $nord15
set -g fish_color_autosuggestion $nord3
set -g fish_color_cancel $nord11

# Completion Pager Colors
set -g fish_pager_color_progress $nord3
set -g fish_pager_color_prefix $nord8
set -g fish_pager_color_completion $nord4
set -g fish_pager_color_description $nord3
set -g fish_pager_color_selected_background --background=$nord2
set -g fish_pager_color_selected_prefix $nord8
set -g fish_pager_color_selected_completion $nord6
set -g fish_pager_color_selected_description $nord6
set -g fish_pager_color_secondary_background --background=$nord1
set -g fish_pager_color_secondary_prefix $nord8
set -g fish_pager_color_secondary_completion $nord4
set -g fish_pager_color_secondary_description $nord3
