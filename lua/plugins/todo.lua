local todo_file = vim.fn.expand("~/.todo.md")
local todo_buf = nil
local todo_win = nil

local function close_todo()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		if todo_buf and vim.api.nvim_buf_is_valid(todo_buf) and vim.bo[todo_buf].modified then
			vim.api.nvim_buf_call(todo_buf, function() vim.cmd("write") end)
		end
		vim.api.nvim_win_close(todo_win, true)
		todo_win = nil
	end
end

local function toggle_todo()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		close_todo()
		return
	end

	-- Create the file if it doesn't exist
	if vim.fn.filereadable(todo_file) == 0 then
		vim.fn.writefile({ "# TODO", "" }, todo_file)
	end

	-- Create or reuse the buffer
	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		todo_buf = vim.fn.bufadd(todo_file)
		vim.fn.bufload(todo_buf)
		vim.bo[todo_buf].buflisted = false
	end

	-- Open a centered floating window
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.7)
	todo_win = vim.api.nvim_open_win(todo_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		border = "rounded",
		title = " TODO ",
		title_pos = "center",
	})

	-- q saves and closes from normal mode
	vim.keymap.set("n", "q", close_todo, { buffer = todo_buf, desc = "Close TODO" })

	-- Mark done: [x] with date
	vim.keymap.set("n", "<leader>x", function()
		local line = vim.api.nvim_get_current_line()
		local date = os.date("%Y-%m-%d")
		-- Replace [ ] or [~] with [x] and insert date after the checkbox
		local new = line:gsub("%[([ ~])%]", function()
			return "[x]"
		end)
		-- Remove existing date if present, then add current date
		new = new:gsub("%[x%]%s*%d%d%d%d%-%d%d%-%d%d%s*", "[x] " .. date .. " ")
		if not new:find("%[x%]%s*%d") then
			new = new:gsub("%[x%]%s*", "[x] " .. date .. " ")
		end
		vim.api.nvim_set_current_line(new)
	end, { buffer = todo_buf, desc = "Mark TODO done" })

	-- Mark in-progress: [~]
	vim.keymap.set("n", "<leader>~", function()
		local line = vim.api.nvim_get_current_line()
		local new = line:gsub("%[([x ])%]", "[~]")
		-- Remove date if present
		new = new:gsub("%[~%]%s*%d%d%d%d%-%d%d%-%d%d%s*", "[~] ")
		vim.api.nvim_set_current_line(new)
	end, { buffer = todo_buf, desc = "Mark TODO in-progress" })

	-- Uncheck: [ ]
	vim.keymap.set("n", "<leader><BS>", function()
		local line = vim.api.nvim_get_current_line()
		local new = line:gsub("%[([x~])%]", "[ ]")
		-- Remove date if present
		new = new:gsub("%[ %]%s*%d%d%d%d%-%d%d%-%d%d%s*", "[ ] ")
		vim.api.nvim_set_current_line(new)
	end, { buffer = todo_buf, desc = "Uncheck TODO" })

end

vim.keymap.set("n", "<leader>td", toggle_todo, { desc = "Toggle TODO" })

return {}
