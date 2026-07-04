#!/usr/bin/env bash
# Screen recording helper using wl-screenrec with wofi selection menu.
# Usage:
#   screen-record.sh           # open wofi menu to select recording mode
#   screen-record.sh stop      # stop recording directly (for keybinding)
#   screen-record.sh status    # check if recording is active

set -euo pipefail

OUTPUT_DIR="$HOME/videos/screencast"
mkdir -p "$OUTPUT_DIR"

is_recording() {
	pgrep -x wl-screenrec > /dev/null 2>&1
}

output_file() {
	echo "$OUTPUT_DIR/recording_$(date +"%Y-%m-%d_%H:%M:%S").mp4"
}

notify() {
	notify-send -a "Screen Record" "$1" "$2"
}

select_monitor() {
	hyprctl monitors | awk '/^Monitor /{print $2}' | \
		wofi --dmenu --prompt "Select Monitor" --width 300 --height 150
}

if [[ $# -eq 0 ]]; then
	if is_recording; then
		options="Record Region\nRecord Fullscreen\nRecord Region with Audio\nRecord Fullscreen with Audio\nStop Recording (active)"
	else
		options="Record Region\nRecord Fullscreen\nRecord Region with Audio\nRecord Fullscreen with Audio"
	fi

	choice=$(printf "%b" "$options" | wofi --dmenu --prompt "Screen Recording" --width 350 --height 250)

	case "$choice" in
		"Record Region")
			wl-screenrec -g "$(slurp)" -f "$(output_file)" &
			notify "Started" "Region recording"
			;;
		"Record Fullscreen")
			monitor=$(select_monitor)
			[[ -z "$monitor" ]] && exit 0
			wl-screenrec -o "$monitor" -f "$(output_file)" &
			notify "Started" "Fullscreen recording on $monitor"
			;;
		"Record Region with Audio")
			wl-screenrec --audio -g "$(slurp)" -f "$(output_file)" &
			notify "Started" "Region recording with audio"
			;;
		"Record Fullscreen with Audio")
			monitor=$(select_monitor)
			[[ -z "$monitor" ]] && exit 0
			wl-screenrec --audio -o "$monitor" -f "$(output_file)" &
			notify "Started" "Fullscreen recording with audio on $monitor"
			;;
		"Stop Recording (active)")
			killall -s SIGINT wl-screenrec 2>/dev/null && \
				notify "Stopped" "Recording saved to $OUTPUT_DIR" || \
				notify "Error" "No active recording found"
			;;
	esac
else
	case "${1:-}" in
		stop)
			killall -s SIGINT wl-screenrec 2>/dev/null && \
				notify "Stopped" "Recording saved to $OUTPUT_DIR" || \
				notify "Error" "No active recording found"
			;;
		status)
			if is_recording; then
				notify "Status" "Recording is active"
			else
				notify "Status" "No active recording"
			fi
			;;
		*)
			echo "Usage: $0 [stop|status]"
			exit 1
			;;
	esac
fi
