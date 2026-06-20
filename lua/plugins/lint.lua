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
				local lint = require("lint")
				-- Only run linters whose binary is actually on PATH, so projects
				-- without oxlint installed don't throw ENOENT on every save.
				local names = lint.linters_by_ft[vim.bo.filetype] or {}
				local available = vim.tbl_filter(function(name)
					return vim.fn.executable(name) == 1
				end, names)
				if #available > 0 then
					lint.try_lint(available)
				end
			end,
		})
	end,
}
