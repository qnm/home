dir="$HOME/.cache/claude-pushgate"
pattern='(^|[^[:alnum:]_-])git( +-C +[^ ]+)? +push([[:space:]]|$)'

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
session=$(jq -r '.session_id // empty' <<<"$input")
event=$(jq -r '.hook_event_name // empty' <<<"$input")

if [ -z "$cmd" ] || [ -z "$session" ]; then exit 0; fi
grep -qE "$pattern" <<<"$cmd" || exit 0

marker="$dir/$session"

case "$event" in
  PostToolUseFailure|PermissionDenied)
    mkdir -p "$dir"
    printf '%s\n' "$cmd" >"$marker"
    ;;
  PreToolUse)
    [ -f "$marker" ] || exit 0
    jq -n --arg prev "$(cat "$marker")" --arg m "$marker" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("A git push already failed in this session: " + $prev + "\nDo not retry. Report the error, then hand Rob a ! push command pinned to a SHA. To unblock, Rob deletes " + $m + ".")
      }
    }'
    ;;
esac
