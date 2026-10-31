local ui = require("vim._core.ui2")
local api = vim.api

ui.enable({
	enable = true,
	msg = {
		targets = {
			progress = "msg",
		},
	},
})

local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local frame = 0
local message_id
local statusline_progress

local function progress(percent, title, is_running)
	frame = frame % #frames + 1
	statusline_progress = is_running and string.format("%s %s %d%%", frames[frame], title, percent) or nil

	message_id = api.nvim_echo({ { title } }, false, {
		id = message_id,
		percent = percent,
		kind = "progress",
		source = "lsp-progress",
		status = is_running and "running" or "success",
		title = string.format("%s LSP", frames[frame]),
	})
	vim.cmd.redrawstatus()
end

api.nvim_create_autocmd("LspProgress", {
	callback = function(args)
		local value = args.data.params.value
		if not value or not value.title then
			return
		end

		local percent = value.percentage or 0
		if percent > 0 then
			progress(percent, value.title, percent <= 95)
		end
	end,
})

return {
	statusline = function()
		return statusline_progress
	end,
}
