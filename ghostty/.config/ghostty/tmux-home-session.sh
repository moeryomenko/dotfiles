#!/usr/bin/env bash
set -Eeuo pipefail

session_name="home"
home_window_option="@ghostty_home_window"

tmux_has_session() {
    tmux has-session -t "=${session_name}" 2>/dev/null
}

find_home_window() {
    tmux list-windows -t "=${session_name}" -F "#{window_id} #{${home_window_option}}" \
        | awk '$2 == 1 { print $1; exit }'
}

ensure_home_window() {
    local home_window
    home_window="$(find_home_window)"

    if [[ -z "${home_window}" ]]; then
        home_window="$(tmux new-window -d -P -F "#{window_id}" -t "=${session_name}" -c "${HOME}")"
        tmux set-option -w -t "${home_window}" "${home_window_option}" 1
    fi

    tmux select-window -t "${home_window}"
}

if ! tmux_has_session; then
    if ! tmux new-session -d -s "${session_name}" -c "${HOME}/videos/dark" 2>/dev/null; then
        tmux_has_session || {
            printf 'Unable to create tmux session: %s\n' "${session_name}" >&2
            exit 1
        }
    fi
fi

ensure_home_window
exec tmux attach-session -t "=${session_name}"
