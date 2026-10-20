function fzp
	fzf --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {}'  \
	--bind "alt-j:preview-down,alt-k:preview-up,ctrl-f:preview-page-down,ctrl-b:preview-page-up,q:abort,ctrl-m:execute:hx {}"  \
	--preview-window=right:70%
end
