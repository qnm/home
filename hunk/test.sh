#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
rex=$(command -v rex)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo=$tmp/repo out=$tmp/out
fail() { echo "FAIL: $*" >&2; exit 1; }
expect() {
  local want=$1; shift
  set +e; "$@" >"$tmp/log" 2>&1; local got=$?; set -e
  [ "$got" = "$want" ] || { cat "$tmp/log" >&2; fail "exit $got, wanted $want: ${*: -3}"; }
}
core() {
  local key=out
  [ "$1" = verify ] && key=worktree
  "$rex" do "$here/core_patch.lua" cmd="$1" patch="$2" "$key=$3"
}
holds() { jq -e "$2" "$1" >/dev/null || fail "$3"; }
edit_json() { jq "$2" "$1" >"$1.new" && mv "$1.new" "$1"; }

git init -q "$repo" && cd "$repo"
git config user.email t@t && git config user.name t
mkdir -p src
printf '%s\n' "import { a } from './a'" "" "export function price(x: number) {" "  return x * 2" "}" >src/price.ts
printf '%s\n' "it('works', () => {})" >src/price.test.ts
git add . && git commit -qm base
printf '%s\n' "import { a } from './a'" "import { b } from './b'" "" "export function price(x: number) {" "  return x * 3" "}" >src/price.ts
printf '%s\n' "it('works', () => {})" "it('triples', () => {})" >src/price.test.ts
printf '%s\n' "import { price } from './price'" "import { b } from './b'" "" "export const rate = price(2)" "export const cap = 10" >src/rate.ts
git add . && git commit -qm head
git diff --no-color --no-ext-diff HEAD~1 HEAD >"$tmp/full.patch"

expect 0 core split "$tmp/full.patch" "$out"
grep -q '"src/price.test.ts#1"' "$out/triage.json" || fail "path rule did not hide the test file"
holds "$out/triage.json" '.["src/price.ts#1"] == {"keep": [[4, 7]], "reason": "imports"}' "line rules did not cut the import lines"
grep -q -- '--- src/price.ts#1' "$out/hunks.txt" || fail "price.ts hunk missing from hunks.txt"

expect 0 core build "$tmp/full.patch" "$out"
expect 0 core verify "$out/core.patch" "$repo"
grep -q 'Hidden from this view: 3 hunks' "$out/sidecar.json" || fail "manifest note missing"

edit_json "$out/triage.json" '.["src/rate.ts#1"] = {"keep": [[4, 5]], "reason": "imports"}'
echo '{"version": 1, "files": [{"path": "src/rate.ts", "annotations": [
  {"newRange": [4, 4], "summary": "rate is derived from price"}]}]}' >"$out/notes.json"
expect 0 core build "$tmp/full.patch" "$out"
grep -q '^@@ -0,0 +4,2 @@' "$out/core.patch" || fail "partial new-file hunk header wrong"
holds "$out/manifest.json" '[.files[].annotations[].author] == ["core-patch"]' "manifest.json split wrong"
holds "$out/live-notes.json" \
  '.comments == [{"filePath": "src/rate.ts", "summary": "rate is derived from price", "author": "agent", "newLine": 4}]' \
  "live-notes.json split wrong"
expect 0 core verify "$out/core.patch" "$repo"

edit_json "$out/sidecar.json" '.files[-1].annotations += [{"newRange": [1, 1], "summary": "hidden import"}]'
expect 1 core verify "$out/core.patch" "$repo"
grep -q 'NOTE OFF-VIEW' "$tmp/log" || fail "off-view note not reported"
expect 0 core build "$tmp/full.patch" "$out"
sed 's/^@@ -0,0 +4,2 @@/@@ -0,0 +3,2 @@/' "$out/core.patch" >"$tmp/shifted.patch"
cp "$out/sidecar.json" "$tmp/sidecar.json"
expect 1 core verify "$tmp/shifted.patch" "$repo"
grep -q 'MISANCHORED HUNK' "$tmp/log" || fail "shifted header not reported"
echo '{"src/nope.ts#1": {"keep": false, "reason": "x"}}' >"$out/triage.json"
expect 1 core build "$tmp/full.patch" "$out"

