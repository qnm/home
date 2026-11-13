#!/usr/bin/env bash
set -euo pipefail

hook="$(cd "$(dirname "$0")" && pwd)/handoffwrap.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

prompt() { jq -nc '{type: "user", message: {role: "user", content: "go"}}'; }
answer() { jq -nc --arg text "$1" '{type: "assistant", message: {role: "assistant", content: [{type: "text", text: $text}]}}'; }
run() { jq -nc --arg t "$1" '{transcript_path: $t}' | bash -euo pipefail "$hook"; }

expect() {
  local name=$1 want=$2 out=$3
  if [ -z "$want" ] && [ -z "$out" ]; then return; fi
  if [ -n "$want" ] && grep -q -- "$want" <<<"$out"; then return; fi
  echo "FAIL $name: wanted '${want:-no output}', got '${out:-no output}'"
  failed=1
}

check() {
  local name=$1 want=$2 text=$3
  { prompt; answer "$text"; } >"$tmp/$name.jsonl"
  expect "$name" "$want" "$(run "$tmp/$name.jsonl")"
}

long_command="! $(printf 'x%.0s' $(seq 1 120))"

check short-command "" '! git status'
check no-command "" 'Nothing to run.'
check long-command "120 characters" "$long_command"
check long-inline-command "120 characters" "Run \`$long_command\` now."
check sudo "runs sudo" '! sudo nix-collect-garbage --delete-older-than 14d'
check sudo-after-pipe "runs sudo" '! echo ok && sudo true'
check sudo-outside-bang "" 'Run `sudo nix-collect-garbage` in a terminal tab.'
check pseudo-word "" '! echo pseudo code'
check sbx-rm-unforced "sbx delete" '! for t in $(cat tags); do sbx template rm "$t"; done'
check sbx-prune-unforced "sbx delete" '! sbx prune'
check sbx-rm-forced "" '! sbx template rm --force a:b'
check sbx-prune-dry-run "" '! sbx prune --dry-run'

prompt >"$tmp/late-reply.jsonl"
(sleep 0.5 && answer "$long_command" >>"$tmp/late-reply.jsonl") &
expect late-reply "120 characters" "$(run "$tmp/late-reply.jsonl")"
wait

prompt >"$tmp/no-reply.jsonl"
expect no-reply "" "$(run "$tmp/no-reply.jsonl")"

expect reply-in-input "120 characters" "$(jq -nc --arg m "$long_command" '{last_assistant_message: $m}' | bash -euo pipefail "$hook")"
expect already-blocked "" "$(jq -nc --arg m "$long_command" '{last_assistant_message: $m, stop_hook_active: true}' | bash -euo pipefail "$hook")"

[ "$failed" = 0 ] && echo "handoffwrap: all checks passed"
exit "$failed"
