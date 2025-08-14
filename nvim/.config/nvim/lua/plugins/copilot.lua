local load_secret = require("core.functions").load_secret

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
			vim.g.copilot_proxy = load_secret("copilot/proxy")
			vim.g.copilot_proxy_strict_ssl = false
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end,
	},
}
