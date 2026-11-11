local terminal = "com.superlogical.terminal"
local home = assert(os.getenv("HOME"), "HOME isn't set")
local snapshot_path = assert(rex.args.snapshot, "pass snapshot=PATH")
local snapshot_version = 1

local function call(method, params)
  local result, err = rex.call(method, params)
  if err ~= nil then error(method .. ": " .. err, 0) end
  return result
end

local function exec(argv, opts)
  local r, err = rex.exec(argv, opts)
  if r == nil then error(argv[1] .. ": " .. err, 0) end
  return r
end

local function applescript_string(text)
  return '"' .. text:gsub("[\\\"]", "\\%0"):gsub("%s+", " ") .. '"'
end

local function notify(text)
  rex.log("error", text)
  local r = exec{
    "/usr/bin/osascript", "-e",
    "display notification " .. applescript_string(text) .. ' with title "Rex restore"',
  }
  if not r.ok then rex.log("error", "osascript failed: " .. r.stderr) end
end

local function read_file(path)
  local f = io.open(path, "r")
  if f == nil then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function server_instance()
  return call("server.status").instance_id
end

local function block_call(block, method, params)
  params = params or {}
  params.session_id, params.block_id = block.session_id, block.block_id
  local result, err = rex.block.call(terminal, method, params)
  if err ~= nil then error(method .. " of " .. block.block_id .. ": " .. err, 0) end
  return result
end

local function at_shell(p)
  local fg, child = p.foreground, p.child
  if fg == nil or child == nil or fg.cwd == nil then return false end
  if fg.pid == child.pid then return true end
  local parent = p.ancestors and p.ancestors[1]
  return parent ~= nil and parent.pid == child.pid
end

local function program_name(fg)
  return (((fg.argv0 or fg.name):match("([^/]+)$")):gsub("^%-", ""))
end

local function terminal_blocks()
  local blocks = {}
  local sessions = call("session.list").sessions
  for _, session in ipairs(sessions) do
    local view = call("session.attach", { session_id = session.session_id }).view
    for _, window in ipairs(view.windows) do
      for _, layer in ipairs(window.layers) do
        for _, block in ipairs(layer.blocks) do
          if block.creator_name == terminal then
            table.insert(blocks, {
              block_id = block.block_id,
              session_id = session.session_id,
              session = session.label,
              window = window.label,
            })
          end
        end
      end
    end
  end
  return blocks, #sessions
end

local function claude_session(pid)
  local text = read_file(home .. "/.claude/sessions/" .. pid .. ".json")
  if text == nil then return nil, "Claude Code hasn't recorded its session" end
  local state = rex.json.decode(text)
  if state == nil or state.pid ~= pid or type(state.sessionId) ~= "string"
    or not state.sessionId:match("^[%w-]+$") then
    return nil, "Claude Code's session file for PID " .. pid .. " isn't as expected"
  end
  local found = exec({
    "/bin/sh", "-c",
    'for f in "$HOME"/.claude/projects/*/"$1".jsonl; do [ -e "$f" ] && exit 0; done; exit 1',
    "sh", state.sessionId,
  }).ok
  return found and state.sessionId or nil
end

local function snapshot_programs()
  local blocks, session_count = terminal_blocks()
  local programs = {}
  for _, block in ipairs(blocks) do
    local p = block_call(block, "process")
    local fg = p.foreground
    if not at_shell(p) and fg ~= nil and fg.cwd ~= nil and program_name(fg) == "claude" then
      local id, err = claude_session(fg.pid)
      local entry = err ~= nil and { error = err } or id and { session_id = id }
      if entry then
        entry.block_id = block.block_id
        entry.session = block.session
        entry.window = block.window
        entry.cwd = fg.cwd
        table.insert(programs, entry)
      end
    end
  end
  table.sort(programs, function(a, b) return a.block_id < b.block_id end)
  return programs, session_count
end

local function valid_snapshot(snapshot)
  if type(snapshot) ~= "table" or snapshot.version ~= snapshot_version
    or type(snapshot.server_instance) ~= "string" then
    return false
  end
  snapshot.programs = snapshot.programs or {}
  if type(snapshot.programs) ~= "table" then return false end
  for _, entry in ipairs(snapshot.programs) do
    if type(entry) ~= "table" or type(entry.block_id) ~= "string"
      or type(entry.cwd) ~= "string"
      or (type(entry.session_id) ~= "string") == (type(entry.error) ~= "string")
      or (entry.session_id ~= nil and not entry.session_id:match("^[%w-]+$")) then
      return false
    end
  end
  return true
