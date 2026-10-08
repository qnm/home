marker="Posted by Claude on Rob"
api='(^|[;&|(]|&&)[[:space:]]*gh[[:space:]]+api[[:space:]].*/(comments|replies|reviews)'
cli='(^|[;&|(]|&&)[[:space:]]*gh[[:space:]]+(pr|issue)[[:space:]]+(comment|review)([[:space:]]|$)'

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cmd" ] || exit 0
grep -qE '(-b|--body|-f[[:space:]]+body=|--raw-field[[:space:]]+body=)[[:space:]=]*["'"'"']?@greptile' <<<"$cmd" && exit 0

files=""
if grep -qE "$api" <<<"$cmd"; then
  grep -qE '(-f|-F|--field|--raw-field)[[:space:]=]+["'"'"']?body=' <<<"$cmd" || exit 0
  files=$(grep -oE 'body=@[^[:space:]"'"'"']+' <<<"$cmd" | sed 's/^body=@//' || true)
elif grep -qE "$cli" <<<"$cmd"; then
  grep -qE '(^|[[:space:]])(-b|--body|-F|--body-file)([[:space:]=]|$)' <<<"$cmd" || exit 0
  files=$(grep -oE '(^|[[:space:]])(-F|--body-file)[[:space:]=]+["'"'"']?[^[:space:]"'"'"']+' <<<"$cmd" \
    | sed -E 's/^[[:space:]]*(-F|--body-file)[[:space:]=]+["'"'"']?//' || true)
else
  exit 0
fi

signed=no
if [ -n "$files" ]; then
  while IFS= read -r f; do
    [ "$f" = "-" ] && exit 0
    case "$f" in /*) ;; *) f="${cwd:-.}/$f" ;; esac
    [ -f "$f" ] || exit 0
    grep -qF "$marker" "$f" && signed=yes
  done <<<"$files"
else
  grep -qF "$marker" <<<"$cmd" && signed=yes
fi
[ "$signed" = no ] || exit 0

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "This posts under Rob'"'"'s name without the attribution line. End the body with _Posted by Claude on Rob'"'"'s behalf._ (robin-voice), then post again."
  }
}'
