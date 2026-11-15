#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/wt-clean.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

mkdir -p "$tmp/bin"
cat >"$tmp/bin/op" <<'STUB'
#!/usr/bin/env bash
shift 2
[ -f "$WT_TEST/gh-fails" ] && exit 1
branch=""
state=""
search=""
query=""
while [ "$#" -gt 0 ]; do
  [ "$1" = "--head" ] && branch=$2
  [ "$1" = "--state" ] && state=$2
  [ "$1" = "--search" ] && search=$2
  [ "$1" = "-q" ] && query=$2
  shift
done
if [ -n "$search" ]; then
  [ -f "$WT_TEST/search/$search" ] && jq -r "$query" "$WT_TEST/search/$search"
  exit 0
fi
cat "$WT_TEST/$state/$branch" 2>/dev/null || true
STUB
cat >"$tmp/bin/watchman" <<'STUB'
#!/usr/bin/env bash
echo '{"error": "directory is not watched"}'
exit 1
STUB
chmod +x "$tmp/bin/op" "$tmp/bin/watchman"
export PATH="$tmp/bin:$PATH" WT_TEST="$tmp"

repo="$tmp/repo"
git init -q --bare -b main "$tmp/origin.git"
git init -q -b main "$repo"
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$repo" remote add origin "$tmp/origin.git"
git -C "$repo" push -q origin main
git -C "$repo" remote set-head origin main
mkdir -p "$tmp/merged" "$tmp/open" "$tmp/search"

add() {
  git -C "$repo" worktree add -q -b "$1" "$repo/.claude/worktrees/$1" main
  git -C "$repo/.claude/worktrees/$1" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "$1"
}
fresh() { git -C "$repo" worktree add -q -b "$1" "$repo/.claude/worktrees/$1" origin/main; }
merge() { git -C "$repo" rev-parse "refs/heads/$1" >"$tmp/merged/$1"; }
run() { (cd "$repo" && bash "$script" "$@" 2>&1) || true; }

expect() {
  local name=$1 want=$2 out=$3
  if grep -q -- "$want" <<<"$out"; then return; fi
  echo "FAIL $name: wanted '$want', got '$out'"
  failed=1
}
gone() { ! git -C "$repo" show-ref -q "refs/heads/$1" && [ ! -d "$repo/.claude/worktrees/$1" ]; }
kept() { git -C "$repo" show-ref -q "refs/heads/$1" && [ -d "$repo/.claude/worktrees/$1" ]; }

add merged-clean
merge merged-clean
add cookie-only
merge cookie-only
touch "$repo/.claude/worktrees/cookie-only/.watchman-cookie-host-1-2"
add dirty
merge dirty
echo edit >"$repo/.claude/worktrees/dirty/file"
add rebased-elsewhere
echo aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa >"$tmp/merged/rebased-elsewhere"
add open-pr
fresh unused
fresh unused-dirty
echo edit >"$repo/.claude/worktrees/unused-dirty/file"
fresh unused-open
echo open >"$tmp/open/unused-open"
git -C "$repo" worktree add -q -b local-commit "$repo/.claude/worktrees/local-commit" main
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local
git -C "$repo/.claude/worktrees/local-commit" reset -q --hard main

out=$(run -n)
expect dry-run "would-rm  merged-clean" "$out"
kept merged-clean || { echo "FAIL dry-run removed merged-clean"; failed=1; }
expect dry-run-bare-unused "keep      unused$" "$out"
out=$(run -n unused)
expect dry-run-unused "would-rm  unused" "$out"
kept unused || { echo "FAIL dry-run removed unused"; failed=1; }

out=$(run)
expect merged-clean "removed   merged-clean" "$out"
gone merged-clean || { echo "FAIL merged-clean still there"; failed=1; }
expect cookie-only "removed   cookie-only" "$out"
gone cookie-only || { echo "FAIL cookie-only still there"; failed=1; }
expect dirty "dirty     dirty" "$out"
kept dirty || { echo "FAIL dirty was removed"; failed=1; }
expect rebased-elsewhere "keep      rebased-elsewhere" "$out"
kept rebased-elsewhere || { echo "FAIL rebased-elsewhere was removed"; failed=1; }
expect open-pr "keep      open-pr" "$out"
expect bare-unused "keep      unused$" "$out"
kept unused || { echo "FAIL bare run removed unused"; failed=1; }

