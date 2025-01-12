return {
	{
		"IlyasYOY/obs.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = {
			"ObsNvimFollowLink",
			"ObsNvimRandomNote",
			"ObsNvimNewNote",
			"ObsNvimCopyObsidianLinkToNote",
			"ObsNvimOpenInObsidian",
			"ObsNvimDailyNote",
			"ObsNvimWeeklyNote",
			"ObsNvimRename",
			"ObsNvimTemplate",
			"ObsNvimMove",
			"ObsNvimBacklinks",
			"ObsNvimFindInJournal",
			"ObsNvimFindNote",
			"ObsNvimFindInNotes",
		},
		keys = {
			"<leader>nn",
			"<leader>nr",
			"<leader>nN",
			"<leader>ny",
			"<leader>no",
			"<leader>nd",
			"<leader>nw",
			"<leader>nrn",
			"<leader>nT",
			"<leader>nM",
			"<leader>nb",
			"<leader>nfj",
			"<leader>nff",
			"<leader>nfg",
		},
		config = function()
			local obs = require("obs")

			obs.setup({
				vault_home = "~/.notes",
				vault_name = "Notes",
				journal = {
					daily_template_name = "daily",
					weekly_template_name = "weekly",
				},
			})

			local group = vim.api.nvim_create_augroup("ObsNvim", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter" }, {
				group = group,
				pattern = "*.md",
				desc = "Setup notes nvim-cmp source",
				callback = function()
					if obs.vault:is_current_buffer_in_vault() then
						require("cmp").setup.buffer({
							sources = {
								{ name = "obs" },
								{ name = "luasnip" },
							},
						})
					end
				end,
			})

			vim.keymap.set("n", "<leader>nn", "<cmd>ObsNvimFollowLink<cr>")
			vim.keymap.set("n", "<leader>nr", "<cmd>ObsNvimRandomNote<cr>")
			vim.keymap.set("n", "<leader>nN", "<cmd>ObsNvimNewNote<cr>")
			vim.keymap.set("n", "<leader>ny", "<cmd>ObsNvimCopyObsidianLinkToNote<cr>")
			vim.keymap.set("n", "<leader>no", "<cmd>ObsNvimOpenInObsidian<cr>")
			vim.keymap.set("n", "<leader>nd", "<cmd>ObsNvimDailyNote<cr>")
			vim.keymap.set("n", "<leader>nw", "<cmd>ObsNvimWeeklyNote<cr>")
			vim.keymap.set("n", "<leader>nrn", "<cmd>ObsNvimRename<cr>")
			vim.keymap.set("n", "<leader>nT", "<cmd>ObsNvimTemplate<cr>")
			vim.keymap.set("n", "<leader>nM", "<cmd>ObsNvimMove<cr>")
			vim.keymap.set("n", "<leader>nb", "<cmd>ObsNvimBacklinks<cr>")
			vim.keymap.set("n", "<leader>nfj", "<cmd>ObsNvimFindInJournal<cr>")
			vim.keymap.set("n", "<leader>nff", "<cmd>ObsNvimFindNote<cr>")
			vim.keymap.set("n", "<leader>nfg", "<cmd>ObsNvimFindInNotes<cr>")

			local cmp = require("cmp")
			local cmp_source = require("obs.cmp-source")
			cmp.register_source("obs", cmp_source.new())
		end,
	},
}
