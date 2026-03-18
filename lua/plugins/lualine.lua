return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "auto",
		},
		sections = {
			lualine_c = {
				"filename",
				{
					function()
						local text = vim.g.todo_active_text
						if not text or text == "" then return "" end
						local prior = vim.g.todo_active_prior_min or 0
						local seg_elapsed = math.floor((os.time() - (vim.g.todo_active_start or os.time())) / 60)
						local total = prior + seg_elapsed
						local h = math.floor(total / 60)
						local m = total % 60
						local dur = h > 0 and string.format("%dh%02dm", h, m) or string.format("%dm", m)
						local max_len = 40
						if #text > max_len then text = text:sub(1, max_len) .. "…" end
						return "⏱ " .. dur .. " " .. text
					end,
					cond = function()
						return vim.g.todo_active_text and vim.g.todo_active_text ~= ""
					end,
				},
			},
		},
		tabline = {
			lualine_a = {
				{
					"tabs",
					mode = 2,
					max_length = vim.o.columns,
					fmt = function(name, context)
						local bufnr = vim.fn.tabpagebuflist(context.tabnr)[vim.fn.tabpagewinnr(context.tabnr)]
						local diags = vim.diagnostic.get(bufnr)
						local errors = #vim.tbl_filter(function(d) return d.severity == vim.diagnostic.severity.ERROR end, diags)
						local warns = #vim.tbl_filter(function(d) return d.severity == vim.diagnostic.severity.WARN end, diags)
						local parts = { name }
						if errors > 0 then table.insert(parts, " " .. errors) end
						if warns > 0 then table.insert(parts, " " .. warns) end
						return table.concat(parts, " ")
					end,
				},
			},
			lualine_z = {},
		},
	},
}
