return {
	"ellisonleao/glow.nvim",
	cmd = "Glow",
	config = function()
		require("glow").setup({
			border = "shadow",
			style = "dark",
			pager = false,
			width = 200,
			height = 140,
			width_ratio = 0.7,
			height_ratio = 0.7,
		})
	end,
}
