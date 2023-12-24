local status_ok, hlchunk = pcall(require, "hlchunk")
if not status_ok then
	return
end

hlchunk.setup({
	chunk = {
		enable = true,
		use_treesitter = true,
		chars = {
			horizontal_line = "─",
			vertical_line = "│",
			left_top = "╭",
			left_bottom = "╰",
			right_arrow = ">",
		},
	},
	indent = {
		enable = true,
	},
	line_num = {
		enable = true,
		use_treesitter = true,
	},
	blank = {
		enable = false,
	},
})
