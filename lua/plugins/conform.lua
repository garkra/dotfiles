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
		formatters = {
			oxfmt = {
				-- The standalone TODO files live at ~/.todo*.md and have no config of
				-- their own, so oxfmt resolves its config from nvim's cwd. Launched from
				-- a project like techcyte-frontend, it picks up that repo's .oxfmtrc.json
				-- (tabWidth 4) and reflows the list to 4-space nesting — which then clashes
				-- with the 2-space note bullets that <leader>n inserts. Pin these files to
				-- $HOME (no .oxfmtrc.json there) so they always format with oxfmt's 2-space
				-- defaults, independent of where nvim was started.
				cwd = function(_, ctx)
					local home = vim.fn.expand("~")
					if ctx.filename:match("^" .. vim.pesc(home) .. "/%.todo[%w%-]*%.md$") then
						return home
					end
					return nil
				end,
			},
		},
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
