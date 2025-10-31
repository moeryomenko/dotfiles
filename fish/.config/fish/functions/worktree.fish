function worktree
    git worktree list | awk '{ print $1}' | \
        sk --ansi --no-sort --reverse --tiebreak=index \
        --preview "git -C {} log --no-merges --date=relative -p" \
        --bind "alt-j:preview-down,alt-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:exec:echo {}" \
        --preview-window=right:70%
end
