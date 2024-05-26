return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	opts = {
		options = {
			separator_style = "thick",
			mode = "tabs",
			offsets = {
				{
					filetype = "NvimTree",
					text = " File Explorer",
					highlight = "Directory",
					separator = false,
				},
			},
		},
	},
}
