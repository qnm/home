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

rr=$tmp/rules ro=$tmp/rules-out
git init -q "$rr" && cd "$rr"
git config user.email t@t && git config user.name t
cat >a.ts <<'EOF'
import { x } from './x'

export function total(items: number[]) {
  const sum = items.reduce((a, b) => a + b, 0)
  const tax = sum * 0.1
  const fee = sum > 100 ? 0 : 5
  const discount = items.length > 3 ? 2 : 0
  const shipping = items.length * 1.5
  return sum + tax + fee - discount + shipping
}

export const label = 'a b'
export const rate = 2
  * 3
EOF
cat >c.ts <<'EOF'
export const greet = (name: string) =>
  format('hello', name, { upper: true, trim: true, pad: 2 })
export const m = 0
// old note
export const n = 1
EOF
cat >d.ts <<'EOF'
export function run() {
  const alpha = computeTheAlphaValue(input)
  const beta = computeTheBetaValue(alpha)
  const gamma = computeTheGammaValue(beta)
  const delta = computeTheDeltaValue(gamma)
}
EOF
printf '%s\n' "import os" "" "def f(x):" "    if x:" "        y = 1" "    return x" >p.py
printf '%s\n' "export const e = 1" "" "call('a', [b, c])" >e.ts
git add . && git commit -qm base
cat >a.ts <<'EOF'
import { x, y } from './x'

export const label = 'ab'
export const rate = 2
  * 4
EOF
cat >b.ts <<'EOF'
import { y } from './y'

export function total(items: number[]) {
  const sum = items.reduce((a, b) => a + b, 0)
  const tax = sum * 0.1
  const fee = sum > 100 ? 0 : 5
  const discount = items.length > 3 ? 2 : 0
  const shipping = items.length * 1.5
  return sum + tax + fee + shipping
}

export const b = y
EOF
cat >c.ts <<'EOF'
export const greet = (name: string) =>
  format("hello", name, {
    upper: true,
    trim: true,
    pad: 2,
  })
export const m = 0
// new note
export const n = 1
import('./m').then(init)
EOF
cat >d.ts <<'EOF'
export function run() {
  if (enabled) {
    const alpha = computeTheAlphaValue(input)
    const beta = computeTheBetaValue(alpha)
    const gamma = computeTheGammaValue(beta)
    const delta = computeTheDeltaValue(gamma)
  }
}
EOF
printf '%s\n' "import os" "import sys" "" "def f(x):" "    if x:" "        y = 1" "        return x" >p.py
printf '%s\n' "export const e = 1" "" "call(" '  "a",' "  [" "    b," "    c," "  ]," ")" >e.ts
git add . && git commit -qm head
git diff --no-color --no-ext-diff HEAD~1 HEAD >"$tmp/rules.patch"
expect 0 core split "$tmp/rules.patch" "$ro"
cp "$ro/triage.json" "$tmp/t1" && cp "$ro/hunks.txt" "$tmp/h1"
expect 0 core split "$tmp/rules.patch" "$ro"
cmp -s "$tmp/t1" "$ro/triage.json" && cmp -s "$tmp/h1" "$ro/hunks.txt" || fail "split is not deterministic"
t=$ro/triage.json
holds "$t" '.["b.ts#1"].reason == "move/rename" and .["b.ts#1"].keep != false' "moved block not cut"
holds "$t" '.["e.ts#1"] == {"keep": false, "reason": "formatting"}' "quote and trailing comma reflow not hidden"
holds "$t" '.["c.ts#1"] == {"keep": [[11, 12]], "reason": "comment"}' "reflow beside a comment cut wrong"
expect 0 core build "$tmp/rules.patch" "$ro"
expect 0 core verify "$ro/core.patch" "$rr"
shown() { grep -qxF -- "$1" "$ro/core.patch" || fail "rules hid a core line: $1"; }
hidden() { ! grep -qxF -- "$1" "$ro/core.patch" || fail "rules showed a non-core line: $1"; }
hidden "+import { x, y } from './x'"; hidden "+import { y } from './y'"; hidden "+import sys"
hidden "+// new note"; hidden "+    upper: true,"; hidden "+  format(\"hello\", name, {"
hidden "-  const fee = sum > 100 ? 0 : 5"; hidden "+  const fee = sum > 100 ? 0 : 5"
shown "+  return sum + tax + fee + shipping"; shown "-  return sum + tax + fee - discount + shipping"
shown "+export const label = 'ab'"; shown "+  * 4"; shown "+import('./m').then(init)"
shown "+export const b = y"; shown "+        return x"
shown "+    const alpha = computeTheAlphaValue(input)"
cd "$repo"

