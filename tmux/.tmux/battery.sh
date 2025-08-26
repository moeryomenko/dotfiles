#!/bin/bash

if command -v pmset >/dev/null 2>&1; then
    battery_info=$(pmset -g batt | grep -E "\d+%")
    
    if [[ $battery_info =~ ([0-9]+)%\;\ ([^;]+) ]]; then
        capacity="${BASH_REMATCH[1]}"
        status="${BASH_REMATCH[2]}"
        
        case $status in
            "charging") icon="󰂄" ;;
            "discharging") icon="󰂁" ;;
            "finishing charge"|"charged") icon="󰁹" ;;
            *) icon="⚡" ;;
        esac
        
        echo "$icon ${capacity}%"
    else
        echo "No battery"
    fi
else
    echo "No battery"
fi
