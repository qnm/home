local here = rex.args.repo
local session = rex.args.session or rex.session_id

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

local function gh_prs()
  local argv = { "gh", "search", "prs", "--review-requested=@me", "--state=open", "--limit", "200",
    "--json", "repository,number,isDraft,author" }
  local r = rex.exec(argv, { timeout = 60 })
  if r == nil then return nil, "gh is not on PATH" end
  local prs = r.ok and rex.json.decode(r.stdout)
  if type(prs) ~= "table" then
    local msg = trim(r.stderr ~= "" and r.stderr or r.stdout)
    return nil, "`gh search prs` failed: " .. msg:sub(1, 300)
  end
  return prs
end

local function tab_labels()
  local view, err = rex.call("session.view", { session_id = session })
  if type(view) ~= "table" and rex.call("session.attach", { session_id = session }) then
    view, err = rex.call("session.view", { session_id = session })
  end
  if type(view) ~= "table" then return nil, "session " .. session .. " unavailable: " .. tostring(err) end
  local tabs = {}
  for _, w in ipairs(type(view.windows) == "table" and view.windows or {}) do
    if type(w.label) == "string" then tabs[w.label] = true end
  end
  return tabs
end

local function is_bot(author)
  if type(author) ~= "table" then return false end
  local login = type(author.login) == "string" and author.login or ""
  return author.is_bot == true or author.type == "Bot" or login:sub(-5) == "[bot]"
end

local function pick()
  if here == nil then return 2, "usage: rex do pick_prs.lua repo=OWNER/REPO [session=SESSION_ID]" end
  if session == nil then return 2, "no Rex session: run inside Rex or pass session=SESSION_ID" end
  here, session = tostring(here), tostring(session)
  local prs, err = gh_prs()
  if prs == nil then return 2, err end
  local tabs
  tabs, err = tab_labels()
  if tabs == nil then return 2, err end
  local picked, skipped = {}, { draft = 0, bot = 0, tab = 0 }
  for _, pr in ipairs(prs) do
    local repo = type(pr.repository) == "table" and pr.repository.nameWithOwner or ""
    local number = string.format("%d", tonumber(pr.number) or 0)
    local suffix = repo == here and number or ((repo:match("/(.*)$") or repo) .. "-" .. number)
    if pr.isDraft == true then
      skipped.draft = skipped.draft + 1
    elseif is_bot(pr.author) then
      skipped.bot = skipped.bot + 1
    elseif tabs["core-" .. suffix] or tabs["review-" .. suffix] then
      skipped.tab = skipped.tab + 1
    else
      picked[#picked + 1] = repo .. " " .. number .. " core-" .. suffix
    end
  end
  for _, line in ipairs(picked) do print(line) end
  local summary = string.format("%d requested: %d new; skipped %d draft, %d bot, %d has a tab",
    #prs, #picked, skipped.draft, skipped.bot, skipped.tab)
  return #picked > 0 and 0 or 3, summary
end

local code, msg = pick()
if msg then io.stderr:write(msg .. "\n") end
rex.stop(code)
