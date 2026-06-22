-- When a program inside a Neovim terminal (e.g. lazygit's `e`) runs $EDITOR,
-- flatten intercepts the nested nvim and opens the file in THIS session instead
-- of nesting a new instance. Requires $EDITOR=nvim (the default here).
return {
	"willothy/flatten.nvim",
	lazy = false,
	-- Load before anything that might spawn a nested nvim.
	priority = 1001,
	opts = {
		window = { open = "alternate" },
		hooks = {
			post_open = function(ctx)
				local lazygit = require("util.lazygit")
				if ctx.is_blocking then
					-- Commit message etc.: lazygit must stay alive and blocked,
					-- so just get its float out of the way.
					lazygit.hide()
				else
					-- `e` on a file: close lazygit entirely and leave us in this
					-- session with the file open. No auto-reopen.
					lazygit.kill()
				end
			end,
			block_end = function()
				-- Only fires for blocking edits (commit messages); bring lazygit
				-- back so it can finish the operation it was waiting on.
				vim.schedule(function()
					require("util.lazygit").show()
				end)
			end,
		},
	},
}
