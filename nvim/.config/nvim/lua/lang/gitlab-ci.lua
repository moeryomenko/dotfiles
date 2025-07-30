vim.filetype.add({
	pattern = {
		["%.gitlab%-ci%.ya?ml"] = "yaml.gitlab",
	},
})

return {
	"neovim/nvim-lspconfig",
	ft = "yaml.gitlab",
	opts = {
		external = {
			gitlab_ci_ls = {
				cmd = { "gitlab-ci-ls" },
				filetypes = { "yaml.gitlab" },
				root_dir = function(fname)
					return require("lspconfig.util").find_git_ancestor(fname)
				end,
				single_file_support = true,
			},
		},
	},
}

