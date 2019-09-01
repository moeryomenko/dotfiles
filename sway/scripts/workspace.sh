#!/usr/bin/bash  

current=$(swaymsg -t get_outputs | jq '.[] | .current_workspace' | sed 's/"//g')
case $1 in
	"right")
		next=$(($current+1))
		if [[ $next == 11 ]]; then next=1; fi;;
	"left")
		next=$(($current-1))
		if [[ $next == 0 ]]; then next=10; fi;;
esac
swaymsg workspace $next