dw=$tmp/dw
git init -q "$dw" && cd "$dw"
git config user.email t@t && git config user.name t
printf '%s\n' "export const a = 1" >a.ts
echo "ignored.log" >.gitignore
git add . && git commit -qm base
git update-ref refs/remotes/origin/main HEAD
cdiff() { "$rex" do "$here/core_patch.lua" cmd=diff worktree="$dw" out="$1" "${@:2}"; }
expect 3 cdiff "$tmp/dw-clean"
[ -f "$tmp/dw-clean/full.patch" ] || fail "diff did not create OUTDIR"
printf '%s\n' "export const a = 2" >a.ts
printf '%s\n' "export const n = 1" >new.ts
echo noise >ignored.log
expect 0 cdiff "$tmp/dw-out"
p=$tmp/dw-out/full.patch
grep -q '^+export const a = 2' "$p" || fail "diff missed the modified file"
grep -q '^+++ b/new.ts' "$p" && grep -q '^+export const n = 1' "$p" || fail "diff missed the untracked file"
grep -q 'ignored.log' "$p" && fail "diff included an ignored file"
expect 0 core split "$p" "$tmp/dw-out"
git add a.ts && git commit -qm head
git update-ref refs/remotes/origin/feature HEAD
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/feature
expect 0 cdiff "$tmp/dw-head"
grep -q '^+++ b/new.ts' "$tmp/dw-head/full.patch" || fail "diff from origin/HEAD missed the untracked file"
grep -q 'a = 2' "$tmp/dw-head/full.patch" && fail "diff did not use origin/HEAD"
expect 0 cdiff "$tmp/dw-base" base=origin/main
grep -q '^+export const a = 2' "$tmp/dw-base/full.patch" || fail "diff ignored base="
expect 2 cdiff "$tmp/dw-bad" base=no-such-ref
expect 2 "$rex" do "$here/core_patch.lua" cmd=diff out="$tmp/dw-bad"
cd "$repo"
echo "hunk-core-view: all core_patch.lua diff checks passed"

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

pp() { "$rex" do "$here/pick_prs.lua" repo=acme/core "$@"; }
cat >"$tmp/bin/gh" <<EOF
#!/usr/bin/env bash
[ "\$1 \$2 \$3 \$4" = "search prs --review-requested=@me --state=open" ] || { echo "bad args: \$*" >&2; exit 1; }
cat "$tmp/prs.json"
EOF
chmod +x "$tmp/bin/gh"
sess=$("$rex" new hunk-pick-test --window core-7 --json | jq -er '.session_id')
trap '"$rex" session kill "$sess" >/dev/null 2>&1; rm -rf "$tmp"' EXIT
"$rex" window new -s "$sess" review-other-9 --focus=false >/dev/null
cat >"$tmp/prs.json" <<'EOF'
[
  {"repository": {"nameWithOwner": "acme/core"}, "number": 7, "isDraft": false, "author": {"login": "sam"}},
  {"repository": {"nameWithOwner": "acme/core"}, "number": 8, "isDraft": false, "author": {"login": "sam"}},
  {"repository": {"nameWithOwner": "acme/core"}, "number": 9, "isDraft": true, "author": {"login": "sam"}},
  {"repository": {"nameWithOwner": "acme/core"}, "number": 10, "isDraft": false, "author": {"login": "renovate[bot]"}},
  {"repository": {"nameWithOwner": "acme/core"}, "number": 11, "isDraft": false, "author": {"login": "app", "is_bot": true}},
  {"repository": {"nameWithOwner": "acme/other"}, "number": 9, "isDraft": false, "author": {"login": "jo"}},
  {"repository": {"nameWithOwner": "acme/other"}, "number": 12, "isDraft": false, "author": null}
]
EOF
set +e; pp session="$sess" >"$tmp/pick.out" 2>"$tmp/pick.err"; got=$?; set -e
[ "$got" = 0 ] || { cat "$tmp/pick.err" >&2; fail "pick_prs exit $got, wanted 0"; }
printf '%s\n' "acme/core 8 core-8" "acme/other 12 core-other-12" | cmp -s - "$tmp/pick.out" || { cat "$tmp/pick.out" >&2; fail "pick_prs picked the wrong PRs"; }
grep -q '7 requested: 2 new; skipped 1 draft, 2 bot, 2 has a tab' "$tmp/pick.err" || { cat "$tmp/pick.err" >&2; fail "pick_prs summary wrong"; }
echo '[{"repository": {"nameWithOwner": "acme/core"}, "number": 7, "isDraft": false, "author": {"login": "sam"}}]' >"$tmp/prs.json"
expect 3 pp session="$sess"
[ "$(grep -c . "$tmp/log")" = 1 ] || fail "pick_prs printed a PR when nothing was new"
expect 2 pp session=no-such-session
echo nope >"$tmp/prs.json"
expect 2 pp session="$sess"
PATH=/usr/bin:/bin expect 2 pp session="$sess"
expect 2 "$rex" do "$here/pick_prs.lua" session="$sess"

echo "hunk-core-view: all pick_prs.lua checks passed"
