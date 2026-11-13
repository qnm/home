#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/ghop.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

mkdir -p "$tmp/real" "$tmp/path"
printf '#!/bin/sh\necho "real $*"\n' >"$tmp/real/gh"
printf '#!/bin/sh\necho "op $* via $(command -v gh)"\n' >"$tmp/path/op"
chmod +x "$tmp/real/gh" "$tmp/path/op"

run() {
  env -i PATH="$tmp/path:/usr/bin:/bin" "$@" \
    sh -c "real_gh_dir='$tmp/real'; $(cat "$script")" gh pr view 1
}

expect() {
  local name=$1 want=$2 out=$3
  [ "$out" = "$want" ] && return
  echo "FAIL $name: wanted '$want', got '$out'"
  failed=1
}

expect plain-sh-goes-through-op "op plugin run -- gh pr view 1 via $tmp/real/gh" "$(run)"
expect github-token-skips-op "real pr view 1" "$(run GITHUB_TOKEN=x)"
expect gh-token-skips-op "real pr view 1" "$(run GH_TOKEN=x)"

exit "$failed"
