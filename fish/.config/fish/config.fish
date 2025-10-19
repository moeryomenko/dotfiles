set -U fish_greeting ""

if status is-interactive
    set -lx SHELL fish
    keychain --eval --ssh-allow-forwarded --quiet /Users/eryoma/.ssh/id_ed25519 | source
    keychain --eval --ssh-allow-forwarded --quiet /Users/eryoma/.ssh/2gis | source
    # Load GPG keys without keychain to avoid warnings
    gpgconf --launch gpg-agent 2>/dev/null
    set -gx GPG_AGENT_INFO (gpgconf --list-dirs | grep agent-socket | cut -d: -f2)
end

export XDG_CONFIG_HOME=$HOME/.config

set -l foreground d8dee9
set -l selection 434c5e
set -l comment 4c566a
set -l red bf616a
set -l orange d08770
set -l yellow ebcb8b
set -l green a3be8c
set -l purple b48ead
set -l cyan 88c0d0
set -l pink b48ead

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
if test -S ~/.gnupg/S.gpg-agent
    set -gx GPG_AGENT_INFO ~/.gnupg/S.gpg-agent
end
export OLLAMA_API_BASE=http://127.0.0.1:11434

fzf_configure_bindings --directory=\cf --git_log=\ct --git_status=\cs --history=\cy --processes=\cp

# Key binding for editing command line with Option+E (Alt+E)
bind \ce edit_command_buffer

set -Ux EDITOR nvim
set -Ux GOPATH (go env GOPATH)
set NPM_PACKAGES "$HOME/.npm-packages"
set PATH $PATH $NPM_PACKAGES/bin
set MANPATH $NPM_PACKAGES/share/man $MANPATH

fish_add_path $XDG_CONFIG_HOME/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $GOPATH/bin
fish_add_path $HOME/projects/flutter/bin

starship init fish | source
direnv hook fish | source
zoxide init fish | source
fx --comp fish | source

# Flatpak settings
set -l xdg_data_home $XDG_DATA_HOME ~/.local/share
set -gx --path XDG_DATA_DIRS $xdg_data_home[1]/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share

alias hx='helix'
alias v='nvim'

# directory navigation related abbreviations
abbr --add ll   "eza -l -h --git --classify --icons"
abbr --add la   "eza -l -h --git --classify --icons -a"
abbr --add tree "eza -l -h --git --classify --icons --long --tree"
abbr --add fz   "sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%"
abbr --add cdfz "z (sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"

# git related abbreviations
abbr --add g    "git"
abbr --add lg   "lazygit"
abbr --add glog "git dlog"
abbr --add ur   "ls | xargs -P10 -I{} git -C {} pull"
abbr --add sw   "cd (worktree)"

# editing related abbreviations
abbr --add vf "v (sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"

# kubectl related abbreviations
abbr --add k   "kubectl"
abbr --add ksc "kubectl config use-context (kubectl config get-contexts -o name | sk --reverse --bind \"j:down,k:up,q:abort\")"
abbr --add kdn "kubectl config set-context --current --namespace=(kubectl get namespaces -o name | cut -d/ -f2 | sk --reverse --bind \"j:down,k:up,q:abort\")"
abbr --add kdp "kubectl get po -o name | cut -d/ -f2 | sk --reverse --preview-window=right:75% --preview 'kubectl describe po {} | bat'"

# golang related abbreviations
abbr --add fmtgou "git status --short | grep '[A|M]' | grep -E -o '[^ ]*\$' | grep '\.go\$' | xargs -I{} goimports -local (go list -m -f {{.Path}}) -w {}"
abbr --add gotest "gotestsum --format-hide-empty-pkg -f testname -- -p=1 -count=1 -timeout=1200s -coverprofile coverage.out "
abbr --add gotstw "gotestsum --watch --format-hide-empty-pkg -f testname -- -p=1 -count=1 -timeout=1200s -run (go list ./... | xargs -n1 go test -list . | grep ^Test | sk) ./...
"

# other stuff
abbr --add check_ping "ping -c 1 -W 3 google.com"
abbr --add jqcs       "jq 'map_keys(from_camel|to_snake)'"

function worktree
    git worktree list | awk '{ print $1}' | \
		sk --ansi --no-sort --reverse --tiebreak=index \
		--preview "git -C {} log --no-merges --date=relative -p" \
		--bind "alt-j:preview-down,alt-k:preview-up,ctrl-f:preview-page-down,crtl-b:preview-page-up,q:abort,ctrl-m:exec:echo {}" \
		--preview-window=right:70%
end

function cscope_gen
	find -E . -regex '.*.(c|h|cc|hh|cpp|hpp|cxx|hxx|hlsl|glsl|comp|vert|frag)' > cscope.files
	cscope -b -q -k
end

function compress
	XZ_OPT=-9 tar cjf $argv.tar.xz $argv
end

function replace_all
	rg -l $argv[1] . | xargs sed -i "s/$argv[1]/$argv[2]/g"
end

function job-select
    set -l job_list (jobs)

    if test -z "$job_list"
        echo "No background jobs"
        return
    end

    set -l selected (printf '%s\n' $job_list | sk --reverse --header="Select job to bring to foreground")

    if test -n "$selected"
        set -l group_id (echo $selected | awk '{print $2}')
        if test -n "$group_id"
            fg $group_id
        end
    end
end

alias jf='job-select'

if test (tty) = /dev/tty1
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec Hyprland
end
