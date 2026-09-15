return {
	{
		src = "https://github.com/kylechui/nvim-surround",
		config = function()
			require("nvim-surround").setup({
				surrounds = {
					HTML = {
						["t"] = "type",
						["T"] = "whole",
					},
					aliases = {
						["a"] = ">",
						["b"] = ")",
						["B"] = "}",
						["r"] = "]",
						["q"] = { '"', "'", "`" },
						["s"] = { ")", "]", "}", ">", "'", '"', "`" },
					},
				},
				highlight = {
					duration = 2,
				},
			})
		end,
	},
}
