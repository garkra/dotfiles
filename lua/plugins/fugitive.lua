return {
	"tpope/vim-fugitive",
	keys = {
		{ "<leader>gs", vim.cmd.Git, desc = "Git status" },
		{ "<leader>lg", function()
			local buf = vim.api.nvim_create_buf(false, true)
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = math.floor(vim.o.columns * 0.9),
				height = math.floor(vim.o.lines * 0.9),
				col = math.floor(vim.o.columns * 0.05),
				row = math.floor(vim.o.lines * 0.05),
				style = "minimal",
				border = "rounded",
			})
			vim.fn.termopen("lazygit", {
				on_exit = function()
					if vim.api.nvim_win_is_valid(win) then
						vim.api.nvim_win_close(win, true)
					end
					vim.api.nvim_buf_delete(buf, { force = true })
				end,
			})
			vim.cmd("startinsert")
		end, desc = "Open lazygit" },
	},
}
