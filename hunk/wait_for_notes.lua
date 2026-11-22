local session = rex.args.session
local seen_file = rex.args.seen
local timeout = tonumber(rex.args.timeout) or 1800
local interval = tonumber(rex.args.interval) or 3

if session == nil or seen_file == nil then
  io.stderr:write("usage: rex do wait_for_notes.lua session=SESSION_ID seen=SEEN_FILE [timeout=S] [interval=S]\n")
  rex.stop(2)
  return
end
session, seen_file = tostring(session), tostring(seen_file)

local function user_notes()
  local r = rex.exec({ "hunk", "session", "comment", "list", session, "--type", "user", "--json" }, { timeout = 30 })
  if r == nil then return nil, "hunk is not on PATH" end
  local data = r.stdout ~= "" and rex.json.decode(r.stdout) or {}
  if type(data) ~= "table" then data = {} end
  if not r.ok or data.comments == nil then
    local msg = type(data.error) == "table" and data.error.message
    if msg == nil or msg == "" then msg = r.stderr:match("^%s*(.-)%s*$") end
    if msg == "" then msg = "no comment list returned" end
    return nil, "session " .. session .. " unavailable: " .. msg
  end
  return data.comments
end

local function wait()
  local seen = {}
  local f = io.open(seen_file, "r")
  if f then
    local text = f:read("*a")
    f:close()
    for id in text:gmatch("%S+") do seen[id] = true end
  end
  local deadline = os.time() + timeout
  while true do
    local notes, err = user_notes()
    if notes == nil then return 2, err end
    local new = {}
    for _, n in ipairs(notes) do
      if n.noteId and not seen[n.noteId] then new[#new + 1] = n end
    end
    if #new > 0 then
      local out = assert(io.open(seen_file, "a"))
      for _, n in ipairs(new) do out:write(n.noteId .. "\n") end
      out:close()
      for _, n in ipairs(new) do print(rex.json.encode(n)) end
      return 0
    end
    if os.time() >= deadline then return 3, string.format("no new note in %gs", timeout) end
    rex.sleep(interval)
  end
end

local code, msg = wait()
if msg then io.stderr:write(msg .. "\n") end
rex.stop(code)
