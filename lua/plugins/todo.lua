local todo_file = vim.fn.expand("~/.todo.md")
local todo_buf = nil
local todo_win = nil

-- ── Time helpers ──

local function time_to_min(t)
	local h, m = t:match("(%d+):(%d+)")
	if not h then return 0 end
	return tonumber(h) * 60 + tonumber(m)
end

local function format_dur(mins)
	if mins < 0 then mins = 0 end
	local h = math.floor(mins / 60)
	local m = mins % 60
	if h > 0 then return string.format("%dh%02dm", h, m) end
	return string.format("%dm", m)
end

local function now_hhmm() return os.date("%H:%M") end
local function today_month() return os.date("%b") end
local function today_day() return tonumber(os.date("%d")) end

-- ── Segment/day parsing ──

local function parse_segments(content)
	local segs = {}
	for seg in content:gmatch("[^,]+") do
		seg = vim.trim(seg)
		local s, e = seg:match("^(%d%d:%d%d)%-(%d%d:%d%d)$")
		if s then
			table.insert(segs, { start = s, stop = e })
		else
			s = seg:match("^(%d%d:%d%d)%-$")
			if s then table.insert(segs, { start = s, stop = nil }) end
		end
	end
	return segs
end

local function parse_time_str(ts)
	if not ts or ts == "" then return {} end
	local days = {}
	for entry in (ts .. " | "):gmatch("(.-)%s*|%s*") do
		entry = vim.trim(entry)
		if entry ~= "" then
			local mon, d, content = entry:match("^(%a+) (%d+): (.+)$")
			if mon then
				local day = { month = mon, day = tonumber(d) }
				local hours, mins = content:match("^(%d+)h(%d+)m$")
				if hours then
					day.collapsed = true
					day.total_min = tonumber(hours) * 60 + tonumber(mins)
				else
					local mins_only = content:match("^(%d+)m$")
					if mins_only then
						day.collapsed = true
						day.total_min = tonumber(mins_only)
					else
						day.collapsed = false
						day.segments = parse_segments(content)
					end
				end
				table.insert(days, day)
			end
		end
	end
	return days
end

local function seg_minutes(seg)
	local stop = seg.stop or now_hhmm()
	return math.max(0, time_to_min(stop) - time_to_min(seg.start))
end

local function day_minutes(day)
	if day.collapsed then return day.total_min end
	local t = 0
	for _, s in ipairs(day.segments or {}) do t = t + seg_minutes(s) end
	return t
end

local function total_minutes(days)
	local t = 0
	for _, d in ipairs(days) do t = t + day_minutes(d) end
	return t
end

local function format_time_str(days)
	local parts = {}
	for _, day in ipairs(days) do
		if day.collapsed then
			table.insert(parts, day.month .. " " .. day.day .. ": " .. format_dur(day.total_min))
		else
			local segs = {}
			for _, s in ipairs(day.segments) do
				table.insert(segs, s.start .. "-" .. (s.stop or ""))
			end
			table.insert(parts, day.month .. " " .. day.day .. ": " .. table.concat(segs, ", "))
		end
	end
	return table.concat(parts, " | ")
end

local function collapse_old_days(days)
	local tl = today_month() .. " " .. today_day()
	local result = {}
	for _, day in ipairs(days) do
		local dl = day.month .. " " .. day.day
		if dl == tl then
			table.insert(result, day)
		else
			if not day.collapsed and day.segments then
				for _, s in ipairs(day.segments) do
					if not s.stop then s.stop = "23:59" end
				end
			end
			table.insert(result, {
				month = day.month, day = day.day,
				collapsed = true, total_min = day_minutes(day),
			})
		end
	end
	return result
end

-- ── Line parsing ──

local function parse_line(line)
	local indent, state, rest = line:match("^(%s*)%- %[([%sxX~=!])%]%s*(.*)")
	if not indent then return nil end
	local time_str = rest:match("{(.-)}")
	local total_str = rest:match("%((%d+h%d+m)%)%s*$") or rest:match("%((%d+m)%)%s*$")
	local text = rest:gsub("%s*{.-}", ""):gsub("%s*%(%d+h?%d*m%)%s*$", ""):gsub("%s+$", "")
	return { indent = indent, state = state, text = text, time_str = time_str, total_str = total_str }
