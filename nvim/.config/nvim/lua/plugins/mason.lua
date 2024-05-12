return {
	"williamboman/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
	opts = function(_, _)
		local icons = require("core.icons")
		return {
			PATH = "prepend",
			log_level = vim.log.levels.INFO,
			max_concurrent_installers = 8,
			ui = {
				check_outdated_packages_on_open = true,
				border = "rounded",
				width = 0.8,
				height = 0.8,
				icons = {
					package_installed = icons.ui.Gear,
					package_pending = icons.ui.Download,
					package_uninstalled = icons.ui.Plus,
				},
				keymaps = {
					toggle_package_expand = "<CR>",
					install_package = "i",
					update_package = "u",
					check_package_version = "c",
					update_all_packages = "U",
					check_outdated_packages = "C",
					uninstall_package = "d",
					cancel_installation = "<C-c>",
					apply_language_filter = "<C-f>",
				},
			},
		}
	end,
	config = function(_, opts)
		require("mason").setup(opts)

		-- handle opts.ensure_installed
		local registry = require("mason-registry")
		registry.refresh(function()
			for _, pkg_name in ipairs(opts.ensure_installed) do
				-- print("loading " .. pkg_name)
				local pkg = registry.get_package(pkg_name)
				if not pkg:is_installed() then
					pkg:install()
				end
			end
		end)
	end,
}
