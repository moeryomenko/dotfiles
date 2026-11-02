local TELEGRAM_CLASS = "org.telegram.desktop"
local OTHER_COLUMN_WIDTH = 0.75
local WIDTH_EPSILON = 0.01

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

-- Splits windows into workspace buckets by short `workspace_key`.
local function groupByWorkspace(windows, workspace_key)
	local byWorkspace = {}
	for _, win in ipairs(windows) do
		if not win.floating and win.workspace then
			local key = workspace_key(win)
			byWorkspace[key] = byWorkspace[key] or {}
			byWorkspace[key][#byWorkspace[key] + 1] = win
		end
	end
	return byWorkspace
end

local function splitPair(wins)
	local telegram, other
	for _, win in ipairs(wins) do
		if isTelegram(win) then
			telegram = win
		else
			other = win
		end
	end
	return telegram, other
end

-- Tiled windows whose column has the wrong width, as an ordered list.
local function wrongWidths(byWorkspace)
	local wrong = {}
	for _, wins in pairs(byWorkspace) do
		if #wins == 2 then
			local telegram, other = splitPair(wins)
			if telegram and other then
				local width = columnWidth(other)
				if not width or math.abs(width - OTHER_COLUMN_WIDTH) > WIDTH_EPSILON then
					wrong[#wrong + 1] = other
				end
			end
		end
	end
	return wrong
end

-- Each workspace is addressed by name rather than id: when a workspace is
-- destroyed its LastWindow id is reset to -1, so windows on different
-- workspaces share an id and get grouped together.
local function fitTelegramPairs()
	local focusBefore = hl.get_active_window()

	local byWorkspace = groupByWorkspace(hl.get_windows(), function(win)
		return win.workspace.name
	end)

	local wrong = wrongWidths(byWorkspace)
	if #wrong == 0 then
		return
	end

	-- colresize acts on the focused window's column, which also demands focus.
	for _, win in ipairs(wrong) do
		hl.dispatch(hl.dsp.focus({ window = win }))
		hl.dispatch(hl.dsp.layout("colresize " .. OTHER_COLUMN_WIDTH))
	end

	-- Put focus back where it was; resizing must not steal it.
	if focusBefore and hl.get_active_window() ~= focusBefore then
		hl.dispatch(hl.dsp.focus({ window = focusBefore }))
	end
end

hl.on("window.open", function()
	fitTelegramPairs()
end)

hl.on("window.destroy", function()
	fitTelegramPairs()
end)

hl.on("config.reloaded", function()
	fitTelegramPairs()
end)
