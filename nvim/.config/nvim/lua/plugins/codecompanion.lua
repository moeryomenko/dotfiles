local prefix = "<leader>a"
local load_secret = require("core.functions").load_secret
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
		"ravitemer/codecompanion-history.nvim",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
		"nvim-telescope/telescope.nvim", -- Optional: For using slash commands
		"zbirenbaum/copilot.lua",
		{ "echasnovski/mini.nvim", version = "*" },
	},
	cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionToggle", "CodeCompanionAdd", "CodeCompanionChat" },
	opts = {
		extensions = {
			history = {
				enabled = true,
				opts = {
					keymap = "gh",
					save_chat_keymap = "sc",
					auto_save = false,
					auto_generate_title = true,
					continue_last_chat = false,
					delete_on_clearing_chat = false,
					picker = "snacks",
					enable_logging = false,
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
				},
			},
		},
		adapters = {
			anthropic = function()
				return require("codecompanion.adapters").extend("anthropic", {
					name = "anthropic",
					env = {
						api_key = load_secret("anthropic/dev-key"),
					},
				})
			end,
			opts = {
				-- proxy = string.gsub(tostring(os.getenv("COPILOT_PROXY_URL")), "https", "http"),
				allow_insecure = false, -- Allow insecure connections
			},
		},
		strategies = {
			chat = {
				adapter = {
					name = "copilot",
					model = "claude-3.7-sonnet",
				},
				roles = {
					llm = "  CodeCompanion",
					user = " " .. user:sub(1, 1):upper() .. user:sub(2),
				},
				keymaps = {
					close = { modes = { n = "q", i = "<C-c>" } },
					stop = { modes = { n = "<C-c>" } },
				},
				tools = {
					["next_edit_suggestion"] = {
						opts = {
							--- the default is to open in a new tab, and reuse existing tabs
							--- where possible
							---@type string|fun(path: string):integer?
							jump_action = "tabnew",
						},
					},
				},
			},
			inline = {
				adapter = {
					name = "copilot",
					model = "claude-3.7-sonnet",
				},
			},
			agent = {
				adapter = {
					name = "copilot",
					model = "claude-3.7-sonnet",
				},
			},
		},
		display = {
			chat = {
				show_settings = true,
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
