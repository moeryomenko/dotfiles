local prefix = "<leader>a"
local user = vim.env.USER or "User"

vim.api.nvim_create_autocmd("User", {
	pattern = "CodeCompanionChatAdapter",
	callback = function(args)
		if args.data.adapter == nil or vim.tbl_isempty(args.data) then
			return
		end
		vim.g.llm_name = args.data.adapter.name
	end,
})

return {
	"olimorris/codecompanion.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
		"nvim-telescope/telescope.nvim", -- Optional: For using slash commands
	},
	cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionToggle", "CodeCompanionAdd", "CodeCompanionChat" },
	opts = {
		adapters = {
			qwen2 = function()
				return require("codecompanion.adapters").extend("ollama", {
					name = "qwen2",
					schema = {
						model = {
							default = "qwen2.5-coder:32b",
						},
					},
				})
			end,
		},
		strategies = {
			chat = {
				adapter = "qwen2",
				roles = {
					llm = "  CodeCompanion",
					user = " " .. user:sub(1, 1):upper() .. user:sub(2),
				},
				keymaps = {
					close = { modes = { n = "q", i = "<C-c>" } },
					stop = { modes = { n = "<C-c>" } },
				},
			},
			inline = { adapter = "qwen2" },
			agent = { adapter = "qwen2" },
		},
		display = {
			chat = {
				show_settings = true,
			},
		},
	},
	keys = {
		{ prefix .. "a", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Action Palette" },
		{ prefix .. "c", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "New Chat" },
		{ prefix .. "A", "<cmd>CodeCompanionAdd<cr>", mode = "v", desc = "Add Code" },
		{ prefix .. "i", "<cmd>CodeCompanion<cr>", mode = "n", desc = "Inline Prompt" },
		{ prefix .. "C", "<cmd>CodeCompanionToggle<cr>", mode = "n", desc = "Toggle Chat" },
	},
}
