vim.filetype.add({
	pattern = {
		-- Ansible playbooks
		["playbook%.ya?ml"] = "yaml.ansible",
		["^.*ansible.*%.ya?ml"] = "yaml.ansible",
		["^.*/playbooks/.*%.ya?ml"] = "yaml.ansible",
		["^.*/tasks/.*%.ya?ml"] = "yaml.ansible",
		["^.*/roles/.*%.ya?ml"] = "yaml.ansible",
		["^.*/handlers/.*%.ya?ml"] = "yaml.ansible",
		["^.*/defaults/.*%.ya?ml"] = "yaml.ansible",
		["^.*/group_vars/.*%.ya?ml"] = "yaml.ansible",
		["^.*/host_vars/.*%.ya?ml"] = "yaml.ansible",
	},
})

return {
	{
		"stevearc/conform.nvim",
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "yamlfmt" })
				end,
			},
		},
		ft = { "yaml.ansible" },
		opts = {
			formatters_by_ft = {
				["yaml.ansible"] = { "yamlfmt" },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"williamboman/mason-lspconfig.nvim",
				dependencies = {
					"williamboman/mason.nvim",
				},
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					vim.list_extend(opts.ensure_installed, { "ansiblels" })
				end,
			},
		},
		ft = { "yaml.ansible" },
		opts = {
			servers = {
				ansiblels = {
					filetypes = { "yaml.ansible" },
					settings = {
						ansible = {
							validation = {
								enabled = true,
								lint = {
									enabled = true,
								},
							},
							path = "ansible",
							executionEnvironment = {
								enabled = false,
							},
							python = {
								interpreterPath = "python",
							},
						},
					},
				},
			},
		},
	},
}
