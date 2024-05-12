return {
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = {
			{
				"b0o/SchemaStore.nvim",
				version = false, -- last release is very old
			},
			{
				"williamboman/mason-lspconfig.nvim",
				-- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
				lazy = false,
				dependencies = {
					{
						-- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
						-- see mason.lua for more settings.
						"williamboman/mason.nvim",
						lazy = false,
					},
				},
			},
			"hrsh7th/nvim-cmp",
			{
				"artemave/workspace-diagnostics.nvim",
				enabled = false,
			},
			{
				"j-hui/fidget.nvim",
				enabled = false, -- TODO: figure out how this status shows without fidget
				opts = {},
			},
		},
		opts = {
			servers = {},
		},
		config = function(_, opts)
			require("core.utils").setup_diagnostics()
			local lspconfig = require("lspconfig")

			local client_capabilities = vim.lsp.protocol.make_client_capabilities()
			local completion_capabilities = require("cmp_nvim_lsp").default_capabilities()
			local capabilities = vim.tbl_deep_extend("force", client_capabilities, completion_capabilities)

			local function setup(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, opts.servers[server] or {})

				lspconfig[server].setup(server_opts)
			end

			-- get all the servers that are available through mason-lspconfig
			local mlsp = require("mason-lspconfig")
			local all_mslp_servers = {}
			all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)

			local ensure_installed = {} ---@type string[]
			for server, server_opts in pairs(opts.servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					-- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
					if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
						setup(server)
					else
						ensure_installed[#ensure_installed + 1] = server
					end
				end
			end

			mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
				callback = function(event)
					require("core.keymaps").setup_lsp_keymaps(event)
				end,
			})
		end,
	},
}