end

local function build_line(indent, state, text, time_str, total_str)
	local line = indent .. "- [" .. state .. "] " .. text
	if time_str and time_str ~= "" then line = line .. " {" .. time_str .. "}" end
	if total_str and total_str ~= "" then line = line .. " (" .. total_str .. ")" end
	return line
end

-- ── Tree helpers ──

local function get_children_range(lines, row)
	local base = (lines[row]:match("^(%s*)") or ""):len()
	local last = row
	for i = row + 1, #lines do
		local indent = (lines[i]:match("^(%s*)") or ""):len()
		if indent > base and lines[i]:match("%S") then last = i
		else break end
	end
	if last == row then return nil, nil end
	return row + 1, last
end

local function get_parent_row(lines, row)
	local base = (lines[row]:match("^(%s*)") or ""):len()
	if base == 0 then return nil end
	for i = row - 1, 1, -1 do
		local indent = (lines[i]:match("^(%s*)") or ""):len()
		if indent < base and lines[i]:match("^%s*%- %[") then return i end
	end
	return nil
end

local function all_children_done(lines, parent_row)
	local first, last = get_children_range(lines, parent_row)
	if not first then return true end
	-- Detect actual child indent from first child rather than assuming +2
	local child_indent = (lines[first]:match("^(%s*)") or ""):len()
	for i = first, last do
		local indent = (lines[i]:match("^(%s*)") or ""):len()
		if indent == child_indent then
			local p = parse_line(lines[i])
			if p and p.state ~= "x" and p.state ~= "X" then return false end
		end
	end
	return true
end

-- ── Lualine globals ──

local function update_lualine_globals()
	if vim.fn.filereadable(todo_file) == 0 then
		vim.g.todo_active_text = ""
		vim.g.todo_active_start = 0
		vim.g.todo_active_prior_min = 0
		return
	end

	local file_lines = vim.fn.readfile(todo_file)
	-- Find deepest (last) active [~] item
	local active_row = nil
	for i, l in ipairs(file_lines) do
		if l:match("%[~%]") then active_row = i end
	end

	if not active_row then
		vim.g.todo_active_text = ""
		vim.g.todo_active_start = 0
		vim.g.todo_active_prior_min = 0
		return
	end

	local parsed = parse_line(file_lines[active_row])
	if not parsed then
		vim.g.todo_active_text = ""
		return
	end

	-- Build display text with parent context
	local display = parsed.text
	local parent = get_parent_row(file_lines, active_row)
	if parent then
		local pp = parse_line(file_lines[parent])
		if pp then display = pp.text .. " → " .. display end
	end

	-- Calculate timing
	local days = parse_time_str(parsed.time_str)
	local prior = 0
	local seg_start_epoch = os.time()
	for _, day in ipairs(days) do
		if day.collapsed then
			prior = prior + day.total_min
		elseif day.segments then
			for _, seg in ipairs(day.segments) do
				if seg.stop then
					prior = prior + seg_minutes(seg)
				else
					local h, m = seg.start:match("(%d+):(%d+)")
					local t = os.date("*t")
					t.hour = tonumber(h)
					t.min = tonumber(m)
					t.sec = 0
					seg_start_epoch = os.time(t)
				end
			end
		end
	end

	vim.g.todo_active_text = display
	vim.g.todo_active_start = seg_start_epoch
	vim.g.todo_active_prior_min = prior
end

-- ── DONE section helpers ──

local function find_done_heading(lines)
	for i, l in ipairs(lines) do
		if l:match("^# DONE:") then return i end
	end
	return nil
end

local function find_or_create_today_entry(lines, done_row)
	local today = os.date("%b") .. " " .. tonumber(os.date("%d"))
	local day_of_week = os.date("%A")
	local today_pat = today:gsub("%-", "%%-")

	for i = done_row + 1, #lines do
		if lines[i]:match("^#") then break end
		if lines[i]:match("^%- " .. today_pat) then return i, false end
	end

	local insert_at = done_row + 1
	while insert_at <= #lines and lines[insert_at]:match("^%s*$") do
		insert_at = insert_at + 1
	end
	return insert_at, true, "- " .. today .. " (" .. day_of_week .. ")"
