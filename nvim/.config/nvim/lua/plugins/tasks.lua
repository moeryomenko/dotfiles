return {
	"Shatur/neovim-tasks",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "Task",
	config = function()
		local Path = require("plenary.path")

		-- Find ccache executable
		local ccache_path = vim.fn.executable("ccache") == 1 and "ccache" or nil
		if not ccache_path then
			-- Fallback to hardcoded path if ccache is not found in PATH
			ccache_path = "'/usr/bin/ccache'"
		else
			ccache_path = string.format("'%s'", ccache_path)
		end

		local configure_args = {
			"-G",
			"Ninja",
			"-D",
			"CMAKE_EXPORT_COMPILE_COMMANDS=1",
			"-D",
			"CMAKE_C_COMPILER_LAUNCHER=" .. ccache_path,
			"-D",
			"CMAKE_CXX_COMPILER_LAUNCHER=" .. ccache_path,
		}

		-- Add linker flags only on Linux
		if vim.fn.has("linux") == 1 then
			vim.list_extend(configure_args, {
				"-D",
				"CMAKE_EXE_LINKER_FLAGS_INIT='-fuse-ld=mold'",
				"-D",
				"CMAKE_SHARED_LINKER_FLAGS_INIT='-fuse-ld=mold'",
			})
		end

		require("tasks").setup({
			default_params = {
				cmake = {
					cmd = "cmake",
					build_dir = tostring(Path:new("{cwd}", "_build")),
					build_type = "Debug",
					dap_name = "lldb",
					args = {
						configure = configure_args,
					},
				},
			},
			save_before_run = true,
			params_file = "neovim.json",
			dap_open_command = function()
				return require("dap").repl.open()
			end,
		})
	end,
}
