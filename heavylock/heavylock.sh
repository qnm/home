lock="$HOME/.cache/claude-heavy.lock"
wait_s=${HEAVYLOCK_WAIT:-300}
pattern='(^|[^[:alnum:]_-])(eslint|tsc|tsgo|jest|vitest|typecheck|lint|check|test)([^[:alnum:]_-]|$)|git( +-C +[^ ]+)? +commit'

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")

[ -z "$cmd" ] && exit 0
case "$cmd" in *claude-heavy.lock*) exit 0 ;; esac
grep -qE "$pattern" <<<"$cmd" || exit 0

flock_bin=$(command -v flock)
wrapped=$(printf '{ %s -w %s 9 || true\n%s\n} 9>%s' "$flock_bin" "$wait_s" "$cmd" "$lock")

jq -n --argjson in "$(jq '.tool_input' <<<"$input")" --arg c "$wrapped" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    updatedInput: ($in + { command: $c, timeout: 600000 })
  }
}'
