limit=100
bt='`'

input=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = true ] && exit 0
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
[ -f "$transcript" ] || exit 0

reply=$(tail -n 400 "$transcript" | jq -rs '
  (map(.type == "user") | rindex(true) // -1) as $last
  | .[($last + 1):]
  | map(select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text)
  | join("\n")
' 2>/dev/null || true)
[ -n "$reply" ] || exit 0

long=$(
  {
    grep -oE "${bt}! [^${bt}]+${bt}" <<<"$reply" | sed -E "s/^${bt}! //; s/${bt}\$//" || true
    grep -E "^[[:space:]]*! [^${bt}]+\$" <<<"$reply" | sed -E 's/^[[:space:]]*! //' || true
  } | awk -v n="$limit" 'length($0) > n { print length($0) }' | sort -rn | head -n 1
)
[ -n "$long" ] || exit 0

jq -n --arg len "$long" --arg n "$limit" '{
  decision: "block",
  reason: ("A ! command in your reply is " + $len + " characters, over " + $n + ". It will wrap when Rob pastes it and split its flags. Write the command to a script in the worktree, such as .cmd-<n>.sh, hand over ! sh .cmd-<n>.sh instead, and send the reply again with the short form. Delete the script once he has run it.")
}'
