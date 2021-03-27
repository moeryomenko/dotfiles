# Filename:      /etc/skel/.zshrc
# Purpose:       config file for zsh (z shell)
# Authors:       (c) grml-team (grml.org)
# Bug-Reports:   see http://grml.org/bugs/
# License:       This file is licensed under the GPL v2 or any later version.
################################################################################
# Nowadays, grml's zsh setup lives in only *one* zshrc file.
# That is the global one: /etc/zsh/zshrc (from grml-etc-core).
# It is best to leave *this* file untouched and do personal changes to
# your zsh setup via ${HOME}/.zshrc.local which is loaded at the end of
# the global zshrc.
#
# That way, we enable people on other operating systems to use our
# setup, too, just by copying our global zshrc to their ${HOME}/.zshrc.
# Adjustments would still go to the .zshrc.local file.
################################################################################

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
	export GDK_BACKEND=wayland
	XKB_DEFAULT_LAYOUT=us exec sway
fi

export GOPATH=$HOME/go
export NPM_CONFIG_PREFIX=$HOME/.npm-global
export PATH=$PATH:$GOPATH/bin:$NPM_CONFIG_PREFIX/bin:/opt/gradle/bin:$HOME/.local/bin

export GPG_TTY=$(tty)

alias g=git
alias c=clear
alias k=kubectl

# fast checkout with save current work.
alias gfc='g stash; g switch'
# fast return to previos works.
alias grw='f(){g switch $1; g stash pop};f'

alias gwds="ydiff -s -c always -w 0"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# install:
#      git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0
if [ -e "$HOME/.asdf" ]; then
	. $HOME/.asdf/asdf.sh
	# append completions to fpath
	fpath=(${ASDF_DIR}/completions $fpath)
	# initialise completions with ZSH's compinit
	autoload -Uz compinit
	compinit
fi

eval $(keychain --eval --agents ssh -Q --quiet ~/.ssh/id_moeryomenko)
eval $(keychain --eval --agents gpg --quiet --gpg2 15AE73521DFBFAED)

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /home/maxer/.local/bin/terraform terraform

source <(kubectl completion zsh)
source <(kind completion zsh)
