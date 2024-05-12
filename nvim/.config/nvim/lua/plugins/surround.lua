return {
	"kylechui/nvim-surround",
	keys = { "cs", "ds", "ys" },
	config = function()
		require("nvim-surround").setup({
			keymaps = { -- vim-surround style keymaps
				-- insert = "ys",
				-- insert_line = "yss",
				visual = "S",
				delete = "ds",
				change = "cs",
			},
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
