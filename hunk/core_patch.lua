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

local C_LIKE = { "//", "/*", "*", "*/" }
local COMMENTS = { css = { "/*", "*", "*/" } }
for _, e in ipairs({ "ts", "tsx", "js", "jsx", "mjs", "cjs", "go", "rs", "java", "kt", "swift", "c", "h", "cpp",
  "cs", "scss" }) do
  COMMENTS[e] = C_LIKE
end
for _, e in ipairs({ "py", "sh", "bash", "zsh", "fish", "rb", "yml", "yaml", "toml", "nix", "tf" }) do
  COMMENTS[e] = { "#" }
end
for _, e in ipairs({ "lua", "sql" }) do COMMENTS[e] = { "--" } end

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

local function line_kinds(path, body)
  local name = path:match("([^/]*)$")
  local ext = name:match("%.([^.]*)$") or ""
  local prefixes, start = COMMENTS[ext], IMPORT_START[ext]
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
    elseif prefixes then
      local body_text = text:match("^%s*(.*)$")
      for _, p in ipairs(prefixes) do
        if starts(body_text, p) then kind = "comment" break end
      end
    end
    kinds[i] = kind
  end
  return kinds
end

local function stripped_sorted(body, idx, sign)
  local out = {}
  for _, i in ipairs(idx) do
    if body[i]:sub(1, 1) == sign then out[#out + 1] = body[i]:sub(2):gsub("%s", "") end
  end
  table.sort(out)
  return join(out, "\n"), #out
end

function M.line_rule(path, h)
  local body = h.body
  local changed, is_changed = {}, {}
  for i, l in ipairs(body) do
    local c = l:sub(1, 1)
    if c == "-" or c == "+" then
      changed[#changed + 1] = i
      is_changed[i] = true
    end
  end
  if #changed == 0 then return nil end
  local removed, nr = stripped_sorted(body, changed, "-")
  local added, na = stripped_sorted(body, changed, "+")
  if nr == na and removed == added then return { keep = false, reason = "formatting" } end
  local kinds = line_kinds(path, body)
  local noise, noise_count, real_noise, seen, hidden = {}, 0, 0, {}, {}
  for _, i in ipairs(changed) do
    if kinds[i] then
      noise[i] = true
      noise_count = noise_count + 1
      if kinds[i] ~= "blank" then
        real_noise = real_noise + 1
        if not seen[kinds[i]] then
          seen[kinds[i]] = true
          hidden[#hidden + 1] = kinds[i]
        end
      end
    end
  end
  table.sort(hidden)
  local reason = #hidden > 0 and join(hidden, ", ") or "formatting"
  if noise_count == #changed then return { keep = false, reason = reason } end
  if real_noise == 0 then return nil end
  local ranges, seg = {}, {}
  for i = 1, #body + 1 do
    if i == #body + 1 or noise[i] then
      local real = {}
      for _, j in ipairs(seg) do
        if is_changed[j] then real[#real + 1] = j end
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
        local auto = M.line_rule(f.path, h)
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

local USAGE = [[
usage: rex do core_patch.lua cmd=split  patch=FULL.patch out=OUTDIR
       rex do core_patch.lua cmd=build  patch=FULL.patch out=OUTDIR
       rex do core_patch.lua cmd=verify patch=CORE.patch worktree=WORKTREE]]

local args = rex.args
if type(args) == "table" and args.cmd ~= nil then
  local run = ({ split = M.split, build = M.build, verify = M.verify })[args.cmd]
  local second = args.cmd == "verify" and args.worktree or args.out
  local ok, err = pcall(function()
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
