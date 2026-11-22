local TERMINAL = "com.superlogical.terminal"
local SHELL = TERMINAL .. ".shell"
local script = os.getenv("HOME") .. "/.config/rex/hunk/hunk-core.sh"

local function call(method, params)
  local result, err = rex.call(method, params)
  if err ~= nil then error("hunk: " .. method .. ": " .. err, 0) end
  return result
end

local function cwd(ctx)
  if ctx.block_id == nil then return nil end
  local info = rex.block.call(TERMINAL, "process", { session_id = ctx.session_id, block_id = ctx.block_id })
  return type(info) == "table" and type(info.foreground) == "table" and info.foreground.cwd or nil
end

local function open(ctx, anchor, label, dir, focus, ...)
  local options = { command = { script, ... }, interactive = true }
  if dir ~= nil and dir ~= "" then options.cwd = dir end
  local split = call("session.new_split", {
    session_id = ctx.session_id,
    anchor_id = anchor,
    direction = "horizontal",
    side = "after",
    ratio = 0.4,
    focus = focus,
    layout = { block = { flavor = SHELL, label = label, options = options } },
  })
  return split.block_ids[1]
end

local WORKTREES = [[
common=$(git rev-parse --path-format=absolute --git-common-dir) || exit 1
for d in "$common"/worktrees/*/; do
  [ -f "$d/gitdir" ] || continue
  w=$(dirname "$(cat "$d/gitdir")")
  [ -d "$w" ] || continue
  printf '%s\t%s\t%s\n' "$(stat -f %m "$d/index" 2>/dev/null || echo 0)" "$w" "$(sed 's|^ref: refs/heads/||' "$d/HEAD")"
done
]]

local function has_changes(dir)
  local dirty = rex.exec({ "git", "diff", "--quiet", "HEAD" }, { cwd = dir, timeout = 10 })
  if dirty == nil or dirty.code ~= 0 then return dirty ~= nil and dirty.code == 1 end
  local base = rex.exec({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" }, { cwd = dir, timeout = 5 })
  local ref = base and base.ok and base.stdout:match("%S+") or "origin/main"
  local ahead = rex.exec({ "git", "rev-list", "--count", ref .. "..HEAD" }, { cwd = dir, timeout = 10 })
  return ahead ~= nil and ahead.ok and tonumber(ahead.stdout) ~= 0
end

local function pick_worktree(dir)
  if type(rex.ui) ~= "table" or type(rex.ui.pick) ~= "function" then return nil end
  local r = rex.exec({ "/bin/sh", "-c", WORKTREES }, { cwd = dir, timeout = 10 })
  if r == nil or not r.ok then return nil end
  local rows = {}
  for mtime, path, branch in r.stdout:gmatch("(%d+)\t([^\t]+)\t([^\n]*)\n") do
    if path ~= dir then rows[#rows + 1] = { mtime = tonumber(mtime), path = path, branch = branch } end
  end
  if #rows == 0 then return nil end
  table.sort(rows, function(x, y) return x.mtime > y.mtime end)
  local items = {}
  for _, row in ipairs(rows) do
    items[#items + 1] = { id = row.path, title = row.path:match("([^/]+)$"), subtitle = row.branch, icon = "folder" }
  end
  local answer = rex.ui.pick{
    title = "Nothing to review in " .. dir:match("([^/]+)$") .. ". Review which worktree?",
    placeholder = "Filter worktrees",
    items = items,
  }
  return answer
end

local function review(label, ...)
  local fixed = { ... }
  return function(ctx, a)
    local target = a and a.target
    local args = (target ~= nil and target ~= "") and { tostring(target) } or fixed
    local dir = cwd(ctx)
    if (#args == 0 or args[1] == "--branch") and dir ~= nil and not has_changes(dir) then
      local picked = pick_worktree(dir)
      if picked ~= nil then dir = picked end
    end
    open(ctx, ctx.block_id, label, dir, true, unpack(args))
  end
end

local HIDES = "Tests, lockfiles, generated code, and edits that only touch imports, comments or whitespace are hidden."

rex.action{
  name = "hunk_core",
  title = "Hunk: Review Core Diff",
  description = "Review this pane's working tree changes, or a PR given as target, in Hunk. " .. HIDES,
  category = "Hunk",
  keywords = "hunk diff review core changes pr pull request",
  args = { target = "string?" },
  run = review("hunk core"),
}

rex.action{
  name = "hunk_core_staged",
  title = "Hunk: Review Core of Staged Changes",
  description = "Review what's staged in Hunk. " .. HIDES,
  category = "Hunk",
  keywords = "hunk diff review core staged index commit",
  run = review("hunk staged", "--staged"),
}

rex.action{
  name = "hunk_core_branch",
  title = "Hunk: Review Core of This Branch",
  description = "Review this branch against its base in Hunk. " .. HIDES,
  category = "Hunk",
  keywords = "hunk diff review core branch pr pull request",
  run = review("hunk branch", "--branch"),
}

rex.action{
  name = "hunk_core_open",
  title = "Hunk: Open Core View",
  description = "Open a core view the hunk-core-view skill built in out, beside the PR's review tab.",
  category = "Hunk",
  keywords = "hunk core view skill",
  args = { out = "string", pr = "string", worktree = "string?" },
  run = function(ctx, a)
    local pr = tostring(a.pr)
    local label = "hunk-" .. pr
    local anchor, tab
    for _, window in ipairs(call("session.view", { session_id = ctx.session_id }).windows or {}) do
      local owns = window.label == "review-" .. pr or window.label == "core-" .. pr
      for _, layer in ipairs(window.layers or {}) do
        for _, block in ipairs(layer.blocks or {}) do
          if block.label == label then
            call("block.close", { session_id = ctx.session_id, block_id = block.block_id })
          elseif owns and anchor == nil and not (block.label or ""):match("^hunk%-") then
            anchor, tab = block.block_id, window.label
          end
        end
      end
    end
    local block = open(ctx, anchor or ctx.block_id, label, a.worktree, false, "--open", a.out)
    return { block_id = block, tab = tab }
  end,
}
