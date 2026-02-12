return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"gopls",
				"pyright",
				"rust_analyzer",
				"eslint",
			},
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
				},
			},
		})

		vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "pyright", "rust_analyzer", "eslint" })

		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
		vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "single" })

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(ev)
				local opts = { buffer = ev.buf, remap = false }
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)
				vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, opts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
				vim.keymap.set("n", "<leader>rr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
			end,
		})
	end,
}
