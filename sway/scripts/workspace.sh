#!/bin/bash

IFS=' ' read -r -a state <<< "`swaymsg -t get_outputs | jq -jr '.[] | .focused," ",.current_workspace," "' | sed 's/"//g'| sed 's/true/1/g' | sed 's/false/0/g' | sed 's/\n/ /g'`"

current=`for i in $(seq 0 2 ${#state[@]}); do
if [[ ${state[$i]} == 1 ]]; then
	((i+=1))
	echo ${state[$i]}
	break
fi
done`

case $1 in
	"right")
		if [ $current == 10 ]; then current=1; else ((current+=1)); fi
		;;
	"left")
		if [ $current == 1 ]; then current=10; else ((current-=1)); fi
		;;
esac

swaymsg workspace $current
