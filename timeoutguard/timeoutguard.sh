pattern='(^|[;&|(!]|&&|\|\||\$\()[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*timeout[[:space:]]'

cmd=$(jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0
grep -qE "$pattern" <<<"$cmd" || exit 0

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "timeout is not installed on this Mac, so the command would exit 127. Drop the prefix and set the Bash tool'"'"'s timeout parameter instead."
  }
}'
