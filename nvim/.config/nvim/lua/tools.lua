require("mason-tool-installer").setup({
	ensure_installed = {
		"clangd",
		"rust-analyzer",
		"codelldb",
	},
	auto_update = true,
	run_on_start = true,
})

require("mason-null-ls").setup({
	ensure_installed = {
		"cpplint",
		"clang_format",
		"gersemi",
		"gitlint",
		"yamllint",
		"yamlfmt",
	},
	automatic_installation = true,
})

require("mason").setup()

local null_ls = require("null-ls")
local b = null_ls.builtins

local sources = {
	-- formatting
	b.formatting.gersemi,
	b.formatting.clang_format,
	b.formatting.rustfmt,
	b.formatting.nginx_beautifier,
	b.formatting.stylua,
	b.formatting.trim_newlines,
	b.formatting.trim_whitespace,
	b.formatting.yamlfmt,
	-- diagnostics
	b.diagnostics.ltrs,
	b.diagnostics.gitlint,
	b.diagnostics.yamllint,
	-- code actions
	b.code_actions.gitsigns,
	b.code_actions.gitrebase,
	-- hover
	b.hover.dictionary,
}

local async_formatting = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	vim.lsp.buf_request(
		bufnr,
		"textDocument/formatting",
		vim.lsp.util.make_formatting_params({}),
		function(err, res, ctx)
			if err then
				local err_msg = type(err) == "string" and err or err.message
				-- you can modify the log message / level (or ignore it completely)
				vim.notify("formatting: " .. err_msg, vim.log.levels.WARN)
				return
			end

			-- don't apply results if buffer is unloaded or has been modified
			if not vim.api.nvim_buf_is_loaded(bufnr) or vim.api.nvim_buf_get_option(bufnr, "modified") then
				return
			end

			if res then
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				vim.lsp.util.apply_text_edits(res, bufnr, client and client.offset_encoding or "utf-16")
				vim.api.nvim_buf_call(bufnr, function()
					vim.cmd("silent noautocmd update")
				end)
			end
		end
	)
end

null_ls.setup({
	sources = sources,
	debug = false,
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					async_formatting(bufnr)
				end,
			})
		end
	end,
})
