local status_ok, tasks = pcall(require, "tasks")
if not status_ok then
	return
end

local Path = require("plenary.path")

tasks.setup({
	default_params = {
		cmake = {
			cmd = "cmake",
			build_dir = tostring(Path:new("{cwd}", "_build")),
			build_type = "Debug",
			dap_name = "lldb",
			args = {
				configure = {
					"-G",
					"Ninja",
					"-D",
					"CMAKE_EXPORT_COMPILE_COMMANDS=1",
					"-D",
					"CMAKE_C_COMPILER_LAUNCHER='/usr/bin/ccache'",
					"-D",
					"CMAKE_CXX_COMPILER_LAUNCHER='/usr/bin/ccache'",
					"-D",
					"CMAKE_EXE_LINKER_FLAGS_INIT='-fuse-ld=mold'",
					"-D",
					"CMAKE_SHARED_LINKER_FLAGS_INIT='-fuse-ld=mold'",
				},
			},
		},
	},
	save_before_run = true,
	params_file = "neovim.json",
	dap_open_command = function()
		return require("dap").repl.open()
	end,
})
