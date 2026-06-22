return {
	"tpope/vim-fugitive",
	keys = {
		{ "<leader>gs", vim.cmd.Git, desc = "Git status" },
		{ "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
		{
			"<leader>lg",
			function()
				require("util.lazygit").open()
			end,
			desc = "Open lazygit",
		},
	},
}
