return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "<leader>pv", "<cmd>Oil<cr>", desc = "Open file explorer" },
		{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
	},
	opts = {
		default_file_explorer = true,
		view_options = {
			show_hidden = true,
		},
		preview_win = {
			update_on_cursor_moved = true,
		},
	},
}
