return {
	"FabijanZulj/blame.nvim",
	opts = {},
	cmd = {
		"BlameToggle",
	},
	config = function()
		local blame = require("blame")

		blame.setup({
			default = blame.virtual_view,
		})
	end,
}
