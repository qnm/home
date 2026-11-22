local M = {}

local PATH_RULES = {
  { "*.test.ts", "test" }, { "*.test.tsx", "test" }, { "*.spec.ts", "test" }, { "*.spec.tsx", "test" },
  { "*/__tests__/*", "test" }, { "*/tests/*", "test" }, { "test_*.py", "test" }, { "*_test.py", "test" },
  { "*_test.go", "test" }, { "*/__snapshots__/*", "snapshot" }, { "*/__mocks__/*", "mock" },
  { "*/test/factories/*", "test factory" }, { "*/fixtures/*", "fixture" }, { "*/testdata/*", "fixture" },
  { "*.cy.ts", "cypress test" }, { "*.stories.tsx", "storybook" },
  { "pnpm-lock.yaml", "lockfile" }, { "package-lock.json", "lockfile" }, { "yarn.lock", "lockfile" },
  { "uv.lock", "lockfile" }, { "poetry.lock", "lockfile" }, { "Cargo.lock", "lockfile" }, { "go.sum", "lockfile" },
  { "*/generated/*", "generated" }, { "*.generated.ts", "generated" },
}

local C_LIKE = { line = "//", block = true }
local COMMENTS = { css = { block = true } }
for _, e in ipairs({ "ts", "tsx", "js", "jsx", "mjs", "cjs", "go", "rs", "java", "kt", "swift", "c", "h", "cpp",
  "cs", "scss" }) do
  COMMENTS[e] = C_LIKE
end
for _, e in ipairs({ "py", "sh", "bash", "zsh", "fish", "rb", "yml", "yaml", "toml", "nix", "tf" }) do
  COMMENTS[e] = { line = "#" }
end
for _, e in ipairs({ "lua", "sql" }) do COMMENTS[e] = { line = "--" } end

local function js_import(text)
  if text:match("^import%s") then return true end
  local rest = text:match("^export%s+(.*)$")
  if rest == nil then return false end
  rest = rest:gsub("^type%s+", "")
  if not (rest:match("^%*") or rest:match("^{")) then return false end
  local before = rest:match("^[^=]*")
  return before:match("%sfrom%s") ~= nil or before == rest and rest:match("{%s*$") ~= nil
end

local IMPORT_START = {
  py = function(text) return text:match("^import%s") or text:match("^from%s+%S+%s+import%s") end,
  rs = function(text) return text:match("^use%s") or text:match("^pub%s+use%s") end,
}
for _, e in ipairs({ "ts", "tsx", "js", "jsx", "mjs", "cjs" }) do IMPORT_START[e] = js_import end

local function set_of(...)
  local s = {}
  for _, list in ipairs({ ... }) do
    for _, e in ipairs(list) do s[e] = true end
  end
  return s
end

local JS = { "ts", "tsx", "js", "jsx", "mjs", "cjs", "mts", "cts" }
local SQUASH_OK = set_of(JS, { "json", "go", "rs", "java", "kt", "kts", "css", "scss" })
local QUOTE_STYLE = set_of(JS, { "py" })
local MOVE_K, MOVE_MIN_CHARS = 4, 60
local RULE_ORDER = { "move/rename", "imports", "comment", "formatting" }

