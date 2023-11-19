#!/usr/bin/env bash

function find_failures {
	journalctl --no-pager --since today \
		--grep 'fail|error|fatal' --output json | jq '._EXE' |
		sort | uniq -c | sort --numeric --reverse --key 1
}

function pm_pkg_clean {
	sudo pacman -Rncs $(pacman -Qdtq)
}

function pm_cache_clean {
	sudo pacman -Scc
}

function partition_size { lsblk --json | jq -c '.blockdevices[]|[.name,.size]'; }

function files_type { test "$#" -gt 0 && stat --printf "%n: %F\n" "$@"; }

function b64d {
	echo "$1" | base64 -d
	echo
}

function b64e { echo -n "$1" | base64; }

function replace_all { grep -rl $1 . | xargs sed -i "s/$1/$2/g"; }

function rand_pass { cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 32 | head -n 1; }

function cscope_gen {
	find . -regex '.*\.\(c\|h\|cc\|hh\|cpp\|hpp\|hlsl\|glsl\)' > cscope.files
	cscope -b -q -k
	echo "The cscope database is generated"
}

function ex {
	case $1 in
	*.tar.bz2) tar xjf $1 ;;
	*.tar.xz) tar xf $1 ;;
	*.tar.gz) tar xzf $1 ;;
	*.bz2) bunzip2 $1 ;;
	*.gz) gunzip $1 ;;
	*.tar) tar xf $1 ;;
	*.tbz2) tar xjf $1 ;;
	*.tgz) tar xzf $1 ;;
	*.zip) unzip $1 ;;
	*.7z) 7z x $1;;
	esac
}

function compress {
	XZ_OPT=-9 tar cJf $1.tar.xz $1
}
