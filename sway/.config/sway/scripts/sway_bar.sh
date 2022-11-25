#!/usr/bin/bash

# Battery or charger
battery_charge=$(upower --show-info $(upower --enumerate | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//g')
battery_status=$(upower --show-info $(upower --enumerate | grep 'BAT') | grep -E "state" | awk '{print $2}')

#"CPUs ${freq_g 1}GHz - ${cpu cpu1}% : ${freq_g 2}GHz - ${cpu cpu2}% : ${freq_g 3}GHz - ${cpu cpu3}% : ${freq_g 4}GHz - ${cpu cpu4}% | "..
#"${addr wlp1s0} ${color red}↑${color}${upspeed wlp1s0} ${color green}↓${color}${downspeed wlp1s0} | $time"
# Audio
audio_volume=$(amixer sget 'Master' | grep -e '[0-9][0-9]%' | head -1 | awk '{print $5}' | tr -d '[]')
audio_is_muted=$(amixer sget 'Master' | grep -e '[0-9][0-9]%' | head -1 | awk '{print $6}' | tr -d '[]')

# Others
language=$(swaymsg -r -t get_inputs | awk '/1:1:AT_Translated_Set_2_keyboard/;/xkb_active_layout_name/' | grep -A1 '\b1:1:AT_Translated_Set_2_keyboard\b' | grep "xkb_active_layout_name" | awk -F '"' '{print $4}')

#weather=$(curl -Ss 'https://wttr.in/Krasnodar?0&T&Q&format=1')

if [ $battery_status = "discharging" && $battery_charge < 10 ];
then
	battery_pluggedin='⚠'
else
	battery_pluggedin='⚡'
fi

if [ $audio_is_muted = "off" ];
then
    audio_active='🔇'
else
    audio_active='🔊'
fi

echo "⌨ $language | $audio_active $audio_volume | $battery_pluggedin $battery_charge% "
