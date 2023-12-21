vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.cmd.colorscheme("tokyonight-storm")

--#region himalaya
vim.g.himalaya_folder_picker = "telescope"
vim.g.himalaya_folder_picker_telescope_preview = 1
--#endregion

require("staline").setup({
	defaults = {
		line_column = "[%l/%L] :%c %p%% ",
	},
})

local wilder = require("wilder")
wilder.setup({ modes = { ":", "/", "?" } })
wilder.set_option(
	"renderer",
	wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
		highlights = {
			border = "Normal", -- highlight to use for the border
		},
		reverse = 1,
		border = "rounded",
		left = { " ", wilder.popupmenu_devicons() },
		right = { " ", wilder.popupmenu_scrollbar() },
	}))
)

--#region filetypes autocmd
vim.api.nvim_create_autocmd({
	"BufNewFile",
	"BufRead",
}, {
	pattern = "*.vert,*.tesc,*.tese,*.geom,*.frag,*.comp,*.glsl",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_option(buf, "filetype", "glsl")
	end,
})

vim.api.nvim_create_autocmd({
	"BufNewFile",
	"BufRead",
}, {
	pattern = "*.qml",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_option(buf, "filetype", "qmljs")
	end,
})
--#endregion
