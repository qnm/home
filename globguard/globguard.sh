pattern="(^|[[:space:]])--?[A-Za-z][A-Za-z0-9-]*=[^[:space:]'\"\\\\]*[*?][^[:space:]]*"

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

hits=$(grep -oE -- "$pattern" <<<"$cmd" | sed 's/^[[:space:]]*//' | sort -u | paste -sd ' ' - || true)
[ -n "$hits" ] || exit 0

jq -n --arg hits "$hits" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "The Bash tool runs zsh, which expands an unquoted glob before the command runs and fails with \"no matches found\": \($hits). Quote the value, for example --include='\''*.ts'\''."
  }
}'
