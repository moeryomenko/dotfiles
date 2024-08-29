local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

local icons = require("core.icons")

local colors = {
	bg = "#202328",
	fg = "#bbc2cf",
	yellow = "#ECBE7B",
	cyan = "#008080",
	darkblue = "#081633",
	green = "#98be65",
	orange = "#FF8800",
	violet = "#a9a1e1",
	magenta = "#c678dd",
	blue = "#51afef",
	red = "#ec5f67",
}

local conditions = {
	buffer_not_empty = function()
		return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
	end,
	hide_in_width = function()
		return vim.fn.winwidth(0) > 80
	end,
	check_git_workspace = function()
		local filepath = vim.fn.expand("%:p:h")
		local gitdir = vim.fn.finddir(".git", filepath .. ";")
		return gitdir and #gitdir > 0 and #gitdir < #filepath
	end,
}

local searchcount = { "searchcount", color = { fg = colors.fg, gui = "bold" } }
local selectioncount = { "selectioncount", color = { fg = colors.fg, gui = "bold" } }
local progress = { "progress", color = { fg = colors.fg, gui = "bold" } }

local filesize = {
	"filesize",
	color = { fg = colors.fg, gui = "bold" },
	cond = conditions.buffer_not_empty,
}

local filetype = {
	"filetype",
	color = { fg = colors.blue, gui = "bold" },
}

local fileformat = {
	"fileformat",
	icons_enabled = true,
	color = { fg = colors.white, gui = "bold" },
}

local filename = {
	"filename",
	cond = conditions.buffer_not_empty,
	color = { fg = colors.magenta, gui = "bold" },
}

local branch = {
	"branch",
	icon = icons.git.Branch,
	fmt = function(str)
		return str:sub(1, 32)
	end,
	color = { fg = colors.green, gui = "bold" },
}

local diff_icons = {
	"diff",
	symbols = { added = icons.git.AddAlt, modified = icons.git.DiffAlt, removed = icons.git.RemoveAlt },
	diff_color = {
		added = { fg = colors.green },
		modified = { fg = colors.orange },
		removed = { fg = colors.red },
	},
	cond = conditions.hide_in_width,
}

local diagnostics = {
	"diagnostics",
	sources = { "nvim_lsp", "nvim_diagnostic", "nvim_workspace_diagnostic" },
	symbols = {
		error = icons.diagnostics.Error,
		warn = icons.diagnostics.Warning,
		info = icons.diagnostics.Information,
		hint = icons.diagnostics.Hint,
	},
	diagnostics_color = {
		color_error = { fg = colors.red },
		color_warn = { fg = colors.yellow },
		color_info = { fg = colors.blue },
		color_hint = { fg = colors.yellow },
	},
}

local lsp = {
	function()
		local msg = "No LSP"
		local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
		local clients = vim.lsp.get_active_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				return client.name
			end
		end
		return msg
	end,
	icon = icons.ui.Gear,
	color = { fg = colors.fg, gui = "bold" },
}

local encoding = {
	"o:encoding",
	fmt = string.upper,
	cond = conditions.hide_in_width,
	color = { fg = colors.green, gui = "bold" },
}

local separator = {
	function()
		return icons.ui.Separator
	end,
	-- TODO: enable.
	-- color = function()
	--     return { fg = mode_color[vim.fn.mode()] }
	-- end,
	padding = { left = 0, right = 0 },
}

local function mode(icon)
	icon = icon or icons.ui.NeoVim
	return {
		function()
			return icon
		end,
		padding = { left = 1, right = 0 },
	}
end

-- Config
local config = {
	options = {
		-- Disable sections and component separators
		component_separators = "",
		-- section_separators = '',
		theme = "nord",
		disabled_filetypes = {
			"dashboard",
		},
	},
	tabline = {
		lualine_a = {},
		lualine_b = { mode(), { "buffers", use_mode_colors = true } },
		lualine_c = {},
		lualine_x = { diff_icons, branch },
		lualine_y = { searchcount, selectioncount },
		lualine_z = {},
	},
	sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { separator, mode(icons.ui.Heart), "location", progress, filename },
		lualine_x = { diagnostics, lsp, filetype, filesize, fileformat, encoding, separator },
		lualine_y = {},
		lualine_z = {},
	},
}

-- Now don't forget to initialize lualine
lualine.setup(config)
