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
while [ "$#" -gt 0 ]; do
  [ "$1" = "--head" ] && branch=$2
  shift
done
cat "$WT_TEST/merged/$branch" 2>/dev/null || true
STUB
cat >"$tmp/bin/watchman" <<'STUB'
#!/usr/bin/env bash
echo '{"error": "directory is not watched"}'
exit 1
STUB
chmod +x "$tmp/bin/op" "$tmp/bin/watchman"
export PATH="$tmp/bin:$PATH" WT_TEST="$tmp"

repo="$tmp/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
mkdir -p "$tmp/merged"

add() {
  git -C "$repo" worktree add -q -b "$1" "$repo/.claude/worktrees/$1" main
  git -C "$repo/.claude/worktrees/$1" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "$1"
}
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

out=$(run -n)
expect dry-run "would-rm  merged-clean" "$out"
kept merged-clean || { echo "FAIL dry-run removed merged-clean"; failed=1; }

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

git -C "$repo" branch -q orphan main
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m orphan
git -C "$repo" branch -qf orphan HEAD
merge orphan
out=$(run orphan)
expect orphan-branch "removed   orphan" "$out"
git -C "$repo" show-ref -q refs/heads/orphan && { echo "FAIL orphan branch still there"; failed=1; }

touch "$tmp/gh-fails"
out=$(run open-pr)
expect gh-error "gh-error  open-pr" "$out"

[ "$failed" = 0 ] && echo "wt-clean: all checks passed"
exit "$failed"
