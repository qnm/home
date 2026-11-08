local terminal = "com.superlogical.terminal"

local function call(method, params)
  local result, err = rex.call(method, params)
  if err ~= nil then error(method .. ": " .. err, 0) end
  return result
end

local history = { session = {}, pane_by_window = {} }

local function visit(h, from, to)
  if h.seen ~= nil and h.seen ~= from then h.other = h.seen end
  if to ~= from then h.other = from end
  h.seen = to
end

local function require_ctx(ctx, field, action)
  if ctx[field] == nil then error(action .. ": Rex gave no " .. field, 0) end
  return ctx[field]
end

local function session_ids()
  local ids = {}
  for _, session in ipairs(call("session.list").sessions) do
    table.insert(ids, session.session_id)
  end
  return ids
end

local function index_of(list, value)
  for i, item in ipairs(list) do
    if item == value then return i end
  end
  return nil
end

local function switch_session(from, to)
  visit(history.session, from, to)
  rex.client.queue("session.select", { session_id = to })
end

rex.action{
  name  = "last_session",
  title = "Go to Last Session",
  run   = function(ctx)
    local from = require_ctx(ctx, "session_id", "last_session")
    local h = history.session
    visit(h, from, from)
    if h.other == nil then error("last_session: no earlier session yet", 0) end
    if index_of(session_ids(), h.other) == nil then
      h.other = nil
      error("last_session: the last session has closed", 0)
    end
    switch_session(from, h.other)
  end,
}

local function window_holding(view, block_id)
  for _, window in ipairs(view.windows) do
    for _, layer in ipairs(window.layers) do
      for _, block in ipairs(layer.blocks) do
        if block.block_id == block_id then return window end
      end
    end
  end
  return nil
end

local function session_view(session)
  return call("session.view", { session_id = session })
end

local function pane_history(ctx, action)
  local session = require_ctx(ctx, "session_id", action)
  local block = require_ctx(ctx, "block_id", action)
  local window = window_holding(session_view(session), block)
  if window == nil then error(action .. ": the focused pane isn't in any tab", 0) end
  local h = history.pane_by_window[window.window_id] or {}
  history.pane_by_window[window.window_id] = h
  return h, session, block, window
end

rex.action{
  name  = "last_pane",
  title = "Focus Last Pane in Tab",
  run   = function(ctx)
    local h, session, from, window = pane_history(ctx, "last_pane")
    visit(h, from, from)
    if h.other == nil then error("last_pane: no earlier pane in this tab yet", 0) end
    local target = window_holding(session_view(session), h.other)
    if target == nil or target.window_id ~= window.window_id then
      h.other = nil
      error("last_pane: the last pane in this tab has closed", 0)
    end
    local to = h.other
    call("session.focus_block", { session_id = session, block_id = to })
    visit(h, from, to)
  end,
}

local status_priority = { blocked = 4, done = 3, error = 3, working = 2, idle = 1 }

local status_since = {}

local function root_status(session, block_id)
  local status = call(terminal .. ".program_status", {
    session_id = session,
    block_id   = block_id,
    args       = {},
  })
  for _, record in ipairs(status.records) do
    if record.id == nil then return record end
  end
  return nil
end

local function agent_panes()
  local panes = {}
  local seen = {}
  for _, session in ipairs(session_ids()) do
    local view = call("session.attach", { session_id = session }).view
    for _, window in ipairs(view.windows) do
      for _, layer in ipairs(window.layers) do
        for _, block in ipairs(layer.blocks) do
          local record = block.creator_name == terminal and root_status(session, block.block_id)
          if record then
            local previous = status_since[block.block_id]
            local since = record.updated_at
            if previous ~= nil and previous.state == record.state then since = previous.since end
            seen[block.block_id] = { state = record.state, since = since }
            table.insert(panes, {
              session  = session,
              window   = window,
              block_id = block.block_id,
              priority = status_priority[record.state] or status_priority.idle,
              since    = since,
              position = #panes,
            })
          end
        end
      end
    end
  end
  status_since = seen
  table.sort(panes, function(a, b)
    if a.priority ~= b.priority then return a.priority > b.priority end
    if a.since ~= b.since then return a.since > b.since end
    return a.position < b.position
  end)
  return panes
end

local function focus_agent(ctx, offset, action)
  local from_session = require_ctx(ctx, "session_id", action)
  local panes = agent_panes()
  if #panes == 0 then return end
  local current = nil
  for i, pane in ipairs(panes) do
    if pane.session == from_session and pane.block_id == ctx.block_id then current = i end
  end
  local target
  if current ~= nil then
    target = panes[(current - 1 + offset) % #panes + 1]
  elseif offset > 0 then
    target = panes[1]
  else
    target = panes[#panes]
  end

  local window_id = target.window.window_id
  local h = history.pane_by_window[window_id] or {}
  history.pane_by_window[window_id] = h
  call("session.focus_block", { session_id = target.session, block_id = target.block_id })
  visit(h, target.window.focused_block_id, target.block_id)
  if target.session ~= from_session then switch_session(from_session, target.session) end
end

rex.action{
  name  = "next_agent",
  title = "Focus Next Agent",
  run   = function(ctx) focus_agent(ctx, 1, "next_agent") end,
}

rex.action{
  name  = "previous_agent",
  title = "Focus Previous Agent",
  run   = function(ctx) focus_agent(ctx, -1, "previous_agent") end,
}

rex.bind("cmd+j", "next_agent")
rex.bind("cmd+k", "previous_agent")
rex.bind("cmd+l", "last_pane")
rex.bind("cmd+,", "last_session")
