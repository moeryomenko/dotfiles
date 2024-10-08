HISTSIZE=-1
HISTFILESIZE=-1

if [ -f /etc/bashrc ]; then
	source /etc/bashrc
fi

if [ ! -f $HOME/.gdbinit ]; then
	curl -fLo $HOME/.gdbinit \
		https://raw.githubusercontent.com/cyrus-and/gdb-dashboard/master/.gdbinit
fi

if [ ! -f $XDG_CONFIG_HOME/bash_completion ]; then
	curl -fLo $XDG_CONFIG_HOME/bash_completion \
		https://raw.githubusercontent.com/scop/bash-completion/master/bash_completion
fi
source $XDG_CONFIG_HOME/bash_completion

if [ ! -f $XDG_CONFIG_HOME/git-completion ]; then
	curl -fLo $XDG_CONFIG_HOME/git-completion \
		https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
fi
source $XDG_CONFIG_HOME/git-completion

if [ ! -f $HOME/.gnupg/gpg-agent.conf ]; then
	ln -sf $XDG_CONFIG_HOME/gpg-agent.conf $HOME/.gnupg/gpg-agent.conf
fi


if [ ! -f $XDG_CONFIG_HOME/fzf-git.sh ]; then
	curl -fLo $XDG_CONFIG_HOME/fzf-git.sh \
                https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh
fi
source $XDG_CONFIG_HOME/fzf-git.sh

if [ ! -f $XDG_CONFIG_HOME/abbrev-alias.plugin.bash ]; then
        curl -fLo $XDG_CONFIG_HOME/abbrev-alias.plugin.bash \
                https://raw.githubusercontent.com/momo-lab/bash-abbrev-alias/master/abbrev-alias.plugin.bash
fi
source $XDG_CONFIG_HOME/abbrev-alias.plugin.bash

source $XDG_CONFIG_HOME/bash-prompt
source $XDG_CONFIG_HOME/oneliners.sh

set colored-stats on
set mark-simlinked-directories on
# append to the history file, don't overwrite it.
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command.
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry (allows easy re-editing of multi-line commands).
shopt -s cmdhist

# If there are multiple matches for completion, Tab should cycle through them
bind 'TAB':menu-complete
# Display a list of the matching files
bind "set show-all-if-ambiguous on"
# Perform partial completion on the first Tab press,
# only start cycling full results on the second Tab press
bind "set menu-complete-display-prefix on"
# Cycle through history based on characters already typed on the line
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

abbrev-alias -g g='git'
abbrev-alias -g ur='ls | xargs -P10 -I{} git -C {} pull'
abbrev-alias -g cor='ls | xargs -P10 -I{} git -C {} co main'
abbrev-alias -g ll='eza -l -h --git --classify --icons' #'ls -l -h --color'
abbrev-alias -g la='eza -l -h --git --classify --icons -a'
abbrev-alias -g tree='eza -l -h --git --classify --icons --long --tree'
abbrev-alias -g fz="sk --preview 'cat {}' --preview-window=right:70%"
abbrev-alias -g hx='helix'
abbrev-alias -g chping='ping -c 1 -W 3 google.com'
abbrev-alias -g pkgclean='sudo pacman -Rncs $(pacman -Qdtq)'
abbrev-alias -g pkgcache='sudo pacman -Scc'

export XKB_DEFAULT_LAYOUT=us
export EDITOR=vim

export PATH=$PATH:$XDG_CONFIG_HOME/git-commands
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.cargo/bin

export GPG_TTY=$(tty)

eval "$(fzf --bash)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CRTL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

function _fzf_compgen_path {
        fd --hidden --exclude .git . "$1"
}

function _fzf_compgen_dir {
        fd --type=d --hidden --exclude .git . "$1"
}

eval $(keychain --eval --agents ssh -Q --quiet ~/.ssh/id_ed25519)
eval $(keychain --eval --agents gpg --quiet --gpg2 5318919FE71A1E81)

if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
	#export WLR_RENDERER=vulkan
	export RADV_VIDEO_DECODE=1
	export SDL_VIDEODRIVER=wayland
	export GDK_BACKEND=wayland
	export XDG_SESSION_TYPE=wayland
	export XDG_CURRENT_DESKTOP=sway
	export MOZ_ENABLE_WAYLAND=1
	exec sway
fi
