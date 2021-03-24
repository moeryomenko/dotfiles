alias g=git
alias c=clear
alias gwds="ydiff -s -c always -w 0"

set -x GDK_BACKEND wayland

set -x GOPATH $HOME/go
set -x GO111MODULE on

if test (tty) = /dev/tty1
	exec sway
end

if test -e ~/.asdf/asdf.fish
	source ~/.asdf/asdf.fish
end
