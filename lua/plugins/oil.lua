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
		columns = {
			"icon",
			{ "mtime", format = "%Y-%m-%d %H:%M" },
		},
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
			-- Toggle between sorting by name and by modification time
			["<leader>st"] = {
				callback = function()
					local oil = require("oil")
					_G.oil_sort_by_mtime = not _G.oil_sort_by_mtime
					if _G.oil_sort_by_mtime then
						oil.set_sort({ { "type", "asc" }, { "mtime", "desc" } })
						vim.notify("Oil: sorting by mtime (newest first)", vim.log.levels.INFO)
					else
						oil.set_sort({ { "type", "asc" }, { "name", "asc" } })
						vim.notify("Oil: sorting by name", vim.log.levels.INFO)
					end
				end,
				desc = "Toggle oil sort (name / mtime)",
			},
		},
		view_options = {
			show_hidden = true,
			-- Default sort: directories first, then newest-modified files first
			sort = {
				{ "type", "asc" },
				{ "mtime", "desc" },
			},
		},
		preview_win = {
			update_on_cursor_moved = true,
		},
	},
}
