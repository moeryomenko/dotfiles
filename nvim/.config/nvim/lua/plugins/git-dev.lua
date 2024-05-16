return {
	"moyiz/git-dev.nvim",
	cmd = { "GitDevOpen" },
	keys = {
		{
			"<leader>go",
			function()
				local repo = vim.fn.input("Repository name / URI: ")
				if repo ~= "" then
					require("git-dev").open(repo, {}, { read_only = false })
				end
			end,
			desc = "[O]pen a remote git repository",
		},
	},
	opts = {
		cd_type = "tab",
	},
}
