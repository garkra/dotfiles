-- Simple task manager. Storage: ~/.todo.md (+ ~/.todo-archive.md).
-- Pure logic lives in lua/todo/core.lua; this file is the UI/IO shell.
local core = require("todo.core")

local TODO = vim.fn.expand("~/.todo.md")
local ARCHIVE = vim.fn.expand("~/.todo-archive.md")
local SUMMARIES = vim.fn.expand("~/.todo-summaries.md")

-- ── file IO ──

local function read_lines(path)
	if vim.fn.filereadable(path) == 0 then return {} end
	return vim.fn.readfile(path)
end

local function write_lines(path, lines)
	vim.fn.writefile(lines, path)
end

local function today_tbl()
	local t = os.date("*t")
	return { year = t.year, month = t.month, day = t.day, wday = t.wday }
end

-- prepend `archived` day-groups onto the archive file (archive stays newest-first)
local function append_archive(archived)
	if #archived == 0 then return end
	local existing = read_lines(ARCHIVE)
	local merged = {}
	for _, l in ipairs(archived) do merged[#merged + 1] = l end
	if #existing > 0 then merged[#merged + 1] = "" end
	for _, l in ipairs(existing) do merged[#merged + 1] = l end
	write_lines(ARCHIVE, merged)
end

-- create the file with empty sections if it doesn't exist yet
local function ensure_ready()
	if #read_lines(TODO) == 0 then
		write_lines(TODO, {
			"# TODAY:", "", "---", "",
			"# THIS WEEK:", "", "---", "",
			"# BACKLOG:", "", "---", "",
			"# BLOCKED:", "", "---", "",
			"# DONE:", "",
		})
	end
end

-- roll DONE day-groups older than 30 days out to the archive. Operates on the OPEN
-- buffer (not the disk file) so the buffer stays the single source of truth; the buffer
-- is written back to disk on close.
local function sweep_archive(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local work, archived = core.archive_sweep(lines, today_tbl())
	if #archived > 0 then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, work)
		append_archive(archived)
	end
end

-- ── float window ──

local state = { win = nil, buf = nil, path = nil }
local open_float, apply, set_keymaps

open_float = function(path, title, opts)
	opts = opts or {}
	-- Edit the REAL file as a normal, swap-backed buffer (NOT a scratch/nofile buffer).
	-- Why this matters: loading a real file makes its contents the floor of the undo
	-- tree, so `u` can never rewind to an empty buffer; edits get a persistent undofile
	-- (undofile is enabled globally); and `:w` works natively. The old nofile buffer had
	-- none of these, so a stray `u` blanked it and the autosave then overwrote the file.
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	vim.bo[buf].buflisted = false
	vim.bo[buf].bufhidden = "hide" -- keep buffer + undo history across opens; never wipe
	vim.bo[buf].filetype = "markdown"
	if opts.readonly then
		vim.bo[buf].modifiable = false
		vim.bo[buf].readonly = true
	end
	local W = math.floor(vim.o.columns * 0.9)
	local H = math.floor(vim.o.lines * 0.7)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor", width = W, height = H,
		row = math.floor((vim.o.lines - H) / 2), col = math.floor((vim.o.columns - W) / 2),
		style = "minimal", border = "rounded", title = title or " TODO ", title_pos = "center",
	})
	state.buf, state.win, state.path = buf, win, (not opts.readonly) and path or nil
	-- Save on ANY exit path (q, :q, switching away from the window). Safe now because the
	-- buffer IS the file: writing it just persists real edits — it can't blank the file.
	if state.path and not vim.b[buf].todo_autosave then
		vim.b[buf].todo_autosave = true
		vim.api.nvim_create_autocmd("BufWinLeave", {
			buffer = buf,
			callback = function()
				if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable then
					vim.api.nvim_buf_call(buf, function()
						if vim.bo.modified then vim.cmd("silent! write") end
					end)
				end
			end,
		})
	end
	return buf, win
end

-- run a core transform on the buffer at the cursor line, updating the buffer in place
apply = function(transform)
	local buf, win = state.buf, state.win
	if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
	local lnum = vim.api.nvim_win_get_cursor(win)[1]
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local out = transform(lines, lnum)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
	pcall(vim.api.nvim_win_set_cursor, win, { math.min(lnum, #out), 0 })
end

local Todo = {}

set_keymaps = function(buf)
	local function map(lhs, fn)
		vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true, nowait = true })
	end
	map("q", function() Todo.close() end)
	map("<leader>d", function() apply(function(l, n) return core.mark_done(l, n, today_tbl()) end) end)
	map("<leader>b", function() apply(function(l, n) return core.toggle_blocked(l, n, today_tbl()) end) end)
	map("<leader>p", function() apply(function(l, n) return core.promote(l, n) end) end)
	map("<leader>m", function()
		vim.ui.input({ prompt = "Meeting: " }, function(name)
			if name and name ~= "" then
				apply(function(l, _) return core.log_meeting(l, name, today_tbl()) end)
			end
		end)
	end)
	map("<leader>l", function()
		local row = vim.api.nvim_win_get_cursor(state.win)[1]
		local cur = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		vim.ui.input({ prompt = "Log: " }, function(text)
			if text == nil then return end
			local entry = core.log_line(cur, text)
			if entry then
				apply(function(l, _) return core.insert_done(l, entry, today_tbl()) end)
			end
		end)
	end)
	map("<leader>a", function()
		local row = vim.api.nvim_win_get_cursor(state.win)[1]
		local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		local indent = line:match("^%s*") or ""
		vim.api.nvim_buf_set_lines(buf, row, row, false, { indent .. "- [ ] " })
		vim.api.nvim_win_set_cursor(state.win, { row + 1, #indent + 6 })
		vim.cmd("startinsert!")
	end)
	map("<leader>n", function()
		local row = vim.api.nvim_win_get_cursor(state.win)[1]
		local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
		local indent = line:match("^%s*") or ""
		vim.api.nvim_buf_set_lines(buf, row, row, false, { indent .. "  - " })
		vim.api.nvim_win_set_cursor(state.win, { row + 1, #indent + 4 })
		vim.cmd("startinsert!")
	end)
end

function Todo.toggle()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		Todo.close()
		return
	end
	ensure_ready()
	local buf = open_float(TODO, " TODO ")
	sweep_archive(buf)
	set_keymaps(buf)
end

function Todo.close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		if state.path and state.buf and vim.api.nvim_buf_is_valid(state.buf)
			and vim.bo[state.buf].modifiable then
			vim.api.nvim_buf_call(state.buf, function()
				if vim.bo.modified then vim.cmd("silent! write") end
			end)
		end
		vim.api.nvim_win_close(state.win, true) -- buffer survives (bufhidden = hide)
	end
	state.win, state.buf, state.path = nil, nil, nil
end

function Todo.open_archive()
	local buf = open_float(ARCHIVE, " TODO — Archive ")
	vim.keymap.set("n", "q", function() Todo.close() end, { buffer = buf, silent = true, nowait = true })
end

-- ── AI summary ──

-- present a finished summary: Float (read-only) or append to ~/.todo-summaries.md
function Todo._present_summary(out, timeframe)
	vim.ui.select({ "Float", "Save to file" }, { prompt = "Summary output:" }, function(choice)
		if not choice then return end
		if choice == "Save to file" then
			local stamp = os.date("%Y-%m-%d") -- ISO date
			local merged = read_lines(SUMMARIES)
			if #merged > 0 then merged[#merged + 1] = "" end
			merged[#merged + 1] = string.format("## %s — %s", stamp, timeframe)
			merged[#merged + 1] = ""
			for _, l in ipairs(out) do merged[#merged + 1] = l end
			write_lines(SUMMARIES, merged)
			vim.notify("Saved summary to " .. SUMMARIES, vim.log.levels.INFO)
		else
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
			vim.bo[buf].filetype = "markdown"
			vim.bo[buf].buftype = "nofile"
			vim.bo[buf].bufhidden = "wipe"
			vim.bo[buf].modifiable = false
			local W = math.floor(vim.o.columns * 0.7)
			local H = math.min(#out + 2, math.floor(vim.o.lines * 0.8))
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor", width = W, height = H,
				row = math.floor((vim.o.lines - H) / 2), col = math.floor((vim.o.columns - W) / 2),
				style = "minimal", border = "rounded", title = " Summary ", title_pos = "center",
			})
			vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf, silent = true })
		end
	end)
end

-- prompt for a timeframe, pipe DONE + archive to `claude`, present the result
function Todo.ai_summary()
	if vim.fn.executable("claude") == 0 then
		vim.notify("`claude` CLI not found on PATH", vim.log.levels.ERROR)
		return
	end
	vim.ui.input({ prompt = "Summary timeframe/focus: " }, function(tf)
		if tf == nil then return end
		local timeframe = (tf ~= "") and tf or "recent completed work, grouped by project/theme"
		local lines = read_lines(TODO)
		local dn = core.section_by_name(lines, "DONE")
		local done = {}
		if dn then
			for i = dn.heading, dn.last do done[#done + 1] = lines[i] end
		end
		local material = table.concat(done, "\n") .. "\n\n# ARCHIVE\n" .. table.concat(read_lines(ARCHIVE), "\n")
		local prompt = string.format(
			"Below is my completed-task log (ISO-dated, `[x]` items grouped by date; many items "
				.. "carry markdown links to Jira tickets, GitLab MRs, docs, and chat threads). "
				.. "Write a concise prose summary of what I accomplished for this timeframe/focus: %s. "
				.. "Group by project or theme and highlight notable items. PRESERVE the relevant "
				.. "links inline as proper [text](url) markdown (especially Jira tickets and GitLab "
				.. "MRs) so I can click through to dive deeper — do not strip them or turn them into "
				.. "bare text. Keep it tight. Output markdown.",
			timeframe)
		vim.notify("Summarizing with claude…", vim.log.levels.INFO)
		vim.system({ "claude", "-p", prompt }, { stdin = material, text = true }, function(res)
			vim.schedule(function()
				if res.code ~= 0 then
					vim.notify("claude failed: " .. (res.stderr or "unknown error"), vim.log.levels.ERROR)
					return
				end
				local out = vim.split(vim.trim(res.stdout or ""), "\n")
				Todo._present_summary(out, timeframe)
			end)
		end)
	end)
end

-- ── global keymaps ──

vim.keymap.set("n", "<leader>td", Todo.toggle, { desc = "Toggle TODO" })
vim.keymap.set("n", "<leader>ta", Todo.open_archive, { desc = "TODO archive" })
vim.keymap.set("n", "<leader>ts", Todo.ai_summary, { desc = "TODO AI summary" })

return {}
