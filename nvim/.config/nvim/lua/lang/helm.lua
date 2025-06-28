return {
	"qvalentin/helm-ls.nvim",
	ft = "helm",
	dependencies = {
		{
			"neovim/nvim-lspconfig",
			opts = {
				servers = {
					helm_ls = {
						settings = {
							["helm-ls"] = {
								yamlls = {
									path = vim.fn.stdpath("data") .. "/mason/bin/yaml-language-server",
								},
							},
						},
					},
				},
			},
		},
	},
	opts = {
		conceal_templates = {
			-- enable the replacement of templates with virtual text of their current values
			enabled = true, -- tree-sitter must be setup for this feature
		},
		indent_hints = {
			-- enable hints for indent and nindent functions
			enabled = true, -- tree-sitter must be setup for this feature
		},
	},
}