end

local function insert_under_today(buf, ref_lines)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local done_row = find_done_heading(lines)
	if not done_row then return end

	local date_row, needs_create, date_line = find_or_create_today_entry(lines, done_row)
	if needs_create then
		local insert_lines = { date_line }
		vim.list_extend(insert_lines, ref_lines)
		table.insert(insert_lines, "")
		vim.api.nvim_buf_set_lines(buf, date_row - 1, date_row - 1, false, insert_lines)
	else
		local insert_at = date_row
		for i = date_row + 1, #lines do
			if lines[i]:match("^%s+%S") then insert_at = i
			else break end
		end
		vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, ref_lines)
	end
end

-- ── Collapse old days on buffer open ──

local function collapse_old_days_in_buf(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local changed = false
	for i, l in ipairs(lines) do
		local parsed = parse_line(l)
		if parsed and parsed.time_str then
			local days = parse_time_str(parsed.time_str)
			local collapsed = collapse_old_days(days)
			local new_ts = format_time_str(collapsed)
			if new_ts ~= parsed.time_str then
				local total = parsed.total_str
				if parsed.state == "x" or parsed.state == "X" then
					total = format_dur(total_minutes(collapsed))
				end
				lines[i] = build_line(parsed.indent, parsed.state, parsed.text, new_ts, total)
				changed = true
			end
		end
	end
	if changed then vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) end
end

-- ── Float window ──

local function close_todo()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		if todo_buf and vim.api.nvim_buf_is_valid(todo_buf) and vim.bo[todo_buf].modified then
			vim.api.nvim_buf_call(todo_buf, function() vim.cmd("write") end)
		end
		vim.api.nvim_win_close(todo_win, true)
		todo_win = nil
	end
	update_lualine_globals()
end

