#!/usr/bin/env bash

function find_failures {
	journalctl --no-pager --since today \
		--grep 'fail|error|fatal' --output json|jq '._EXE' | \
		sort | uniq -c | sort --numeric --reverse --key 1;
}

# TODO: in progress.
# function tranfer() {
# 	tar --create --directory /home/josevnz/tmp/ --file - *| \
# 		ssh raspberrypi "tar --directory /home/josevnz \
# 		--verbose --list --file -"
# }

function partition_size { lsblk --json | jq -c '.blockdevices[]|[.name,.size]'; }

function files_type { test "$#" -gt 0 && stat --printf "%n: %F\n" "$@"; }

# function git_update {
# 	 for i in */.git; do cd $(dirname $i); git pull; cd ..; done
# }

function gwds { ydiff -s -c always -w 0; }
function fz { sk --preview 'bat --color=always --style=numbers --line-range=:500 {}'; }

function b64d { echo "$1" | base64 -d ; echo ;}

function b64e { echo -n "$1" | base64 ;}

function replace_all { grep -rl $1 . | xargs sed -i "s/$1/$2/g"; }

function check_ping { ping -c 1 -W 3 google.com ;}

function rand_pass { cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 32 | head -n 1 ; }