end

local function load_snapshot()
  local text = read_file(snapshot_path)
  if text == nil then return nil end
  local snapshot = rex.json.decode(text)
  if valid_snapshot(snapshot) then return snapshot end
  local aside = snapshot_path .. ".unreadable-" .. os.time()
  assert(os.rename(snapshot_path, aside))
  notify("The snapshot of Claude sessions to restore was unreadable, so nothing was restored. It's kept at " .. aside)
  return nil
end

local function write_atomically(path, text)
  local tmp = path .. ".tmp"
  local f = assert(io.open(tmp, "w"))
  assert(f:write(text))
  assert(f:close())
  assert(os.rename(tmp, path))
end

local function write_snapshot(snapshot)
  local text = assert(rex.json.encode(snapshot, { indent = true })) .. "\n"
  if text ~= read_file(snapshot_path) then write_atomically(snapshot_path, text) end
end

local function describe(entry)
  return string.format("claude in %s › %s", entry.session or "?", entry.window or "?")
end

local function wait_for_shell(block)
  local p
  for _ = 1, 40 do
    p = block_call(block, "process")
    if at_shell(p) then
      rex.sleep(1)
      return p.foreground
    end
    rex.sleep(0.25)
  end
  return nil, p.foreground
end

local function restore_program(entry, block, resumed)
  if block == nil then return "Rex didn't restore its pane" end
  if entry.session_id ~= nil and resumed[entry.session_id] then
    return "its session is already resumed in another pane"
  end
  local fg = block_call(block, "process").foreground
  if fg ~= nil and program_name(fg) == "claude" then
    if entry.session_id ~= nil then resumed[entry.session_id] = true end
    rex.log("info", describe(entry) .. " is still running")
    return nil
  end
  if entry.error ~= nil then return entry.error end
  local shell, busy = wait_for_shell(block)
  if shell == nil then
    return "its pane is running " .. (busy and program_name(busy) or "something else")
  end
  if shell.cwd ~= entry.cwd then
    return "its pane is in " .. tostring(shell.cwd) .. ", not " .. entry.cwd
  end
  local line = "claude --resume " .. entry.session_id
  block_call(block, "write", { data = line .. "\r" })
  resumed[entry.session_id] = true
  rex.log("info", "restored " .. describe(entry) .. ": " .. line)
  return nil
end

local function restore(snapshot)
  local blocks = {}
  for _, block in ipairs((terminal_blocks())) do blocks[block.block_id] = block end
  local failures, resumed = {}, {}
  for _, entry in ipairs(snapshot.programs) do
    local ok, why = pcall(restore_program, entry, blocks[entry.block_id], resumed)
    if not ok or why ~= nil then
      local failure = describe(entry) .. ": " .. tostring(why)
      rex.log("error", "couldn't restore " .. failure)
      table.insert(failures, failure)
    end
  end
  if #failures > 0 then
    notify(string.format("Couldn't restore %d of %d Claude sessions: %s", #failures,
      #snapshot.programs, table.concat(failures, "; ")))
  end
  rex.log("info", string.format("restored %d of %d Claude sessions",
    #snapshot.programs - #failures, #snapshot.programs))
end

local instance = server_instance()
local previous = load_snapshot()
local restored_for = snapshot_path .. ".restored-for"
if previous ~= nil and previous.server_instance ~= instance
  and read_file(restored_for) ~= instance then
  write_atomically(restored_for, instance)
  write_atomically(snapshot_path .. ".previous", read_file(snapshot_path))
  restore(previous)
end

local function save()
  if server_instance() ~= instance then
    rex.log("error", "the Rex server restarted; stopping so the restart restores its sessions")
    rex.stop(1)
  end
  local programs, session_count = snapshot_programs()
  if session_count == 0 then return end
  write_snapshot{
    version = snapshot_version,
    server_instance = instance,
    programs = programs,
  }
end

save()

local pending
local function save_soon()
  if pending ~= nil then pending:cancel() end
  pending = rex.after(2, save)
end
for _, event in ipairs({ "terminal.process_changed", "block_closed", "session_destroyed" }) do
  rex.on(event, save_soon)
end
rex.every(30, save)