local function toggle_todo()
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		close_todo()
		return
	end

	if vim.fn.filereadable(todo_file) == 0 then
		vim.fn.writefile({
			"<!-- Keybindings (only active in this float): -->",
			"<!-- <leader>s   Start/pause [~]/[=]            -->",
			"<!-- <leader>d   Mark done [x] + track in DONE  -->",
			"<!-- <leader>b   Toggle blocked [!]             -->",
			"<!-- <leader>n   Add note bullet                 -->",
			"<!-- <leader>a   Add sibling item               -->",
			"<!-- <leader>c   Add child item                 -->",
			"<!-- <leader><BS> Reset item [ ]                -->",
			"<!-- q           Save and close                 -->",
			"<!-- V then J/K  Reorder items by priority      -->",
			"",
			"# TODO:",
			"",
			"---",
			"",
			"# DONE:",
			"",
		}, todo_file)
	end

	if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
		todo_buf = vim.fn.bufadd(todo_file)
		vim.fn.bufload(todo_buf)
		vim.bo[todo_buf].buflisted = false
		vim.bo[todo_buf].filetype = "markdown"
	end

	collapse_old_days_in_buf(todo_buf)

	local width = math.floor(vim.o.columns * 0.9)
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

	-- ── Keybindings ──

	vim.keymap.set("n", "q", close_todo, { buffer = todo_buf, desc = "Close TODO" })

	-- Start/pause toggle
	vim.keymap.set("n", "<leader>s", function()
		local line = vim.api.nvim_get_current_line()
		local parsed = parse_line(line)
		if not parsed then return end

		local days = parse_time_str(parsed.time_str)
		local now = now_hhmm()
		local tm, td = today_month(), today_day()

		if parsed.state == " " or parsed.state == "=" or parsed.state == "!" then
			parsed.state = "~"
			local today_entry = nil
			for _, d in ipairs(days) do
				if d.month == tm and d.day == td then today_entry = d; break end
			end
			if not today_entry then
				today_entry = { month = tm, day = td, collapsed = false, segments = {} }
				table.insert(days, today_entry)
			end
			if today_entry.collapsed then
				today_entry.collapsed = false
				today_entry.segments = {}
			end
			table.insert(today_entry.segments, { start = now, stop = nil })
			days = collapse_old_days(days)
		elseif parsed.state == "~" then
			parsed.state = "="
			for _, d in ipairs(days) do
				if d.month == tm and d.day == td and not d.collapsed then
					for _, seg in ipairs(d.segments) do
						if not seg.stop then seg.stop = now; break end
					end
					break
				end
			end
		end

		vim.api.nvim_set_current_line(build_line(parsed.indent, parsed.state, parsed.text, format_time_str(days), nil))
		update_lualine_globals()
	end, { buffer = todo_buf, desc = "Start/pause TODO" })

	-- Toggle blocked
	vim.keymap.set("n", "<leader>b", function()
		local line = vim.api.nvim_get_current_line()
		local parsed = parse_line(line)
		if not parsed then return end

		local days = parse_time_str(parsed.time_str)
		local now = now_hhmm()
		local tm, td = today_month(), today_day()

		if parsed.state == "!" then
			-- Unblock → back to paused (or todo if no time data)
			parsed.state = #days > 0 and "=" or " "
		else
			-- Block → close any active segment first
			if parsed.state == "~" then
				for _, d in ipairs(days) do
					if d.month == tm and d.day == td and not d.collapsed then
						for _, seg in ipairs(d.segments) do
							if not seg.stop then seg.stop = now; break end
						end
						break
					end
				end
			end
			parsed.state = "!"
		end

		vim.api.nvim_set_current_line(build_line(parsed.indent, parsed.state, parsed.text, format_time_str(days), nil))
		update_lualine_globals()
	end, { buffer = todo_buf, desc = "Toggle blocked" })

	-- Mark done
	vim.keymap.set("n", "<leader>d", function()
		local row = vim.api.nvim_win_get_cursor(todo_win)[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		local line = lines[row]
		local parsed = parse_line(line)
		if not parsed then return end

		-- Close any active segment
		local days = parse_time_str(parsed.time_str)
		for _, d in ipairs(days) do
			if not d.collapsed and d.segments then
				for _, seg in ipairs(d.segments) do
					if not seg.stop then seg.stop = now_hhmm() end
				end
			end
		end
		days = collapse_old_days(days)
		local tot = total_minutes(days)
		local ts = format_time_str(days)
		local total_str = tot > 0 and format_dur(tot) or nil
		local new_line = build_line(parsed.indent, "x", parsed.text, ts ~= "" and ts or nil, total_str)

		local parent_row = get_parent_row(lines, row)
		local first_child, last_child = get_children_range(lines, row)

		if parent_row then
			-- ── Child item: stay in place, add reference to DONE ──
			vim.api.nvim_buf_set_lines(todo_buf, row - 1, row, false, { new_line })

			local parent_parsed = parse_line(lines[parent_row])
			local ref = "  - ✓ " .. parsed.text
			if parent_parsed then ref = ref .. " (" .. parent_parsed.text .. ")" end
			if total_str then ref = ref .. " — " .. total_str end
			insert_under_today(todo_buf, { ref })

			-- Check if all siblings done → auto-complete parent
			lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
			if all_children_done(lines, parent_row) then
				local pp = parse_line(lines[parent_row])
				if pp then
					local p_first, p_last = get_children_range(lines, parent_row)
					local parent_total = 0
					if p_first then
						for i = p_first, p_last do
							local cp = parse_line(lines[i])
							if cp and cp.time_str then
								parent_total = parent_total + total_minutes(parse_time_str(cp.time_str))
							end
						end
					end
					local p_total_str = parent_total > 0 and format_dur(parent_total) or nil
					local parent_new = build_line(pp.indent, "x", pp.text, nil, p_total_str)

					local tree_end = p_last or parent_row
					local tree_lines = { "  " .. parent_new }
					for i = parent_row + 1, tree_end do
						table.insert(tree_lines, "  " .. lines[i])
					end

					vim.api.nvim_buf_set_lines(todo_buf, parent_row - 1, tree_end, false, {})
					insert_under_today(todo_buf, tree_lines)
				end
			end

		elseif first_child then
			-- ── Parent item (direct completion): move whole tree to DONE ──
			local parent_total = 0
			for i = first_child, last_child do
				local cp = parse_line(lines[i])
				if cp and cp.time_str then
					parent_total = parent_total + total_minutes(parse_time_str(cp.time_str))
				end
			end
			if tot > 0 then parent_total = parent_total + tot end
			local p_total_str = parent_total > 0 and format_dur(parent_total) or nil
			local parent_done = build_line(parsed.indent, "x", parsed.text, ts ~= "" and ts or nil, p_total_str)

			local tree_lines = { "  " .. parent_done }
			for i = first_child, last_child do
				table.insert(tree_lines, "  " .. lines[i])
			end

			vim.api.nvim_buf_set_lines(todo_buf, row - 1, last_child, false, {})
			insert_under_today(todo_buf, tree_lines)
		else
			-- ── Standalone item: move to DONE ──
			vim.api.nvim_buf_set_lines(todo_buf, row - 1, row, false, {})
			insert_under_today(todo_buf, { "  " .. new_line })
		end

		lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		vim.api.nvim_win_set_cursor(todo_win, { math.min(row, #lines), 0 })
		update_lualine_globals()
	end, { buffer = todo_buf, desc = "Mark TODO done" })

	-- Reset: [ ], clear time
	vim.keymap.set("n", "<leader><BS>", function()
		local line = vim.api.nvim_get_current_line()
		local parsed = parse_line(line)
		if not parsed then return end
		vim.api.nvim_set_current_line(build_line(parsed.indent, " ", parsed.text, nil, nil))
		update_lualine_globals()
	end, { buffer = todo_buf, desc = "Reset TODO" })

	-- Add sibling item
	vim.keymap.set("n", "<leader>a", function()
		local row = vim.api.nvim_win_get_cursor(todo_win)[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		local current = parse_line(lines[row])
		local indent = current and current.indent or ""
		local _, last_child = get_children_range(lines, row)
		local insert_row = last_child or row
		vim.api.nvim_buf_set_lines(todo_buf, insert_row, insert_row, false, { indent .. "- [ ] " })
		vim.api.nvim_win_set_cursor(todo_win, { insert_row + 1, #indent + 6 })
		vim.cmd("startinsert!")
	end, { buffer = todo_buf, desc = "Add TODO sibling" })

	-- Add note (plain bullet, not a task)
	vim.keymap.set("n", "<leader>n", function()
		local row = vim.api.nvim_win_get_cursor(todo_win)[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		local current_indent = (lines[row]:match("^(%s*)") or "")
		local note_indent = current_indent .. "  "
		local _, last_child = get_children_range(lines, row)
		local insert_row = last_child or row
		vim.api.nvim_buf_set_lines(todo_buf, insert_row, insert_row, false, { note_indent .. "- " })
		vim.api.nvim_win_set_cursor(todo_win, { insert_row + 1, #note_indent + 2 })
		vim.cmd("startinsert!")
	end, { buffer = todo_buf, desc = "Add note" })

	-- Add child item
	vim.keymap.set("n", "<leader>c", function()
		local row = vim.api.nvim_win_get_cursor(todo_win)[1]
		local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
		local current = parse_line(lines[row])
		if not current then return end
		local child_indent = current.indent .. "  "
		local _, last_child = get_children_range(lines, row)
		local insert_row = last_child or row
		vim.api.nvim_buf_set_lines(todo_buf, insert_row, insert_row, false, { child_indent .. "- [ ] " })
		vim.api.nvim_win_set_cursor(todo_win, { insert_row + 1, #child_indent + 6 })
		vim.cmd("startinsert!")
	end, { buffer = todo_buf, desc = "Add child TODO" })
end

vim.keymap.set("n", "<leader>td", toggle_todo, { desc = "Toggle TODO" })

-- Initialize on startup and auto-update on save
update_lualine_globals()

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = vim.fn.fnamemodify(todo_file, ":t"),
	callback = update_lualine_globals,
})

return {}
