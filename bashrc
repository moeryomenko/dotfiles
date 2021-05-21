if [ -f /etc/bashrc ]; then
        source /etc/bashrc
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

source $HOME/.config/bash-prompt

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

alias g=git
alias ll='ls -l --color=always'
alias la='ll -a'
alias gwds='ydiff -s -c always -w 0'
alias fz="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"

export GDK_BACKEND=wayland
export XKB_DEFAULT_LAYOUT=us

export GOPATH=$HOME/go
export GO111MODULE=on
export NPM_CONFIG_PREFIX=$HOME/.npm-global

export PATH=$PATH:$GOPATH/bin:$NPM_CONFIG_PREFIX/bin:$HOME/.local/bin:$HOME/.local/git-fuzzy/bin
export PATH=$PATH:$HOME/.local/jdk/bin:$HOME/flutter/bin
export JAVA_HOME=$HOME/.local/jdk

export GPG_TTY=$(tty)

eval $(keychain --eval --agents ssh -Q --quiet ~/.ssh/id_moeryomenko)
eval $(keychain --eval --agents gpg --quiet --gpg2 15AE73521DFBFAED)

if [ ! -e $HOME/.asdf ]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0
fi
source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash

if [ -z $DISPLAY ] && [ $(tty) = /dev/tty1 ]; then
        exec sway
fi
