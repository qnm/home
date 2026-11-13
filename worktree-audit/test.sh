#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
upstream=$(find "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/cache/pstack-claude/pstack" -path '*/poteto-mode/scripts/worktree-audit.mjs' 2>/dev/null | sort -V | tail -n 1)
if [ -z "$upstream" ]; then
  if [ "${SKIP_UPSTREAM:-}" = 1 ]; then echo "worktree-audit: SKIPPED, pstack plugin not installed"; exit 0; fi
  echo "worktree-audit: pstack plugin not installed. Set SKIP_UPSTREAM=1 to skip."
  exit 1
fi

tmp=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$tmp"' EXIT
failed=0
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

git init -q --bare "$tmp/origin.git"
git init -q -b main "$tmp/repo"
cd "$tmp/repo"
printf '.prettiercache\n.env\n*.module.css.d.ts\n' >.gitignore
git add .gitignore && git commit -q -m init
git remote add origin "$tmp/origin.git" && git push -q -u origin main
for name in cache secret clean; do git worktree add -q "$tmp/wt-$name" -b "br-$name"; done
touch "$tmp/wt-cache/.prettiercache" "$tmp/wt-cache/a.module.css.d.ts" "$tmp/wt-secret/.env"
echo '[]' >"$tmp/prs.json"
mkdir "$tmp/quiet" "$tmp/noisy" "$tmp/bin"
printf '{"text":"%s %s %s "}\n' "$tmp/wt-cache" "$tmp/wt-secret" "$tmp/wt-clean" >"$tmp/noisy/session.jsonl"
printf '#!/bin/sh\nexit 1\n' >"$tmp/bin/gh" && chmod +x "$tmp/bin/gh"

bucket() { awk -F'\t' -v path="$2" '$10 == path { print $8 }' <<<"$1"; }
expect() {
  [ "$2" = "$3" ] && return
  echo "FAIL $1: wanted '$2', got '$3'"
  failed=1
}

plain=$(PATH="$tmp/bin:$PATH" node "$upstream" "$tmp/repo" "$tmp/quiet" 2>/dev/null)
expect "upstream holds the cache worktree" hold-ignored "$(bucket "$plain" "$tmp/wt-cache")"

quiet=$(node "$here/audit.mjs" --prs "$tmp/prs.json" "$tmp/repo" "$tmp/quiet" 2>/dev/null)
expect "cache files are disposable" safe "$(bucket "$quiet" "$tmp/wt-cache")"
expect "a secret still holds" hold-ignored "$(bucket "$quiet" "$tmp/wt-secret")"
expect "a clean merged worktree is safe" safe "$(bucket "$quiet" "$tmp/wt-clean")"

noisy=$(node "$here/audit.mjs" --prs "$tmp/prs.json" "$tmp/repo" "$tmp/noisy" 2>"$tmp/noisy.err")
expect "one chat naming every worktree is unknown" review "$(bucket "$noisy" "$tmp/wt-clean")"
expect "the uniform column is reported" 1 "$(grep -c 'on every row' "$tmp/noisy.err")"

PATH="$tmp/bin:$PATH" node "$here/audit.mjs" "$tmp/repo" "$tmp/quiet" >/dev/null 2>"$tmp/gh.err"
expect "a gh failure names the fetch command" 1 "$(grep -c -- '--prs prs.json' "$tmp/gh.err")"

[ "$failed" = 0 ] && echo "worktree-audit: all checks passed"
exit "$failed"
