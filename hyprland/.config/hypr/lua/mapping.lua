local vars = require("lua.vars")

-- General
hl.bind(vars.mainMod .. " + Q", hl.dsp.exec_cmd(vars.terminal))
hl.bind(vars.mainMod .. " + C", hl.dsp.window.close())
hl.bind(vars.mainMod .. " + ALT + M", hl.dsp.exec_cmd("exit"))
hl.bind(vars.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(vars.mainMod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(vars.mainMod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle noctalia/notes:panel"))

hl.bind(vars.mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(vars.mainMod .. " + F", hl.dsp.window.fullscreen())

-- Focus
hl.bind(vars.mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(vars.mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(vars.mainMod .. " + k", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(vars.mainMod .. " + j", hl.dsp.focus({ workspace = "e+1" }))

-- Move
hl.bind(vars.mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(vars.mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(vars.mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(vars.mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

-- Logout
hl.bind(vars.mainMod .. " + DELETE", hl.dsp.exec_cmd("wlogout"))

-- Workspaces
for i = 1, 10 do
	local key = i == 10 and 0 or i
	hl.bind(vars.mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(vars.mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special Workspace
hl.bind(vars.mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(vars.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(vars.mainMod .. " + ALT + k", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(vars.mainMod .. " + ALT + j", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse
hl.bind(vars.mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(vars.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Scrolling layout
hl.bind(vars.mainMod .. " + G", hl.dsp.layout("colresize 1"))

-- Screenshots / Screen Recording
-- Screenshots (HyprCapture plugin)
if hl.plugin and hl.plugin.hyprcapture then
	hl.bind("Print", hl.plugin.hyprcapture.open)
end
hl.bind(vars.mainMod .. "+ R", hl.dsp.exec_cmd('noctalia msg plugin noctalia/screen_recorder:service all toggle'))

-- Audio
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),
	{ locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +10%"),
	{ locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -10%"),
	{ locked = true, repeating = true })

-- Hymission Mission Control
hl.bind(vars.mainMod .. " + O", hl.plugin.scrolloverview.overview("toggle all"))

