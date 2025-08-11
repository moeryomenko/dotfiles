#!/bin/bash

battery_path="/sys/class/power_supply/BAT0"
if [ -d "$battery_path" ]; then
    capacity=$(cat "$battery_path/capacity" 2>/dev/null)
    status=$(cat "$battery_path/status" 2>/dev/null)

    case $status in
        "Charging") icon="󰂄" ;;
        "Discharging") icon="󰂁" ;;
        "Full") icon="󰁹" ;;
        *) icon="⚡" ;;
    esac

    echo "$icon ${capacity}%"
else
    echo "No battery"
fi
