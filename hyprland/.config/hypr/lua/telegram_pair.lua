local TELEGRAM_CLASS = "org.telegram.desktop"

local function isTelegram(win)
	return win.class == TELEGRAM_CLASS
end

local function columnWidth(win)
	local layout = win.layout
	if not layout or not layout.column then
		return nil
	end
	return layout.column.width
end

local function containsWindow(list, win)
	for _, w in ipairs(list) do
		if w.address == win.address then
			return true
		end
	end
	return false
end

local function fitTelegramPairs(restore)
	local wasActive = hl.get_active_window()

	local byWorkspace = {}
	for _, win in ipairs(hl.get_windows()) do
		if not win.floating and win.workspace then
			local key = win.workspace.id
			byWorkspace[key] = byWorkspace[key] or {}
			byWorkspace[key][#byWorkspace[key] + 1] = win
		end
	end

	local resized = {}
	for _, wins in pairs(byWorkspace) do
		if #wins == 2 then
			local telegram, other
			for _, win in ipairs(wins) do
				if isTelegram(win) then
					telegram = win
				else
					other = win
				end
			end
			if telegram and other then
				local width = columnWidth(other)
				if not width or math.abs(width - 0.75) > 0.01 then
					hl.dispatch(hl.dsp.focus({ window = other }))
					hl.dispatch(hl.dsp.layout("colresize 0.75"))
					resized[#resized + 1] = other
				end
			end
		end
	end

	if #resized > 0 then
		local target = restore
		if not target or containsWindow(resized, target) then
			target = wasActive
		end
		if target and not containsWindow(resized, target) then
			hl.dispatch(hl.dsp.focus({ window = target }))
		end
	end
end

hl.on("window.open", function(win)
	fitTelegramPairs(win)
end)

hl.on("window.destroy", function()
	fitTelegramPairs(nil)
end)

hl.on("config.reloaded", function()
	fitTelegramPairs(hl.get_active_window())
end)