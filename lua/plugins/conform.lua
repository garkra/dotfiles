return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format()
			end,
			desc = "Format buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			typescript = { "oxfmt" },
			typescriptreact = { "oxfmt" },
			javascript = { "oxfmt" },
			javascriptreact = { "oxfmt" },
			json = { "oxfmt" },
			jsonc = { "oxfmt" },
			markdown = { "oxfmt" },
			yaml = { "oxfmt" },
			css = { "oxfmt" },
			graphql = { "oxfmt" },
			go = { "gofmt" },
			python = {},
			rust = { "rustfmt" },
			c = { "clang-format" },
			cpp = { "clang-format" },
		},
format_on_save = {
			timeout_ms = 3000,
			lsp_format = "fallback",
		},
	},
}
