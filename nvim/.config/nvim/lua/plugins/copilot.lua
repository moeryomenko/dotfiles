return {
	"zbirenbaum/copilot-cmp",
	event = "InsertEnter",
	config = function()
		require("copilot_cmp").setup()
	end,
	dependencies = {
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		config = function()
			vim.g.copilot_proxy = os.getenv("HTTP_PROXY")
			vim.g.copilot_proxy_strict_ssl = false
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},
}
