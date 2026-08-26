return {
	"kylechui/nvim-surround",
	lazy = false,
	config = function()
		require("nvim-surround").setup({
			surrounds = {
				HTML = {
					["t"] = "type", -- Change just the tag type
					["T"] = "whole", -- Change the whole tag contents
				},
				aliases = {
					["a"] = ">", -- Single character aliases apply everywhere
					["b"] = ")",
					["B"] = "}",
					["r"] = "]",
					-- Table aliases only apply for changes/deletions
					["q"] = { '"', "'", "`" }, -- Any quote character
					["s"] = { ")", "]", "}", ">", "'", '"', "`" }, -- Any surrounding delimiter
				},
			},
			highlight = { -- Highlight before inserting/changing surrounds
				duration = 2,
			},
		})
	end,
}
