return {
	{
		src = "https://github.com/FabijanZulj/blame.nvim",
		config = function()
			local blame = require("blame")

			blame.setup({
				default = blame.virtual_view,
			})
		end,
	},
}
