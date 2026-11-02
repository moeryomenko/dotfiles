#!/bin/bash

# Volume display for the tmux status bar: icon by level plus the value.
#
#   mute        -> 
#   0-40%       -> 
#   41-90%      -> 
#   91-100%     -> 
#
# Reads the macOS volume state in one osascript call. Prints nothing when the
# volume cannot be read (no CoreAudio, unknown output device, etc.).

settings=$(osascript -e 'get volume settings' 2>/dev/null)

if [[ $settings =~ output\ volume:[[:space:]]*([0-9]+) ]]; then
    volume="${BASH_REMATCH[1]}"
    muted=""

    if [[ $settings =~ output\ muted:[[:space:]]*(true|false) ]]; then
        muted="${BASH_REMATCH[1]}"
    fi

    if [[ $muted == "true" || $volume -eq 0 ]]; then
        icon=""
    elif (( volume <= 40 )); then
        icon=""
    elif (( volume <= 90 )); then
        icon=""
    else
        icon=""
    fi

    echo "${icon} ${volume}%"
fi
