return {
	"harrisoncramer/gitlab.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
	},
	build = function()
		require("gitlab.server").build()
	end,
	config = function()
		local gitlab = require("gitlab")
		vim.keymap.set("n", "glb", gitlab.choose_merge_request)
		vim.keymap.set("n", "gls", gitlab.summary)
		vim.keymap.set("n", "glr", gitlab.review)
		vim.keymap.set("n", "glo", gitlab.open_in_browser)
		vim.keymap.set("n", "glA", gitlab.approve)
		vim.keymap.set("n", "glR", gitlab.revoke)
		vim.keymap.set("n", "glc", gitlab.create_comment)
		vim.keymap.set("v", "glc", gitlab.create_multiline_comment)
		vim.keymap.set("n", "gln", gitlab.create_note)
		vim.keymap.set("v", "gln", gitlab.create_comment_suggestion)
		vim.keymap.set("n", "gld", gitlab.toggle_discussions)
		vim.keymap.set("n", "glaa", gitlab.add_assignee)
		vim.keymap.set("n", "glad", gitlab.delete_assignee)
		vim.keymap.set("n", "glra", gitlab.add_reviewer)
		vim.keymap.set("n", "glrd", gitlab.delete_reviewer)
		vim.keymap.set("n", "glp", gitlab.pipeline)
		vim.keymap.set("n", "glm", gitlab.move_to_discussion_tree_from_diagnostic)
		vim.keymap.set("n", "glM", gitlab.merge)
		vim.keymap.set("n", "glO", gitlab.create_mr)
		vim.keymap.set("n", "glal", gitlab.add_label)
		vim.keymap.set("n", "gldl", gitlab.delete_label)
		vim.keymap.set("n", "glu", gitlab.copy_mr_url)

		gitlab.setup({
			debug = { go_request = true, go_response = true },
			reviewer_settings = {
				diffview = {
					imply_local = true, -- If true, will attempt to use --imply_local option when calling |:DiffviewOpen|
				},
			},
			popup = {
				temporary_registers = { '"', "+", "g" },
			},
			create_mr = {
				target = "main",
				template_file = "default.md",
				squash = true,
				delete_branch = true,
			},
			discussion_signs = {
				severity = vim.diagnostic.severity.WARN,
			},
			discussion_tree = {
				position = "bottom",
				tree_type = "simple",
			},
		})
	end,
}
