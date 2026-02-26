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
		vim.fn.writefile({
			"<!-- Keybindings (only active in this float): -->",
			"<!-- <leader>a   Add new item to current section -->",
			"<!-- <leader>s   Start item [~]                   -->",
			"<!-- <leader>d   Mark item as done [x] + move to DONE -->",
			"<!-- <leader><BS> Uncheck item [ ]               -->",
			"<!-- q           Save and close                  -->",
			"<!-- V then J/K  Reorder items by priority       -->",
			"",
			"# TODO:",
			"",
			"---",
			"",
			"# DONE:",
			"",
		}, todo_file)
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

	local datetime_pattern = "%d%d%d%d%-%d%d%-%d%d %d%d:%d%d "

	-- Mark done: [x] with date and time, move to DONE section
	vim.keymap.set("n", "<leader>d", function()
		local row = vim.api.nvim_win_get_cursor(todo_win)[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		local line = lines[row]
		local stamp = os.date("%Y-%m-%d %H:%M")

		-- Mark as done with timestamp
		local new = line:gsub("%[([ ~])%]", "[x]")
		new = new:gsub("%[x%]%s*" .. datetime_pattern, "[x] " .. stamp .. " ")
		if not new:find("%[x%]%s*%d") then
			new = new:gsub("%[x%]%s*", "[x] " .. stamp .. " ")
		end

		-- Collect subitems (indented lines below current)
		local item_lines = { new }
		local base_indent = (line:match("^(%s*)") or ""):len()
		local last_row = row
		for i = row + 1, #lines do
			local indent = (lines[i]:match("^(%s*)") or ""):len()
			if indent > base_indent and lines[i]:match("%S") then
				table.insert(item_lines, lines[i])
				last_row = i
			else
				break
			end
		end

		-- Find the DONE heading
		local done_row = nil
		for i = 1, #lines do
			if lines[i]:match("^# DONE:") then
				done_row = i
				break
			end
		end

		if not done_row then
			-- No DONE section, just mark in place
			vim.api.nvim_set_current_line(new)
			return
		end

		-- Remove original lines first
		vim.api.nvim_buf_set_lines(todo_buf, row - 1, last_row, false, {})
		local removed = last_row - row + 1

		-- Re-read lines after removal and find DONE heading again
		lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		done_row = nil
		for i = 1, #lines do
			if lines[i]:match("^# DONE:") then
				done_row = i
				break
			end
		end

		-- Find or create today's date entry under DONE
		local today = os.date("%Y-%m-%d")
		local day_of_week = os.date("%A")
		local date_row = nil
		local today_pattern = today:gsub("%-", "%%-")
		for i = done_row + 1, #lines do
			if lines[i]:match("^#") then break end
			if lines[i]:match("^%- " .. today_pattern) then
				date_row = i
				break
			end
		end

		-- Indent done items as subitems
		local sub_items = {}
		for _, l in ipairs(item_lines) do
			table.insert(sub_items, "  " .. l)
		end

		if date_row then
			-- Find last line belonging to this date entry (any indented content)
			local insert_at = date_row
			for i = date_row + 1, #lines do
				if lines[i]:match("^%s+%S") then
					insert_at = i
				else
					break
				end
			end
			vim.api.nvim_buf_set_lines(todo_buf, insert_at, insert_at, false, sub_items)
		else
			-- Create new date entry right after DONE heading (skip blank lines)
			local insert_at = done_row + 1
			while insert_at <= #lines and lines[insert_at]:match("^%s*$") do
				insert_at = insert_at + 1
			end
			local new_lines = { "- " .. today .. " (" .. day_of_week .. ")" }
			for _, l in ipairs(sub_items) do
				table.insert(new_lines, l)
			end
			vim.api.nvim_buf_set_lines(todo_buf, insert_at - 1, insert_at - 1, false, new_lines)
		end
		vim.api.nvim_win_set_cursor(todo_win, { math.min(row, vim.api.nvim_buf_line_count(todo_buf)), 0 })
	end, { buffer = todo_buf, desc = "Mark TODO done" })

	-- Start: mark in-progress [~]
	vim.keymap.set("n", "<leader>s", function()
		local line = vim.api.nvim_get_current_line()
		local new = line:gsub("%[([x ])%]", "[~]")
		new = new:gsub("%[~%]%s*" .. datetime_pattern, "[~] ")
		vim.api.nvim_set_current_line(new)
	end, { buffer = todo_buf, desc = "Start TODO item" })

	-- Uncheck: [ ]
	vim.keymap.set("n", "<leader><BS>", function()
		local line = vim.api.nvim_get_current_line()
		local new = line:gsub("%[([x~])%]", "[ ]")
		new = new:gsub("%[ %]%s*" .. datetime_pattern, "[ ] ")
		vim.api.nvim_set_current_line(new)
	end, { buffer = todo_buf, desc = "Uncheck TODO" })

	-- Add new todo item below the current section's last list item
	vim.keymap.set("n", "<leader>a", function()
		local cursor = vim.api.nvim_win_get_cursor(todo_win)
		local row = cursor[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		-- Find the last list item before the next heading, divider, or end of file
		local insert_row = row
		for i = row + 1, #lines do
			local l = lines[i]
			if l:match("^#") or l:match("^%-%-%-") then break end
			if l:match("^%s*%-") then insert_row = i end
		end
		vim.api.nvim_buf_set_lines(todo_buf, insert_row, insert_row, false, { "- [ ] " })
		vim.api.nvim_win_set_cursor(todo_win, { insert_row + 1, 6 })
		vim.cmd("startinsert!")
	end, { buffer = todo_buf, desc = "Add TODO item" })

end

vim.keymap.set("n", "<leader>td", toggle_todo, { desc = "Toggle TODO" })

return {}
