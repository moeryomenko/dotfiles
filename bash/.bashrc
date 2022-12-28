HISTSIZE=-1
HISTFILESIZE=-1

if [ -f /etc/bashrc ]; then
        source /etc/bashrc
fi

if [ ! -f $HOME/.gdbinit ]; then
        curl -fLo $HOME/.gdbinit \
                https://raw.githubusercontent.com/cyrus-and/gdb-dashboard/master/.gdbinit
fi

if [ ! -f $HOME/.config/bash_completion ]; then
        curl -fLo $HOME/.config/bash_completion \
                https://raw.githubusercontent.com/scop/bash-completion/master/bash_completion
fi
source $HOME/.config/bash_completion

if [ ! -f $HOME/.config/git-completion ]; then
        curl -fLo $HOME/.config/git-completion \
                https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
fi
source $HOME/.config/git-completion

if [ ! -f $HOME/.gnupg/gpg-agent.conf ]; then
        ln -sf $HOME/.config/gpg-agent.conf $HOME/.gnupg/gpg-agent.conf
fi

source $HOME/.config/bash-prompt
source $HOME/.config/oneliners.sh

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

alias g=git
alias gco='g co'
alias glog='g glog'
alias ga='g a'
alias grb='g rb'
alias grbc='g rbc'
alias gcm='g cm'
alias gcmm='g cmm'
alias grc='g rc'
alias gcp='g cp'
alias gpo='g po'
alias gpfo='g pfo'
alias ur='ls | xargs -P10 -I{} git -C {} pull'
alias cor='ls | xargs -P10 -I{} git -C {} co main'
alias ll='ls -l -h --color'
alias la='ll -a'
alias c=clear
alias cs='cscope -b -q -k'
alias bathelp='bat --plain --language=help'

export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export XKB_DEFAULT_LAYOUT=us

export EDITOR=vim

export NPM_CONFIG_PREFIX=$HOME/.npm-global

. "$HOME/.cargo/env"
export PATH=$PATH:$NPM_CONFIG_PREFIX/bin
export PATH=$PATH:$HOME/.config/git-commands
export PATH=$PATH:$HOME/.local/bin

. <(rustup completions bash)
. <(rustup completions bash cargo)

export GPG_TTY=$(tty)

eval $(keychain --eval --agents ssh -Q --quiet ~/.ssh/id_moeryomenko)
eval $(keychain --eval --agents gpg --quiet --gpg2 BDEFC42C5E88B8C5)

if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
       export GDK_BACKEND=wayland
       exec sway
fi

# BEGIN_KITTY_SHELL_INTEGRATION
if test -n "$KITTY_INSTALLATION_DIR" -a -e "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; then source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"; fi
# END_KITTY_SHELL_INTEGRATION
