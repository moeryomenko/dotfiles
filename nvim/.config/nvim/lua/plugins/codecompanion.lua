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
		{ "echasnovski/mini.nvim", version = "*" },
	},
	cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionToggle", "CodeCompanionAdd", "CodeCompanionChat" },
	opts = {
		adapters = {
			qwen3 = function()
				return require("codecompanion.adapters").extend("ollama", {
					name = "qwen3",
					schema = {
						model = {
							default = "qwen3:14b",
						},
						num_ctx = {
							default = 16384,
						},
					},
				})
			end,
		},
		strategies = {
			chat = {
				adapter = "qwen3",
				roles = {
					llm = "  CodeCompanion",
					user = " " .. user:sub(1, 1):upper() .. user:sub(2),
				},
				keymaps = {
					close = { modes = { n = "q", i = "<C-c>" } },
					stop = { modes = { n = "<C-c>" } },
				},
			},
			inline = { adapter = "qwen3" },
			agent = { adapter = "qwen3" },
		},
		display = {
			chat = {
				show_settings = false,
				diff = {
					enabled = true,
					close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
					layout = "vertical", -- vertical|horizontal split for default provider
					opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
					provider = "mini_diff", -- default|mini_diff
				},
				slash_commands = {
					["file"] = {
						callback = "strategies.chat.slash_commands.file",
						description = "Select a file using Telescope",
						opts = {
							provider = "telescope", -- Other options include 'default', 'mini_pick', 'fzf_lua'
							contains_code = true,
						},
					},
				},
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
