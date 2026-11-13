limit=100
bt='`'

input=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = true ] && exit 0

final_text() {
  jq -rs '
    (map(.type == "user") | rindex(true) // -1) as $last
    | .[($last + 1):]
    | map(select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text)
    | join("\n")
  ' 2>/dev/null || true
}

block() {
  jq -n --arg reason "$1" '{decision: "block", reason: $reason}'
  exit 0
}

reply=$(jq -r '.last_assistant_message // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
if [ -z "$reply" ] && [ -f "$transcript" ]; then
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    reply=$(tail -n 400 "$transcript" | final_text)
    [ -n "$reply" ] && break
    sleep 0.2
  done
fi
[ -n "$reply" ] || exit 0

commands=$(
  {
    grep -oE "${bt}! [^${bt}]+${bt}" <<<"$reply" | sed -E "s/^${bt}! //; s/${bt}\$//" || true
    grep -E "^[[:space:]]*! [^${bt}]+\$" <<<"$reply" | sed -E 's/^[[:space:]]*! //' || true
  }
)
[ -n "$commands" ] || exit 0

long=$(awk -v n="$limit" 'length($0) > n { print length($0) }' <<<"$commands" | sort -rn | head -n 1)
[ -z "$long" ] || block "A ! command in your reply is $long characters, over $limit. It will wrap when Rob pastes it and split its flags. Write the command to a script in the worktree, such as .cmd-<n>.sh, hand over ! sh .cmd-<n>.sh instead, and send the reply again with the short form. Delete the script once he has run it."

sudo=$(grep -E '(^|[;&|(][[:space:]]*)sudo[[:space:]]' <<<"$commands" | head -n 1 || true)
[ -z "$sudo" ] || block "A ! command in your reply runs sudo. ! has no terminal, so sudo cannot ask for a password. Hand it over as a plain command for Rob to run in a terminal tab, say so, and send the reply again."

teardown=$(grep -E 'git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)*worktree[[:space:]]+remove' <<<"$commands" | head -n 1 || true)
[ -z "$teardown" ] || block "A ! command in your reply removes a worktree by hand. Hand over ! wt-clean <slug> instead, run from the main checkout. It checks the PR merged at the worktree's head, skips dirty trees, clears watchman, and deletes the branch. Use ! wt-clean -n <slug> first for a dry run. Send the reply again."

unforced=$(grep -E 'sbx[[:space:]]+((template[[:space:]]+)?rm|prune)' <<<"$commands" | grep -vE -- '--force|--dry-run' | head -n 1 || true)
[ -z "$unforced" ] || block "A ! command in your reply runs an sbx delete that asks for confirmation. ! has no terminal, so it fails. Add --force once Rob has approved that exact set, or hand it over for a terminal tab, and send the reply again."
