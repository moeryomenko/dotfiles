#!/usr/bin/env bash

while true; do
	PID=`pidof swaybg`
	swaybg -i `find $HOME/pictures/wallpapers/ -type f | shuf -n1` -m fill &
	sleep 1
	kill $PID
	sleep 30
done

# mpvpaper -vs -o "--loop-file=inf --volume=40" HDMI-A-1 ~/videos/dark_forest_rainy_sci-fi_ambient.mp4
# mpvpaper -o "--volume=30" -v HDMI-A-1 ~/videos/dark_outpost_2.mkv &
# mpvpaper -o "--volume=0" -v DP-1 ~/videos/dark_outpost_2.mkv &
