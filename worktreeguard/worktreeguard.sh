pattern='(^|[;&|(]|&&|\|\||\$\()[[:space:]]*git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)*worktree[[:space:]]+add[[:space:]][^;&|]*'

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

adds=$(grep -oE "$pattern" <<<"$cmd" || true)
[ -n "$adds" ] || exit 0
grep -qvF '.claude/worktrees/' <<<"$adds" || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input")
root=$(git -C "${cwd:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
root=${root%/.git}
target="${root:-<main checkout>}/.claude/worktrees/<slug>"

jq -n --arg target "$target" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Worktrees live at \($target). Write that path out in the git worktree add command, or use EnterWorktree or `claude -w <slug>`. Other folders in git worktree list are old and are not the convention."
  }
}'
