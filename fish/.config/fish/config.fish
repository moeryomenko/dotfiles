fish_add_path /opt/homebrew/bin

if status is-interactive
	set -lx SHELL fish
	keychain --eval --agents ssh --quiet -Q ~/.ssh/id_ed25519 | source
end

export GPG_TTY=$(tty)

set -U EDITOR nvim
set -U NPM_CONFIG_PREFIX $HOME/.npm-global
set -U GOPATH (go env GOPATH)
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

fish_add_path $HOME/.config/git-commands
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/Library/Python/3.10/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.sbm-cli/usr/bin

direnv hook fish | source
starship init fish | source
zoxide init fish | source

abbr --add ll   "eza -l -h --git --classify --icons"
abbr --add la   "eza -l -h --git --classify --icons -a"
abbr --add tree "eza -l -h --git --classify --icons --long --tree"
abbr --add g    "git"
abbr --add ga   "git a"
abbr --add lg   "lazygit"
abbr --add nv   "nvim"

set fzf_preview_dir_cmd ll
set fzf_preview_file_cmd bat
set fzf_fd_opts --hidden --exclude=.git

bind \cx edit_command_buffer

fzf_configure_bindings --history=\ch

function fz
	sk --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%
end

abbr --add htpf       "set pods (kubectl -n paas-content-operations-shifts get po -l app.kubernetes.io/component=perf-test --template '{{range.items}}{{.metadata.name}}{{\"\\n\"}}{{end}}'); for i in (seq (count \$pods)); fish -c \"kubectl -n paas-content-operations-shifts port-forward \\\$argv[1] 301\\\$argv[2]:3010\" \$pods[\$i] (math \$i - 1) & ; end"


abbr --add nslist    "kubectl get namespaces -l paas.sbermarket.tech/service=paas-content-operations-shifts -o name | sk --ansi --no-sort --reverse --tiebreak=index --bind \"j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:execute:set -U NAMESPACE (echo {} | sed 's/namespace\\///')\"+abort"
abbr --add kubestg   "kubectl config --context teleport.sbmt.io-stage use-context teleport.sbmt.io-stage"
abbr --add kubeprod  "kubectl config --context teleport.sbmt.io-k8s-prod use-context teleport.sbmt.io-k8s-prod"
abbr --add gpo       "kubectl -n \$NAMESPACE get po -l app.kubernetes.io/instance=paas-content-operations-shifts-paas"
abbr --add gpao      "kubectl -n \$NAMESPACE get po"
abbr --add rwpf      "kubectl -n paas-content-operations-shifts port-forward (kubectl -n paas-content-operations-shifts get po --template '{{(index .items 0).metadata.name}}') 6432:6432"
abbr --add ropf      "kubectl -n paas-content-operations-shifts port-forward (kubectl -n paas-content-operations-shifts get po --template '{{(index .items 0).metadata.name}}') 6532:6532"
abbr --add stgpf     "kubectl -n \$NAMESPACE port-forward postgresql-0 5432:5432"
abbr --add restartpo "kubectl -n \$NAMESPACE get po -l app.kubernetes.io/instance=\$NAMESPACE-paas --template '{{range.items}}{{.metadata.name}}{{\"\\n\"}}{{end}}' | xargs kubectl -n paas-content-operations-shifts delete po"
abbr --add restartw  "kubectl -n \$NAMESPACE get po -l app.kubernetes.io/component=workers --template '{{range.items}}{{.metadata.name}}{{\"\\n\"}}{{end}}' | xargs kubectl -n paas-content-operations-shifts delete po"
abbr --add swiss     "kubectl -n \$NAMESPACE scale deployment/swissknife --replicas"
abbr --add redispf   "kubectl -n paas-content-operations-shifts port-forward (kubectl -n paas-content-operations-shifts get po --template '{{(index .items 0).metadata.name}}') 6379:6379"
abbr --add gdpod     "kubectl -n \$NAMESPACE get po -o name | sk --ansi --no-sort --reverse --tiebreak=index --bind \"j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:execute:kubectl -n \$NAMESPACE describe po (echo {} | sed 's/pod\///') | less\"+abort"
abbr --add ppf       "kubectl -n \$NAMESPACE port-forward (kubectl -n \$NAMESPACE get po -o name | sk --ansi --no-sort --reverse --tiebreak=index --bind \"j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:execute:echo {}\"+abort) "
abbr --add logsof    "kubectl -n \$NAMESPACE get rollouts.argoproj.io -o name | sk --ansi --no-sort --reverse --tiebreak=index --bind \"j:down,k:up,ctrl-j:preview-down,ctrl-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:execute:stern --color=always -n \$NAMESPACE -l app.kubernetes.io/component=(echo {} | sed 's/rollout.argoproj.io\///') -o raw -c app | jlog \"+abort"
abbr --add sw        "cd (worktree)"

function worktree
    git worktree list | awk '{ print $1}' | \
    	sk --ansi --no-sort --reverse --tiebreak=index \
    	--preview "git -C {} clog" \
    	--bind "alt-j:preview-down,alt-k:preview-up,ctrl-f:preview-page-down,crtl-b:preview-page-up,q:abort,ctrl-m:exec:echo {}" \
    	--preview-window=right:70%
end

function b64e
	echo -n "$argv[1]" | base64
end

function b64d
	echo -n "$argv[1]" | base64 -d
	echo
end

function replace_all
	rg -l $argv[1] . | xargs sed -i'' 's/$argv[1]/$argv[2]/g'
end
