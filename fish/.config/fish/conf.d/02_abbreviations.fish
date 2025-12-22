# directory navigation related abbreviations
abbr --add ll   "eza -l -h --git --classify --icons"
abbr --add la   "eza -l -h --git --classify --icons -a"
abbr --add tree "eza -l -h --git --classify --icons --long --tree"
abbr --add fz   "sk --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%"
abbr --add cdfz "z (sk --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:70%)"

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
abbr --add cargoall   "cargo install (cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:?\$' | cut -f1 -d' ')"
