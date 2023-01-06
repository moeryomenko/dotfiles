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
	default_params = { -- Default module parameters with which `neovim.json` will be created.
		cmake = {
			cmd = "cmake", -- CMake executable to use, can be changed using `:Task set_module_param cmake cmd`.
			build_dir = tostring(Path:new("{cwd}", "build")), -- Build directory. The expressions `{cwd}`, `{os}` and `{build_type}` will be expanded with the corresponding text values. Could be a function that return the path to the build directory.
			build_type = "Debug", -- Build type, can be changed using `:Task set_module_param cmake build_type`.
			dap_name = "lldb", -- DAP configuration name from `require('dap').configurations`. If there is no such configuration, a new one with this name as `type` will be created.
			args = { -- Task default arguments.
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
	save_before_run = true, -- If true, all files will be saved before executing a task.
	params_file = "neovim.json", -- JSON file to store module and task parameters.
	quickfix = {
		pos = "botright", -- Default quickfix position.
		height = 12, -- Default height.
	},
	dap_open_command = function()
		return dap.repl.open()
	end, -- Command to run after starting DAP session. You can set it to `false` if you don't want to open anything or `require('dapui').open` if you are using https://github.com/rcarriga/nvim-dap-ui
})
