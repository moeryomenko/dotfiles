local dap = require("dap")
dap.adapters.lldb = {
	type = "executable",
	command = "/usr/bin/lldb-vscode", -- adjust as needed, must be absolute path
	env = {
		LLDB_LAUNCH_FLAG_LAUNCH_IN_TTY = "YES",
	},
	name = "lldb",
}
dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
	},
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
dap.configurations.scala = {
	{
		type = "scala",
		request = "launch",
		name = "Run or test with input",
		metals = {
			runType = "runOrTestFile",
			args = function()
				local args_string = vim.fn.input("Arguments: ")
				return vim.split(args_string, " +")
			end,
		},
	},
	{
		type = "scala",
		request = "launch",
		name = "Run or Test",
		metals = {
			runType = "runOrTestFile",
		},
	},
	{
		type = "scala",
		request = "launch",
		name = "Test Target",
		metals = {
			runType = "testTarget",
		},
	},
}

require("metals").setup_dap()

local Path = require("plenary.path")
require("tasks").setup({
	default_params = {
		cmake = {
			cmd = "cmake",
			build_dir = tostring(Path:new("{cwd}", "build")),
			build_type = "Debug",
			dap_name = "lldb",
			args = {
				configure = {
					"-D",
					"CMAKE_EXPORT_COMPILE_COMMANDS=1",
					"-G",
					"Ninja",
					"-D",
					'CMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=mold"',
					"-D",
					'CMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=mold"',
					"-D",
					"CMAKE_C_COMPILER=clang",
					"-D",
					"CMAKE_CXX_COMPILER=clang++",
					"-D",
					"CMAKE_C_COMPILER_LAUNCHER='/usr/bin/ccache'",
					"-D",
					"CMAKE_CXX_COMPILER_LAUNCHER='/usr/bin/ccache'",
				},
			},
		},
	},
	save_before_run = true,
	params_file = "neovim.json",
	quickfix = {
		pos = "botright",
		height = 12,
	},
	dap_open_command = function()
		return require("dapui").open()
	end,
})
