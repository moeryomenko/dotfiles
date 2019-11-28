alias g=git
alias c=clear
alias gwds="ydiff -s -c always -w 0"

set -x GDK_BACKEND wayland

if test (tty) = /dev/tty1
	exec sway
end
