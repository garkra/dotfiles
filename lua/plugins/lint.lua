return {
	"mfussenegger/nvim-lint",
	event = { "BufWritePost", "BufReadPost" },
	config = function()
		require("lint").linters_by_ft = {
			typescript = { "oxlint" },
			typescriptreact = { "oxlint" },
			javascript = { "oxlint" },
			javascriptreact = { "oxlint" },
		}

		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
