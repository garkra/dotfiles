-- Pure logic for the todo plugin. No `vim.*` calls (testable under `nvim -l`).
-- Functions take a `lines` array (and a `today` table where needed) and return new
-- `lines`/data. `today` = { year=2026, month=6, day=8, wday=2 } (wday 1=Sunday..7=Saturday).
local M = {}
M.VERSION = 1

M.HEADINGS = {
  ["# TODAY:"] = "TODAY", ["# THIS WEEK:"] = "THIS WEEK",
  ["# BACKLOG:"] = "BACKLOG", ["# BLOCKED:"] = "BLOCKED", ["# DONE:"] = "DONE",
}
M.WEEKDAYS = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}

-- ── parsing primitives ──────────────────────────────────────────────────────

function M.indent_of(line) return #(line:match("^%s*")) end

function M.heading_name(line) return M.HEADINGS[line] end

-- a "---" thematic break, tolerant of leading/trailing whitespace
function M.is_separator(line) return line:match("^%s*%-%-%-+%s*$") ~= nil end

-- { indent=int, mark=" "|"!"|"x" or nil, text=string, is_task=bool } or nil if not a bullet
function M.parse_task(line)
  local indent, rest = line:match("^(%s*)%-%s(.*)$")
  if not rest then return nil end
  local mark, text = rest:match("^%[(.)%]%s?(.*)$")
  if mark then
    return { indent = #indent, mark = mark, text = text, is_task = true }
  end
  return { indent = #indent, mark = nil, text = rest, is_task = false }
end

-- ISO day header: "- 2026-06-08 (Monday)" -> { year, month, day } (numbers), else nil
function M.parse_day_header(line)
  local y, m, d = line:match("^%-%s(%d%d%d%d)%-(%d%d)%-(%d%d)%s")
  if y then return { year = tonumber(y), month = tonumber(m), day = tonumber(d) } end
  return nil
end

-- ── section model ───────────────────────────────────────────────────────────

-- array of {name, heading, first, last} in file order. first..last is the content
-- range; if last < first the section is empty.
function M.sections(lines)
  local out, cur = {}, nil
  for i, line in ipairs(lines) do
    local name = M.HEADINGS[line]
    if name then
      if cur then cur.last = i - 1 end
      cur = { name = name, heading = i, first = i + 1, last = i }
      table.insert(out, cur)
    end
  end
  if cur then cur.last = #lines end
  return out
end

function M.section_by_name(lines, name)
  for _, sec in ipairs(M.sections(lines)) do
    if sec.name == name then return sec end
  end
  return nil
end

-- ── item block + group tag ──────────────────────────────────────────────────

-- last line of the block rooted at lnum: lnum plus following more-indented bullet lines
function M.block_end(lines, lnum)
  local base = M.indent_of(lines[lnum])
  local last = lnum
  for i = lnum + 1, #lines do
    local l = lines[i]
    if l:match("^%s*$") or M.HEADINGS[l] or M.is_separator(l) then break end
    if M.indent_of(l) > base then last = i else break end
  end
  return last
end

-- nearest ancestor plain bullet (is_task=false) at lesser indent; nil if none /
-- parent is a task / heading or blank hit
function M.group_tag(lines, lnum)
  local base = M.indent_of(lines[lnum])
  for i = lnum - 1, 1, -1 do
    local l = lines[i]
    if M.HEADINGS[l] or l:match("^%s*$") or M.is_separator(l) then return nil end
    local p = M.parse_task(l)
    if p and p.indent < base then
      return (not p.is_task) and p.text or nil
    end
  end
  return nil
end

-- ── dates ───────────────────────────────────────────────────────────────────

function M.today_header(today)
  return string.format("- %04d-%02d-%02d (%s)", today.year, today.month, today.day, M.WEEKDAYS[today.wday])
end

-- whole days between `today` and a fully-specified (y, m, d). No inference.
function M.days_ago(today, y, m, d)
  local then_t = os.time({ year = y, month = m, day = d, hour = 12 })
  local now_t = os.time({ year = today.year, month = today.month, day = today.day, hour = 12 })
  return math.floor((now_t - then_t) / 86400 + 0.5)
end

-- ── shared edit helpers (file-local) ────────────────────────────────────────

-- extract block [lnum..block_end] from lines; returns remaining_lines, block_lines
local function cut_block(lines, lnum)
  local last = M.block_end(lines, lnum)
  local rest, block = {}, {}
  for i, l in ipairs(lines) do
    if i >= lnum and i <= last then block[#block + 1] = l else rest[#rest + 1] = l end
  end
  return rest, block
end

-- set the checkbox mark on a single bullet line
local function set_mark(line, mark)
  return (line:gsub("^(%s*%-%s)%[.%]", "%1[" .. mark .. "]", 1))
end

-- insert `block` at the TOP (after heading + blank) or BOTTOM (after last content line,
-- or after the heading's blank for an empty section) of a named section.
local function insert_block(lines, section_name, block, where)
  local out = {}
  for _, l in ipairs(lines) do out[#out + 1] = l end
  local sec = M.section_by_name(out, section_name)
  if not sec then return out end
  if where == "top" then
    local at = sec.heading + 1
    if out[at] == "" then at = at + 1 else table.insert(out, at, ""); at = at + 1 end
    for k = #block, 1, -1 do table.insert(out, at, block[k]) end
  else -- bottom
    local last_content = nil
    for i = sec.first, sec.last do
      local l = out[i] or ""
      if l:match("%S") and not M.is_separator(l) then last_content = i end -- ignore --- rules
    end
    local at
    if last_content then
      at = last_content + 1
    else
      at = sec.heading + 1
      if out[at] == "" then at = at + 1 else table.insert(out, at, ""); at = at + 1 end
    end
    for k = 1, #block do table.insert(out, at, block[k]); at = at + 1 end
  end
  return out
end

-- ── DONE insertion ──────────────────────────────────────────────────────────

-- insert `item` (a single "  - [x] text" line, or an array of such lines for an item
-- plus its notes) under today's day-group in DONE. Creates the day-group at the top of
-- DONE if missing. Returns a new lines array.
function M.insert_done(lines, item, today)
  local items = type(item) == "table" and item or { item }
  local out = {}
  for _, l in ipairs(lines) do out[#out + 1] = l end
  local dn = M.section_by_name(out, "DONE")
  if not dn then
    out[#out + 1] = ""; out[#out + 1] = "# DONE:"
    dn = M.section_by_name(out, "DONE")
  end
  local header = M.today_header(today)
  local hdr_idx = nil
  for i = dn.first, math.max(dn.first, dn.last) do
    if out[i] == header then hdr_idx = i; break end
  end
  if hdr_idx then
    for k = #items, 1, -1 do table.insert(out, hdr_idx + 1, items[k]) end
  else
    local at = dn.heading + 1
    if out[at] == "" then at = at + 1 else table.insert(out, at, ""); at = at + 1 end
    table.insert(out, at, header)
    for k = 1, #items do table.insert(out, at + k, items[k]) end
    table.insert(out, at + #items + 1, "")
  end
  return out
end

-- ── operations ──────────────────────────────────────────────────────────────

-- mark the task at lnum done: move it (and its note/sub-bullet subtree) under today's
-- DONE day-group, retagging the head line and re-basing indentation to 2 spaces.
function M.mark_done(lines, lnum, today)
  local task = M.parse_task(lines[lnum])
  if not task or not task.is_task then return lines end
  local tag = M.group_tag(lines, lnum)
  local last = M.block_end(lines, lnum)
  local base = task.indent
  local moved = {}
  for i = lnum, last do
    local l = lines[i]
    local indent = string.rep(" ", (M.indent_of(l) - base) + 2)
    if i == lnum then
      local body = tag and string.format("[x] (%s) %s", tag, task.text)
        or string.format("[x] %s", task.text)
      moved[#moved + 1] = indent .. "- " .. body
    else
      moved[#moved + 1] = indent .. l:gsub("^%s*", "")
    end
  end
  local out = {}
  for i, l in ipairs(lines) do
    if i < lnum or i > last then out[#out + 1] = l end
  end
  return M.insert_done(out, moved, today)
end

-- toggle blocked: move the block to BLOCKED (mark !) or back to top of THIS WEEK (mark space).
function M.toggle_blocked(lines, lnum, today)
  local task = M.parse_task(lines[lnum])
  if not task or not task.is_task then return lines end
  local rest, block = cut_block(lines, lnum)
  if task.mark == "!" then
    block[1] = set_mark(block[1], " ")
    return insert_block(rest, "THIS WEEK", block, "top")
  else
    block[1] = set_mark(block[1], "!")
    return insert_block(rest, "BLOCKED", block, "bottom")
  end
end

-- which promotable section contains line index `lnum`? returns name or nil
function M.section_at(lines, lnum)
  local found
  for _, sec in ipairs(M.sections(lines)) do
    if lnum >= sec.first and lnum <= sec.last then found = sec.name end
  end
  return found
end

local PROMOTE_UP = { ["BACKLOG"] = "THIS WEEK", ["THIS WEEK"] = "TODAY" }

-- promote the block at lnum up one scale (Backlog->This Week->Today), bottom of dest.
function M.promote(lines, lnum)
  local from = M.section_at(lines, lnum)
  local to = from and PROMOTE_UP[from]
  if not to then return lines end
  local rest, block = cut_block(lines, lnum)
  return insert_block(rest, to, block, "bottom")
end

-- log a meeting straight into DONE under today.
function M.log_meeting(lines, name, today)
  return M.insert_done(lines, string.format("  - [x] (meeting) %s", name), today)
end

-- build a progress-log bullet for DONE: "  - <text> --> <ref>", where <ref> is the text
-- of the bullet under the cursor (carrying its inline links). Falls back gracefully and
-- returns nil if there's nothing to log.
function M.log_line(cursor_line, text)
  text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local ref
  local p = M.parse_task(cursor_line or "")
  if p then
    local t = (p.text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t ~= "" then ref = t end
  end
  local entry
  if text ~= "" and ref then entry = text .. " --> " .. ref
  elseif text ~= "" then entry = text
  elseif ref then entry = ref
  else return nil end
  return "  - " .. entry
end

-- ── archive ─────────────────────────────────────────────────────────────────

-- end line of a DONE day-group starting at hdr; spans until the next day header,
-- section heading, or a blank line.
local function daygroup_end(lines, hdr)
  local last = hdr
  for i = hdr + 1, #lines do
    local l = lines[i]
    if M.HEADINGS[l] or M.parse_day_header(l) then break end
    if l:match("^%s*$") then break end
    last = i
  end
  return last
end

-- move DONE day-groups older than 30 days out to an archive list.
-- returns working_lines, archived_lines (archived in original order).
function M.archive_sweep(lines, today)
  local dn = M.section_by_name(lines, "DONE")
  if not dn then return lines, {} end
  local archived, drop = {}, {}
  local i = dn.first
  while i <= dn.last do
    local dh = M.parse_day_header(lines[i])
    if dh then
      local age = M.days_ago(today, dh.year, dh.month, dh.day)
      local last = daygroup_end(lines, i)
      if age and age > 30 then
        for k = i, last do archived[#archived + 1] = lines[k]; drop[k] = true end
        if lines[last + 1] == "" then drop[last + 1] = true end
      end
      i = last + 1
    else
      i = i + 1
    end
  end
  if #archived == 0 then return lines, {} end
  local work = {}
  for idx, l in ipairs(lines) do if not drop[idx] then work[#work + 1] = l end end
  return work, archived
end

return M