out=$(run unused local-commit)
expect unused "unused    unused" "$out"
gone unused || { echo "FAIL unused still there"; failed=1; }
expect unused-dirty "dirty     unused-dirty" "$out"
kept unused-dirty || { echo "FAIL unused-dirty was removed"; failed=1; }
expect unused-open "keep      unused-open" "$out"
kept unused-open || { echo "FAIL unused-open was removed"; failed=1; }
expect local-commit "keep      local-commit" "$out"
kept local-commit || { echo "FAIL local-commit was removed"; failed=1; }

git -C "$repo" branch -q orphan main
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m orphan
git -C "$repo" branch -qf orphan HEAD
merge orphan
out=$(run orphan)
expect orphan-branch "removed   orphan" "$out"
git -C "$repo" show-ref -q refs/heads/orphan && { echo "FAIL orphan branch still there"; failed=1; }

git -C "$repo" branch -q stray origin/main
git -C "$repo" branch -q stray-open origin/main
echo open >"$tmp/open/stray-open"
out=$(run stray)
expect stray-branch "unused    stray" "$out"
git -C "$repo" show-ref -q refs/heads/stray && { echo "FAIL stray branch still there"; failed=1; }
git -C "$repo" show-ref -q refs/heads/stray-open || { echo "FAIL stray-open branch was removed"; failed=1; }

found() {
  local head state name sha
  head=$(git -C "$repo" rev-parse "refs/heads/$1")
  shift
  while [ "$#" -gt 0 ]; do
    state=$1 name=$2 sha=$3
    shift 3
    printf '{"headRefOid":"%s","headRefName":"%s","state":"%s"}\n' "$sha" "$name" "$state"
  done | jq -s . >"$tmp/search/$head"
}
tip() { git -C "$repo" rev-parse "refs/heads/$1"; }

add stacked
git -C "$repo" branch -q stacked-top "$(git -C "$repo" -c user.email=t@t -c user.name=t commit-tree -p stacked -m top "stacked^{tree}")"
found stacked OPEN stacked-top "$(tip stacked-top)"

add closed-only
git -C "$repo" branch -q closed-top closed-only
found closed-only CLOSED closed-top "$(tip closed-top)"

add own-open
echo open >"$tmp/open/own-open"
git -C "$repo" branch -q own-open-top own-open
found own-open OPEN own-open-top "$(tip own-open-top)"

add not-ancestor
found not-ancestor MERGED other "$(tip main)"

add remote-only
git -C "$repo" push -q origin remote-only
git clone -q "$tmp/origin.git" "$tmp/other"
git -C "$tmp/other" switch -q remote-only
git -C "$tmp/other" -c user.email=t@t -c user.name=t commit -q --allow-empty -m remote
git -C "$tmp/other" push -q origin HEAD:refs/heads/remote-top
remote_top=$(git -C "$tmp/other" rev-parse HEAD)
found remote-only MERGED remote-top "$remote_top"
git -C "$repo" cat-file -e "$remote_top^{commit}" 2>/dev/null && { echo "FAIL remote-top already local"; failed=1; }

out=$(run)
expect bare-absorbed "keep      stacked$" "$out"
kept stacked || { echo "FAIL bare run removed stacked"; failed=1; }

out=$(run -n stacked)
expect dry-run-absorbed "would-rm  stacked$" "$out"
kept stacked || { echo "FAIL dry-run removed stacked"; failed=1; }

out=$(run stacked closed-only own-open not-ancestor remote-only)
expect absorbed "absorbed  stacked$" "$out"
gone stacked || { echo "FAIL stacked still there"; failed=1; }
expect closed-only "keep      closed-only" "$out"
kept closed-only || { echo "FAIL closed-only was removed"; failed=1; }
expect own-open "keep      own-open" "$out"
kept own-open || { echo "FAIL own-open was removed"; failed=1; }
expect not-ancestor "keep      not-ancestor" "$out"
kept not-ancestor || { echo "FAIL not-ancestor was removed"; failed=1; }
expect remote-only "absorbed  remote-only" "$out"
gone remote-only || { echo "FAIL remote-only still there"; failed=1; }

fresh gh-unused
touch "$tmp/gh-fails"
out=$(run open-pr)
expect gh-error "gh-error  open-pr" "$out"
out=$(run gh-unused)
expect gh-error-unused "gh-error  gh-unused" "$out"
kept gh-unused || { echo "FAIL gh-unused was removed"; failed=1; }

[ "$failed" = 0 ] && echo "wt-clean: all checks passed"
exit "$failed"
