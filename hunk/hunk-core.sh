#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
hold() {
  local code=$?
  if [ "$code" -ne 0 ] && [ -t 0 ]; then
    printf '\nPress enter to close.'
    read -r _
  fi
}
trap hold EXIT
usage() {
  echo "usage: hunk-core.sh [--staged | --branch | PR-NUMBER | PR-URL | --open DIR]" >&2
  exit 2
}
git_diff() { git diff --no-color --no-ext-diff "$@"; }
branch_diff() { git_diff "$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main)...HEAD"; }

if [ "${1:-}" = --open ]; then
  out=${2:-}
  [ -s "$out/core.patch" ] || usage
else
  out=$(mktemp -d "${TMPDIR:-/tmp}/hunk-core.XXXXXX")
  case "${1:-}" in
    "") if [ -n "$(git_diff HEAD)" ]; then git_diff HEAD; else branch_diff; fi ;;
    --staged) git_diff --staged ;;
    --branch) branch_diff ;;
    [0-9]* | https://*) gh pr diff "$1" --color never ;;
    *) usage ;;
  esac >"$out/full.patch"
  if [ ! -s "$out/full.patch" ]; then
    echo "No changes to review."
    exit 1
  fi
  rex do "$here/core_patch.lua" cmd=split patch="$out/full.patch" out="$out" >/dev/null
  if ! rex do "$here/core_patch.lua" cmd=build patch="$out/full.patch" out="$out"; then
    echo "Every edit is noise, so here is the full diff."
    cp "$out/full.patch" "$out/core.patch"
    echo '{"version": 1, "files": []}' >"$out/manifest.json"
  fi
fi

exec hunk patch "$out/core.patch" --agent-context "$out/manifest.json" --agent-notes
