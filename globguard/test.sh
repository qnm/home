#!/usr/bin/env bash
set -euo pipefail

hook="$(cd "$(dirname "$0")" && pwd)/globguard.sh"
failed=0

run() { jq -nc --arg c "$1" '{tool_input: {command: $c}}' | bash -euo pipefail "$hook"; }

check() {
  local name=$1 want=$2 cmd=$3 out
  out=$(run "$cmd")
  if [ "$want" = deny ] && grep -q '"deny"' <<<"$out"; then return; fi
  if [ "$want" = allow ] && [ -z "$out" ]; then return; fi
  echo "FAIL $name: wanted $want, got '${out:-no output}'"
  failed=1
}

check unquoted-include deny 'grep -rn foo --include=*.ts src'
check unquoted-exclude deny 'grep -rn foo --exclude-dir=node_* .'
check single-dash deny 'rg foo -g=*.md'
check after-pipe deny 'cat x | grep -r y --include=*.json .'
check single-quoted allow "grep -rn foo --include='*.ts' src"
check double-quoted allow 'grep -rn foo --include="*.ts" src'
check escaped allow 'grep -rn foo --include=\*.ts src'
check no-glob allow 'git log --format=%H -1'
check plain-glob allow 'ls *.ts'
check no-command allow ''

[ "$failed" = 0 ] && echo "globguard: all tests pass"
exit "$failed"
