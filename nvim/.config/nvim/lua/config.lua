vim.cmd([[colorscheme nordic]])
vim.cmd([[set shell=bash]])
vim.cmd([[set ts=4 sw=4 ai smarttab wildmenu]])
vim.cmd([[set encoding=utf8]])
vim.cmd([[set nu rnu]])
vim.cmd([[set termguicolors cursorline]])
vim.cmd([[set background=dark]])
vim.cmd([[set backspace=indent,eol,start]])
vim.cmd([[set tw=120 cc=+1]])
vim.cmd([[au FileType gitcommit setlocal tw=72 cc=+1 cc+=51 spell spelllang=en_us]])
vim.cmd([[au FileType c,cpp setlocal tw=80 cc=+1]])
vim.cmd([[au BufNewFile,BufRead *.qml set ft=qmljs]])

vim.cmd([[let g:himalaya_folder_picker = 'telescope']])
vim.cmd([[let g:himalaya_folder_picker_telescope_preview = 1]])

require("evilline")
require("bufferline").setup({})

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
