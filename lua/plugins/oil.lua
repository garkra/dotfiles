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
		keymaps = {
			["<leader>yf"] = {
				callback = function()
					local dir = require("oil").get_current_dir()
					if dir then
						vim.fn.setreg("+", dir)
						vim.notify(dir, vim.log.levels.INFO)
					end
				end,
				desc = "Copy current directory path",
			},
		},
		view_options = {
			show_hidden = true,
		},
		preview_win = {
			update_on_cursor_moved = true,
		},
	},
}
