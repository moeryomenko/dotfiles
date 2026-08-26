local function start_hyprsunset()
	hl.exec_cmd("killall hyprsunset 2>/dev/null; sleep 0.5; nohup hyprsunset > /dev/null 2>&1 &")
end

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("sleep 0.5 && awww restore")  -- restore last set wallpaper	hl.exec_cmd("systemctl --user enable --now tide-island.service")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	start_hyprsunset()
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("~/.config/hypr/bin/xdg-portal.sh")
end)

hl.on("config.reloaded", function()
	start_hyprsunset()
end)