lr=$tmp/lr
git init -q "$lr" && cd "$lr"
git config user.email t@t && git config user.name t
{ printf '%s\n' "import {" "  a," "} from './a'"; for i in $(seq 1 12); do echo "const k$i = $i"; done
  printf '%s\n' "export function f(x: number) {" "  if (x) {" "    return 1" "  }" "  return x" "}"
  for i in $(seq 1 12); do echo "const m$i = $i"; done
  printf '%s\n' "export function g(y: number) {" "  return y" "}"; } >m.ts
printf '%s\n' "export { a } from './a'" "const b = 1" "const c = 2" "export {" "  b," "}" >idx.ts
git add . && git commit -qm base
perl -0pi -e 's/  a,\n/  a,\n  b,\n/; s/    return 1\n/      return 1\n/; s|  return y\n|  // y is never negative\n  return y + 1\n|' m.ts
printf '%s\n' "export {" "  a," "  z," "} from './a'" "const b = 1" "const c = 2" "export {" "  b," "  c," "}" >idx.ts
git diff --no-color --no-ext-diff >"$tmp/lr.patch"
expect 0 core split "$tmp/lr.patch" "$tmp/lr-out"
t=$tmp/lr-out/triage.json
holds "$t" '.["m.ts#1"] == {"keep": false, "reason": "imports"}' "multi-line import not hidden"
holds "$t" '.["m.ts#2"] == {"keep": false, "reason": "formatting"}' "whitespace-only hunk not hidden"
holds "$t" '.["m.ts#3"].reason == "comment" and .["m.ts#3"].keep != false' "comment beside logic not cut"
holds "$t" '.["idx.ts#1"].reason == "imports" and .["idx.ts#1"].keep != false' "re-export not cut"
expect 0 core build "$tmp/lr.patch" "$tmp/lr-out"
expect 0 core verify "$tmp/lr-out/core.patch" "$lr"
c=$tmp/lr-out/core.patch
grep -q 'never negative' "$c" && fail "comment line still shown"
grep -q '^+  return y + 1' "$c" || fail "logic line beside the comment was hidden"
grep -q '^+  z,' "$c" && fail "re-export line still shown"
grep -q '^+  c,' "$c" || fail "local export list was hidden"
cd "$repo"

: >"$tmp/empty.patch"
expect 2 core split "$tmp/empty.patch" "$tmp/out2"
expect 2 core build "$tmp/full.patch" "$tmp/nowhere"

echo "hunk-core-view: all core_patch.lua checks passed"

wn() { "$rex" do "$here/wait_for_notes.lua" session="$1" seen="$2" "${@:3}"; }
mkdir -p "$tmp/bin"
cat >"$tmp/bin/hunk" <<EOF
#!/usr/bin/env bash
[ "\$4" = live-session ] || { echo '{"error":{"message":"No active session"}}'; exit 1; }
cat "$tmp/notes.json"
EOF
chmod +x "$tmp/bin/hunk"
export PATH="$tmp/bin:$PATH"
seen=$tmp/seen
echo '{"comments":[]}' >"$tmp/notes.json"
expect 3 wn live-session "$seen" timeout=1 interval=0.2
echo '{"comments":[{"noteId":"user:1","filePath":"src/rate.ts","newRange":[4,4],"body":"why 2?","source":"user"}]}' >"$tmp/notes.json"
expect 0 wn live-session "$seen" timeout=2 interval=0.2
grep -q '"noteId":"user:1"' "$tmp/log" || fail "new note not printed"
expect 3 wn live-session "$seen" timeout=1 interval=0.2
expect 2 wn gone-session "$seen" timeout=1
PATH=/usr/bin:/bin expect 2 wn live-session "$seen" timeout=1

echo "hunk-core-view: all wait_for_notes.lua checks passed"
