if status is-interactive
	set -lx SHELL fish
	keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
 	keychain --eval --agents gpg --quiet --gpg2 -Q 5318919FE71A1E81 | source
 	keychain --eval --agents gpg --quiet --gpg2 -Q 4B065CE067340C25 | source
end

set -U XDG_CONFIG_HOME $HOME/.config

# TokyoNight Color Palette
set -l foreground c0caf5
set -l selection 2e3c64
set -l comment 565f89
set -l red f7768e
set -l orange ff9e64
set -l yellow e0af68
set -l green 9ece6a
set -l purple 9d7cd8
set -l cyan 7dcfff
set -l pink bb9af7

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
set -g fish_pager_color_selected_background --background=$selection

export GPG_TTY=$(tty)

export OLLAMA_API_BASE=http://127.0.0.1:11434

fzf_configure_bindings --directory=\cf --git_log=\cl --git_status=\cs --history=\cy --processes=\cp

starship init fish | source
direnv hook fish | source
zoxide init fish | source

set -U EDITOR nvim
set -U GOPATH (go env GOPATH)
set NPM_PACKAGES "$HOME/.npm-packages"
set PATH $PATH $NPM_PACKAGES/bin
set MANPATH $NPM_PACKAGES/share/man $MANPATH

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/.krew/bin

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
abbr --add sw         "cd (worktree)"

abbr --add gotest     "gotestsum --format-hide-empty-pkg -f dots-v2 -- -p=1 -count=1 -timeout=1200s"

alias hx='helix'

function worktree
    git worktree list | awk '{ print $1}' | \
		sk --ansi --no-sort --reverse --tiebreak=index \
		--preview "git -C {} log --no-merges --date=relative -p" \
		--bind "alt-j:preview-down,alt-k:preview-up,ctrl-f:preview-page-down,crtl-b:preview-page-up,q:abort,ctrl-m:exec:echo {}" \
		--preview-window=right:70%
end

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

if not test -d $HOME/.asdf
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
end
source ~/.asdf/asdf.fish

if test (tty) = /dev/tty1
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec Hyprland
end
