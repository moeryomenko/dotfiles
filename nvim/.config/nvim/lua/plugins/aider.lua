return {
	"GeorgesAlkhouri/nvim-aider",
	cmd = {
		"AiderTerminalToggle",
	},
	keys = {
		{ "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
		{ "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
		{ "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
		{ "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
		{ "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
		{ "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
		{ "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
		-- Example nvim-tree.lua integration if needed
		{ "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
		{ "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
	},
	dependencies = {
		"folke/snacks.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-tree.lua",
	},
	config = function()
		require("nvim_aider").setup({
			args = {
				"--model",
				"ollama_chat/qwen2.5-coder:32b-instruct-fp16",
				"--no-auto-commits",
				"--pretty",
				"--stream",
				"--cache-prompts",
			},
			win = {
				style = "nvim_aider",
				position = "right",
			},
		})
	end,
}