local function join(list, sep)
  sep = sep or ""
  local out
  for i = 1, #list, 500 do
    local chunk = {}
    for k = i, math.min(i + 499, #list) do chunk[#chunk + 1] = list[k] end
    local part = table.concat(chunk, sep)
    out = out == nil and part or out .. sep .. part
  end
  return out or ""
end

local Failure = {}

local function die(code, msg)
  error(setmetatable({ code = code, msg = msg }, Failure), 0)
end

local function read(path)
  local f = io.open(path, "r")
  local text = f and f:read("*a")
  if f then f:close() end
  if text == nil then die(2, "missing input: " .. path) end
  return text
end

local function exists(path)
  local f = io.open(path, "r")
  if f == nil then return false end
  f:close()
  return true
end

local function write(path, text)
  local f = assert(io.open(path, "w"))
  assert(f:write(text))
  f:close()
end

local ARRAY_KEYS = { files = true, annotations = true, comments = true }

local function arrays_marked(value, key)
  if type(value) ~= "table" then return value end
  if ARRAY_KEYS[key] and next(value) == nil then return "\0[]" end
  local copy = {}
  for k, v in pairs(value) do copy[k] = arrays_marked(v, k) end
  return copy
end

local function encode(value)
  local text = assert(rex.json.encode(arrays_marked(value), { indent = true }))
  return (text:gsub('"\\u0000%[%]"', "[]")) .. "\n"
end

local function lines_of(text)
  if text ~= "" and text:sub(-1) ~= "\n" then text = text .. "\n" end
  local lines = {}
  for line in text:gmatch("(.-)\n") do lines[#lines + 1] = line end
  return lines
end

local function starts(s, prefix) return s:sub(1, #prefix) == prefix end

function M.parse(text)
  local files, cur, hunk = {}, nil, nil
  for _, line in ipairs(lines_of(text)) do
    local old, new, tail = line:match("^@@ %-(%d+)[,%d]* %+(%d+)[,%d]* @@(.*)$")
    if starts(line, "diff --git ") then
      local at = line:find(" b/", 1, true)
      cur = { header = { line }, path = at and line:sub(at + 3) or "", hunks = {} }
      files[#files + 1] = cur
      hunk = nil
    elseif cur == nil then
    elseif old then
      hunk = { old = tonumber(old), new = tonumber(new), tail = tail, body = {} }
      cur.hunks[#cur.hunks + 1] = hunk
    elseif hunk ~= nil then
      hunk.body[#hunk.body + 1] = line
    else
      cur.header[#cur.header + 1] = line
      if starts(line, "+++ b/") then cur.path = line:sub(7) end
    end
  end
  for _, f in ipairs(files) do
    if #f.hunks > 0 then return files end
  end
  die(2, "no hunks found: is this a unified diff from `git diff`?")
end

local function counts(body)
  local o, n = 0, 0
  for _, l in ipairs(body) do
    local c = l:sub(1, 1)
    if c == " " or c == "-" then o = o + 1 end
    if c == " " or c == "+" then n = n + 1 end
  end
  return o, n
end

local function glob(pattern)
  return "^" .. pattern:gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*", ".*") .. "$"
end

local function path_rule(path)
  local name = path:match("([^/]*)$")
  for _, rule in ipairs(PATH_RULES) do
    local p = glob(rule[1])
    if path:match(p) or name:match(p) then return rule[2] end
  end
  return nil
end

local function reexport_closes(body, i, sides)
  for j = i + 1, #body do
    local sign, text = body[j]:sub(1, 1), body[j]:sub(2)
    local same = sign == " "
    for _, s in ipairs(sides) do same = same or sign == s end
    if same and text:match("}") then return text:match("}%s*from%s") ~= nil end
  end
  return false
end

local function ext_of(path)
  local name = path:match("([^/]*)$")
  return (name:match("%.([^.]*)$") or ""):lower()
end

local function comment_lines(style, body)
  local hits, block = {}, false
  for i, line in ipairs(body) do
    local text = line:sub(2):match("^%s*(.*)$")
    if block then
      hits[i] = true
      block = text:find("*/", 1, true) == nil
    elseif style.line and starts(text, style.line) and not starts(text, "#!") then
      hits[i] = true
    elseif style.block and starts(text, "/*") then
      hits[i] = true
      block = text:find("*/", 1, true) == nil
    end
  end
  return hits
end

local function line_kinds(path, body)
  local ext = ext_of(path)
  local start = IMPORT_START[ext]
  local comments = comment_lines(COMMENTS[ext] or {}, body)
  local open_import = { ["-"] = false, ["+"] = false }
  local kinds = {}
  for i, line in ipairs(body) do
    local sign, text = line:sub(1, 1), line:sub(2)
    local sides = sign == " " and { "-", "+" } or open_import[sign] ~= nil and { sign } or {}
    local kind = false
    local open = false
    for _, s in ipairs(sides) do open = open or open_import[s] end
    if not text:match("%S") then
      kind = "blank"
    elseif #sides > 0 and open then
      kind = "imports"
      if text:match("[})]") then
        for _, s in ipairs(sides) do open_import[s] = false end
      end
    elseif start and start(text) and (not text:match("^export") or not text:match("{%s*$")
      or reexport_closes(body, i, sides)) then
      kind = "imports"
      local _, o1 = text:gsub("[{(]", "")
      local _, c1 = text:gsub("[})]", "")
      for _, s in ipairs(sides) do open_import[s] = o1 > c1 end
    elseif comments[i] then
      kind = "comment"
    end
    kinds[i] = kind
  end
  return kinds
end

local function trim(s) return s:match("^%s*(.-)%s*$") end

local function is_change(line)
  local c = line:sub(1, 1)
  return c == "+" or c == "-"
end

local function squash(text, lang)
  local out, q, buf, i, n = {}, nil, {}, 1, #text
  while i <= n do
    local c = text:sub(i, i)
    if q then
      buf[#buf + 1] = c
      if c == "\\" and i < n then
        buf[#buf + 1] = text:sub(i + 1, i + 1)
        i = i + 1
      elseif c == q then
        local quoted = join(buf)
        local inner = quoted:sub(2, -2)
        local plain = q ~= "`" and QUOTE_STYLE[lang] and not inner:find("['\"\\]")
        out[#out + 1] = plain and ('"' .. inner .. '"') or quoted
        q, buf = nil, {}
      end
    elseif c == "'" or c == '"' or c == "`" then
      q, buf = c, { c }
    elseif (c == ")" or c == "]" or c == "}") and out[#out] == "," then
      out[#out] = c
    elseif not c:match("%s") then
      out[#out + 1] = c
    end
    i = i + 1
  end
  return join(out) .. join(buf)
end

local function change_blocks(body)
  local blocks, cur = {}, {}
  for i, l in ipairs(body) do
    if is_change(l) then
      cur[#cur + 1] = i
    elseif l:sub(1, 1) == " " and #cur > 0 then
      blocks[#blocks + 1] = cur
      cur = {}
    end
  end
  if #cur > 0 then blocks[#blocks + 1] = cur end
  return blocks
end

local function formatting_lines(lang, body)
  local hits = {}
  for _, blk in ipairs(change_blocks(body)) do
    local old, new, words = {}, {}, false
    for _, i in ipairs(blk) do
      local t = body[i]:sub(2)
      words = words or t:match("%S") ~= nil
      if body[i]:sub(1, 1) == "-" then old[#old + 1] = t else new[#new + 1] = t end
    end
    local same = not words
    if not same and SQUASH_OK[lang] then
      same = squash(join(old, "\n"), lang) == squash(join(new, "\n"), lang)
    end
    if not same and #old == #new then
      same = true
      for k = 1, #old do
        if (old[k]:gsub("%s+$", "")) ~= (new[k]:gsub("%s+$", "")) then
          same = false
          break
        end
      end
    end
    if same then
      for _, i in ipairs(blk) do hits[i] = true end
    end
  end
  return hits
end

local function moved_lines(files)
  local runs = { ["+"] = {}, ["-"] = {} }
  for _, f in ipairs(files) do
    for n, h in ipairs(f.hunks) do
      local key = f.path .. "#" .. n
      for _, blk in ipairs(change_blocks(h.body)) do
        for sign, list in pairs(runs) do
          local run = {}
          for _, i in ipairs(blk) do
            local t = trim(h.body[i]:sub(2))
            if h.body[i]:sub(1, 1) == sign and t ~= "" then run[#run + 1] = { i, t } end
          end
          if #run >= MOVE_K then list[#list + 1] = { key, run } end
        end
      end
    end
  end
  local function gram(run, j)
    local texts, chars = {}, 0
    for k = j, j + MOVE_K - 1 do
      texts[#texts + 1] = run[k][2]
      chars = chars + #run[k][2]
    end
    return table.concat(texts, "\n"), chars
  end
  local function mark(hits, key, run, j)
    hits[key] = hits[key] or {}
    for k = j, j + MOVE_K - 1 do hits[key][run[k][1]] = true end
  end
  local grams = {}
  for _, r in ipairs(runs["+"]) do
    for j = 1, #r[2] - MOVE_K + 1 do
      local g = gram(r[2], j)
      grams[g] = grams[g] or {}
      table.insert(grams[g], { r[1], r[2], j })
    end
  end
  local hits = {}
  for _, r in ipairs(runs["-"]) do
    for j = 1, #r[2] - MOVE_K + 1 do
      local g, chars = gram(r[2], j)
      if chars >= MOVE_MIN_CHARS then
        for _, added in ipairs(grams[g] or {}) do
          if added[1] ~= r[1] then
            mark(hits, r[1], r[2], j)
            mark(hits, added[1], added[2], added[3])
          end
        end
      end
    end
  end
  return hits
end

local function rule_entry(body, labels)
  local tally, kinds, real_count, changed = {}, 0, 0, 0
  for i, l in ipairs(body) do
    if is_change(l) then
      changed = changed + 1
      local r = labels[i]
      if r then
        if tally[r] == nil then
          tally[r] = 0
          kinds = kinds + 1
        end
        tally[r] = tally[r] + 1
      elseif l:sub(2):match("%S") then
        real_count = real_count + 1
      end
    end
  end
  if kinds == 0 then return nil end
  if kinds > 1 then tally.formatting = nil end
  local reason
  for _, r in ipairs(RULE_ORDER) do
    if tally[r] and (reason == nil or tally[r] > tally[reason]) then reason = r end
  end
  if real_count == 0 then return { keep = false, reason = reason } end
  local ranges, seg = {}, {}
  for i = 1, #body + 1 do
    if i == #body + 1 or labels[i] then
      local real = {}
      for _, j in ipairs(seg) do
        if is_change(body[j]) and body[j]:sub(2):match("%S") then real[#real + 1] = j end
      end
      if #real > 0 then
        local a0, b0 = math.max(real[1] - 1, seg[1]), math.min(real[#real] + 1, seg[#seg])
        local a = body[a0]:sub(1, 1) == " " and a0 or real[1]
        local b = body[b0]:sub(1, 1) == " " and b0 or real[#real]
        ranges[#ranges + 1] = { a, b }
      end
      seg = {}
    elseif not starts(body[i], "\\") then
      seg[#seg + 1] = i
    end
  end
  if #ranges == 1 and ranges[1][1] == 1 and ranges[1][2] == #body then return nil end
  return { keep = ranges, reason = reason }
end

function M.line_rules(files)
  local moved, entries = moved_lines(files), {}
  for _, f in ipairs(files) do
    local lang = ext_of(f.path)
    for n, h in ipairs(f.hunks) do
      local key = f.path .. "#" .. n
      local labels = {}
      local function label(reason, hit)
        for i, l in ipairs(h.body) do
          if is_change(l) and hit(i) then labels[i] = reason end
        end
      end
      local formatting, kinds, moves = formatting_lines(lang, h.body), line_kinds(f.path, h.body), moved[key] or {}
      label("formatting", function(i) return formatting[i] end)
      label("comment", function(i) return kinds[i] == "comment" end)
      label("imports", function(i) return kinds[i] == "imports" end)
      label("move/rename", function(i) return moves[i] end)
      entries[key] = rule_entry(h.body, labels)
    end
  end
  return entries
end

local function sub_hunk(h, a, b)
  if type(a) ~= "number" or type(b) ~= "number" or not (1 <= a and a <= b and b <= #h.body) then
    return nil
  end
  local old, new = h.old, h.new
  for k = 1, a - 1 do
    local c = h.body[k]:sub(1, 1)
    if c == " " or c == "-" then old = old + 1 end
    if c == " " or c == "+" then new = new + 1 end
  end
  local body = {}
  for k = a, b do body[#body + 1] = h.body[k] end
  if b < #h.body and starts(h.body[b + 1], "\\") then body[#body + 1] = h.body[b + 1] end
  local oc, nc = counts(body)
  local header = string.format("@@ -%d,%d +%d,%d @@%s", oc > 0 and old or math.max(old - 1, 0), oc,
    nc > 0 and new or math.max(new - 1, 0), nc, h.tail)
  table.insert(body, 1, header)
  return body
end

local function append(list, items)
  for _, item in ipairs(items) do list[#list + 1] = item end
end

function M.split(patch, out)
  local files = M.parse(read(patch))
  local by_line = M.line_rules(files)
  local made = rex.exec({ "mkdir", "-p", out })
  if made == nil or not made.ok then die(2, "can't create " .. out) end
  local triage, lines, total, by_path, auto_count = {}, {}, 0, 0, 0
  for _, f in ipairs(files) do
    local rule = path_rule(f.path)
    lines[#lines + 1] = "\n===== " .. f.path .. (rule and ("   [auto-hidden: " .. rule .. "]") or "")
    for n, h in ipairs(f.hunks) do
      total = total + 1
      local key = f.path .. "#" .. n
      if rule then
        triage[key] = { keep = false, reason = rule }
        by_path = by_path + 1
      else
        local auto = by_line[key]
        local mark = ""
        if auto then
          triage[key] = auto
          auto_count = auto_count + 1
          local what = "hidden"
          if auto.keep then
            local parts = {}
            for _, r in ipairs(auto.keep) do parts[#parts + 1] = "[" .. r[1] .. ", " .. r[2] .. "]" end
            what = "[" .. join(parts, ", ") .. "]"
          end
          mark = "   [auto: " .. auto.reason .. " " .. what .. "]"
        end
        lines[#lines + 1] = string.format("--- %s  (new-file lines from %d) %s%s", key, h.new,
          h.tail:match("^%s*(.-)%s*$"), mark)
        for i, l in ipairs(h.body) do lines[#lines + 1] = string.format("%4d %s", i, l) end
      end
    end
  end
  write(out .. "/hunks.txt", join(lines, "\n") .. "\n")
  write(out .. "/triage.json", encode(triage))
  print(string.format("%d hunks in %d files: %d hidden by path rules, %d cut by line rules, %d left to triage",
    total, #files, by_path, auto_count, total - by_path))
end

function M.build(patch, out)
  local files = M.parse(read(patch))
  local triage = rex.json.decode(read(out .. "/triage.json")) or die(1, "triage.json isn't JSON")
  local notes = { version = 1, files = {} }
  if exists(out .. "/notes.json") then
    notes = rex.json.decode(read(out .. "/notes.json")) or die(1, "notes.json isn't JSON")
    notes.files = notes.files or {}
  end
  local by_path = {}
  for _, f in ipairs(files) do by_path[f.path] = f end

  local errors = {}
  for key, entry in pairs(triage) do
    local path, n = key:match("^(.*)#([^#]*)$")
    local f = path and by_path[path]
    n = n and n:match("^%d+$") and tonumber(n)
    if not (f and n and n >= 1 and n <= #f.hunks) then
      errors[#errors + 1] = "unknown hunk " .. key
    elseif type(entry.keep) == "table" then
      local h = f.hunks[n]
      for _, r in ipairs(entry.keep) do
        if not (type(r) == "table" and #r == 2 and sub_hunk(h, r[1], r[2])) then
          errors[#errors + 1] = string.format("%s: range %s outside 1..%d", key, rex.json.encode(r), #h.body)
        end
      end
    end
  end
  if #errors > 0 then
    table.sort(errors)
    die(1, "triage.json is wrong:\n  " .. join(errors, "\n  "))
  end

  local patch_out, hidden, order, kept, is_kept = {}, {}, {}, {}, {}
  local function hide(reason, item)
    if hidden[reason] == nil then
      hidden[reason] = {}
      order[#order + 1] = reason
    end
    table.insert(hidden[reason], item)
  end
  for _, f in ipairs(files) do
    local chunks = {}
    if #f.hunks == 0 then hide("no text hunks (binary, mode or rename only)", f.path) end
    for n, h in ipairs(f.hunks) do
      local key = f.path .. "#" .. n
      local entry = triage[key] or { keep = true }
      if entry.keep == true then
        local oc, nc = counts(h.body)
        chunks[#chunks + 1] = string.format("@@ -%d,%d +%d,%d @@%s", h.old, oc, h.new, nc, h.tail)
        append(chunks, h.body)
      else
        hide(entry.reason or "unspecified", key .. (entry.keep and " (partial)" or ""))
        for _, r in ipairs(entry.keep or {}) do append(chunks, sub_hunk(h, r[1], r[2])) end
      end
    end
    if #chunks > 0 then
      append(patch_out, f.header)
      append(patch_out, chunks)
      kept[#kept + 1] = f.path
      is_kept[f.path] = true
    end
  end
  if #kept == 0 then die(1, "triage hides every hunk; nothing left to review") end
  write(out .. "/core.patch", join(patch_out, "\n") .. "\n")

  local dropped, note_files = {}, {}
  for _, x in ipairs(notes.files) do
    if is_kept[x.path] then note_files[#note_files + 1] = x else dropped[#dropped + 1] = x.path end
  end
  notes.files = note_files
  local total = 0
  for _, r in ipairs(order) do total = total + #hidden[r] end
  if total > 0 then
    local sorted = { unpack(order) }
    local position = {}
    for i, r in ipairs(order) do position[r] = i end
    table.sort(sorted, function(a, b)
      if #hidden[a] ~= #hidden[b] then return #hidden[a] > #hidden[b] end
      return position[a] < position[b]
    end)
    local by_reason, rationale = {}, {}
    for _, r in ipairs(sorted) do by_reason[#by_reason + 1] = r .. " " .. #hidden[r] end
    for _, r in ipairs(order) do rationale[#rationale + 1] = r .. ": " .. join(hidden[r], ", ") end
    local target
    for _, x in ipairs(notes.files) do
      if x.path == kept[1] then target = x break end
    end
    if target == nil then
      target = { path = kept[1], annotations = {} }
      table.insert(notes.files, 1, target)
    end
    target.annotations = target.annotations or {}
    table.insert(target.annotations, 1, {
      summary = string.format("Hidden from this view: %d hunks (%s)", total, join(by_reason, ", ")),
      rationale = join(rationale, "\n"),
      author = "core-patch",
    })
  end
  write(out .. "/sidecar.json", encode(notes))

  local manifest, live = { version = 1, files = {} }, {}
  for _, x in ipairs(notes.files) do
    local mine = {}
    for _, a in ipairs(x.annotations or {}) do
      if a.author == "core-patch" then
        mine[#mine + 1] = a
      else
        local c = { filePath = x.path, summary = a.summary, author = a.author or "agent", rationale = a.rationale }
        if a.newRange then c.newLine = a.newRange[1] else c.hunk = 1 end
        live[#live + 1] = c
      end
    end
    if #mine > 0 then manifest.files[#manifest.files + 1] = { path = x.path, annotations = mine } end
  end
  write(out .. "/manifest.json", encode(manifest))
  write(out .. "/live-notes.json", encode({ comments = live }))
  print(string.format("core.patch: %d files kept, %d hunks hidden, %d live notes", #kept, total, #live)
    .. (#dropped > 0 and ("; dropped notes on fully hidden files: " .. join(dropped, ", ")) or ""))
end

function M.verify(patch, worktree)
  local files = M.parse(read(patch))
  local bad, visible, hunks = 0, {}, 0
  for _, f in ipairs(files) do
    local target = worktree .. "/" .. f.path
    if not exists(target) then die(2, target .. " not found: is WORKTREE checked out at the PR head?") end
    local head = {}
    local text = read(target) .. "\n"
    for line in text:gmatch("(.-)\n") do head[#head + 1] = line end
    for n, h in ipairs(f.hunks) do
      local want = {}
      for _, l in ipairs(h.body) do
        local c = l:sub(1, 1)
        if c == " " or c == "+" then want[#want + 1] = l:sub(2) end
      end
      visible[f.path] = visible[f.path] or {}
      table.insert(visible[f.path], { h.new, h.new + #want - 1 })
      hunks = hunks + 1
      for k, w in ipairs(want) do
        if head[h.new + k - 1] ~= w then
          bad = bad + 1
          print(string.format("MISANCHORED HUNK %s hunk %d at new line %d", f.path, n, h.new))
          break
        end
      end
    end
  end
  local sidecar = patch:match("^(.*)/[^/]*$") or "."
  sidecar = sidecar .. "/sidecar.json"
  if exists(sidecar) then
    for _, f in ipairs((rex.json.decode(read(sidecar)) or {}).files or {}) do
      for _, a in ipairs(f.annotations or {}) do
        local r = a.newRange
        if r then
          local ok = false
          for _, v in ipairs(visible[f.path] or {}) do
            if v[1] <= r[1] and r[2] <= v[2] then ok = true end
          end
          if not ok then
            bad = bad + 1
            print(string.format("NOTE OFF-VIEW %s [%d, %d]: %s", f.path, r[1], r[2], (a.summary or ""):sub(1, 60)))
          end
        end
      end
    end
  end
  if bad > 0 then die(1, "verify: " .. bad .. " problems") end
  print(string.format("verify: %d hunks anchored, every note visible", hunks))
end

local function git(worktree, argv, ok_codes)
  local cmd = { "git", "-C", worktree }
  append(cmd, argv)
  local r = rex.exec(cmd)
  if r == nil then die(2, "git is not on PATH") end
  local ok = r.ok
  for _, code in ipairs(ok_codes or {}) do ok = ok or r.code == code end
  if not ok then die(2, "git " .. join(argv, " ") .. ": " .. trim(r.stderr)) end
  return r.stdout
end

local function default_base(worktree)
  local r = rex.exec({ "git", "-C", worktree, "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD" })
  if r == nil then die(2, "git is not on PATH") end
  local head = r.ok and trim(r.stdout) or ""
  if head ~= "" then return (head:gsub("^refs/remotes/", "")) end
  return "origin/main"
end

function M.diff(worktree, out, base)
  base = base or default_base(worktree)
  local mb = trim(git(worktree, { "merge-base", base, "HEAD" }))
  local parts = { git(worktree, { "diff", "--no-color", "--no-ext-diff", mb }) }
  local listed = git(worktree, { "ls-files", "--others", "--exclude-standard", "-z" })
  local untracked = 0
  for f in listed:gmatch("[^%z]+") do
    untracked = untracked + 1
    parts[#parts + 1] = git(worktree, { "diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", f }, { 1 })
  end
  local text = join(parts)
  local made = rex.exec({ "mkdir", "-p", out })
  if made == nil or not made.ok then die(2, "can't create " .. out) end
  write(out .. "/full.patch", text)
  if not text:match("%S") then die(3, "no changes in " .. worktree .. " since " .. base .. " (" .. mb:sub(1, 12) .. ")") end
  print(string.format("%s/full.patch: changes since %s (%s), %d untracked files included", out, base, mb:sub(1, 12),
    untracked))
end

local USAGE = [[
usage: rex do core_patch.lua cmd=diff   worktree=WORKTREE out=OUTDIR [base=REF]
       rex do core_patch.lua cmd=split  patch=FULL.patch out=OUTDIR
       rex do core_patch.lua cmd=build  patch=FULL.patch out=OUTDIR
       rex do core_patch.lua cmd=verify patch=CORE.patch worktree=WORKTREE]]

local args = rex.args
if type(args) == "table" and args.cmd ~= nil then
  local ok, err = pcall(function()
    if args.cmd == "diff" then
      if args.worktree == nil or args.out == nil then die(2, USAGE) end
      local base = args.base
      if type(base) == "number" then
        if base ~= math.floor(base) or math.abs(base) >= 2 ^ 53 then
          die(2, "base= was read as the number " .. tostring(base) .. ": pass it with --args '{\"base\": \"REF\"}'")
        end
        base = string.format("%d", base)
      end
      return M.diff(tostring(args.worktree), tostring(args.out), base and tostring(base))
    end
    local run = ({ split = M.split, build = M.build, verify = M.verify })[args.cmd]
    local second = args.cmd == "verify" and args.worktree or args.out
    if run == nil or args.patch == nil or second == nil then die(2, USAGE) end
    run(tostring(args.patch), tostring(second))
  end)
  if not ok then
    if getmetatable(err) ~= Failure then error(err, 0) end
    io.stderr:write(err.msg .. "\n")
    rex.stop(err.code)
  end
  return
end

return M
