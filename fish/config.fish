alias g=git
alias c=clear
alias l=ll
alias gwds="ydiff -s -c always -w 0"

set -x GDK_BACKEND wayland
set -x XKB_DEFAULT_LAYOUT us

set -x GOPATH $HOME/go
set -x GO111MODULE on
set -x NPM_CONFIG_PREFIX $HOME/.npm-global

set -x PATH $PATH:$GOPATH/bin:$NPM_CONFIG_PREFIX/bin:$HOME/.local/bin:$HOME/.local/git-fuzzy/bin
set -x PATH $PATH:$HOME/.local/jdk/bin:$HOME/flutter/bin
set -x JAVA_HOME $HOME/.local/jdk

set GPG_TTY (tty)


function delete-branches
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="git log {} --" |
    xargs --no-run-if-empty git branch --delete --force
end

function pr-checkout
  set -l jq_template '"'\
'#\(.number) - \(.title)'\
'\t'\
'Author: \(.user.login)\n'\
'Created: \(.created_at)\n'\
'Updated: \(.updated_at)\n\n'\
'\(.body)'\
'"'

  set -l pr_number (
    gh api 'repos/:owner/:repo/pulls' |
    jq ".[] | $jq_template" |
    sed -e 's/"\(.*\)"/\1/' -e 's/\\\\t/\t/' |
    fzf \
      --with-nth=1 \
      --delimiter='\t' \
      --preview='echo -e {2}' \
      --preview-window=top:wrap |
    sed 's/^#\([0-9]\+\).*/\1/'
  )

  if [ -n "$pr_number" ]
    gh pr checkout "$pr_number"
  end
end

if test (tty) = /dev/tty1
	exec sway
end

source ~/.asdf/asdf.fish
