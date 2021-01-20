#!/usr/bin/env zsh

state=(`echo $(swaymsg -t get_outputs | jq -jr '.[] | .focused," ",.current_workspace," "' | sed 's/"//g'| sed 's/true/1/g' | sed 's/false/0/g') | sed 's/ /\n/g'`)

current=`for i in $(seq 1 2 ${#state[@]}); do
	if [[ $state[$i] == 1 ]]; then
		echo $(($state[$i+1]))
		break
	fi
done`

case $1 in
	"right")
		next=$(($current+1))
		if [[ $next == 11 ]]; then next=1; fi;;
	"left")
		next=$(($current-1))
		if [[ $next == 0 ]]; then next=10; fi;;
esac

swaymsg workspace $next
