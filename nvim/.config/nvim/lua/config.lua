vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.cmd.colorscheme("tokyonight-storm")

vim.opt.shell = "bash"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wildmenu = true
vim.opt.cursorline = true
vim.opt.encoding = "utf8"

vim.cmd([[set backspace=indent,eol,start]])
vim.cmd([[set tw=120 cc=+1]])
vim.cmd([[au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us]])
vim.cmd([[au FileType c,cpp setlocal tw=80 cc=+1]])

--#region line number settings.
vim.opt.number = true
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
	callback = function()
		vim.opt.relativenumber = true
	end,
})
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
	callback = function()
		vim.opt.relativenumber = false
	end,
})
--#endregion

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
