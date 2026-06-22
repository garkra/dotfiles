-- Floating lazygit terminal, exposed as a small module so that flatten.nvim's
-- hooks can hide/kill/reopen the float when lazygit shells out to $EDITOR.
local M = {}

M.buf = nil
M.win = nil

local function win_opts()
	return {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.9),
		height = math.floor(vim.o.lines * 0.9),
		col = math.floor(vim.o.columns * 0.05),
		row = math.floor(vim.o.lines * 0.05),
		style = "minimal",
		border = "rounded",
	}
end

-- Close just the floating window, leaving the lazygit job alive in M.buf.
function M.hide()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, true)
	end
	M.win = nil
end

-- Re-show the still-running lazygit terminal in a fresh float.
function M.show()
	if not (M.buf and vim.api.nvim_buf_is_valid(M.buf)) then
		return M.open()
	end
	M.win = vim.api.nvim_open_win(M.buf, true, win_opts())
	vim.cmd("startinsert")
end

-- Fully terminate lazygit: close the window and kill the terminal job.
function M.kill()
	M.hide()
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		vim.api.nvim_buf_delete(M.buf, { force = true })
	end
	M.buf = nil
end

-- Launch a fresh lazygit in a floating terminal.
function M.open()
	M.kill()
	M.buf = vim.api.nvim_create_buf(false, true)
	M.win = vim.api.nvim_open_win(M.buf, true, win_opts())
	vim.fn.termopen("lazygit", {
		on_exit = function()
			M.kill()
		end,
	})
	vim.cmd("startinsert")
end

return M
