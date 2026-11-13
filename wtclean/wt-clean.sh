gh() { op plugin run -- gh "$@"; }

dry=0
if [ "${1:-}" = "-n" ] || [ "${1:-}" = "--dry-run" ]; then
  dry=1
  shift
fi

here=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "wt-clean: not in a git repo"
  exit 1
}
main=$(git worktree list --porcelain | awk 'NR==1 { print $2 }')

wanted() {
  local branch=$1 path=$2 want
  shift 2
  [ "$#" -gt 0 ] || return 0
  for want in "$@"; do
    case "$branch" in *"$want"*) return 0 ;; esac
    if [ -n "$path" ]; then
      case "$path" in *"$want"*) return 0 ;; esac
    fi
  done
  return 1
}

merged_at() {
  local branch=$1 head=$2 heads
  heads=$(gh pr list --head "$branch" --state merged --json headRefOid -q '.[].headRefOid') || return 2
  grep -qx "$head" <<<"$heads" || return 1
}

base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD) || base=origin/main

unused() {
  local branch=$1 count prs
  [ "$branch" != "${base#origin/}" ] || return 1
  count=$(git rev-list --count "$base..refs/heads/$branch" 2>/dev/null) || return 1
  [ "$count" = 0 ] || return 1
  prs=$(gh pr list --head "$branch" --state open --json number -q '.[].number') || return 2
  [ -z "$prs" ] || return 1
}

report() { printf '%-9s %s\n' "$1" "$2"; }

declare -A has_tree=()
status=0
path=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) path=${line#worktree } ;;
    "branch "*)
      branch=${line#branch refs/heads/}
      has_tree[$branch]=1
      if [ "$path" = "$main" ] || [ "$path" = "$here" ]; then continue; fi
      wanted "$branch" "$path" "$@" || continue
      if git -C "$path" status --porcelain | grep -qv '\.watchman-cookie-'; then
        report dirty "$branch"
        continue
      fi
      rc=0
      merged_at "$branch" "$(git -C "$path" rev-parse HEAD)" || rc=$?
      if [ "$rc" = 2 ]; then
        report gh-error "$branch"
        status=1
        continue
      fi
      verdict=removed
      if [ "$rc" = 1 ] && [ "$#" -gt 0 ]; then
        rc=0
        unused "$branch" || rc=$?
        if [ "$rc" = 2 ]; then
          report gh-error "$branch"
          status=1
          continue
        fi
        verdict=unused
      fi
      if [ "$rc" = 1 ]; then
        report keep "$branch"
        continue
      fi
      if [ "$dry" = 1 ]; then
        report would-rm "$branch"
        continue
      fi
      watchman watch-del "$path" >/dev/null 2>&1 || true
      if git worktree remove --force "$path" && git branch -D "$branch" >/dev/null; then
        report "$verdict" "$branch"
      else
        report failed "$branch"
        status=1
      fi
      ;;
  esac
done < <(git worktree list --porcelain)

if [ "$#" -gt 0 ]; then
  while IFS= read -r branch; do
    [ -z "${has_tree[$branch]:-}" ] || continue
    wanted "$branch" "" "$@" || continue
    rc=0
    merged_at "$branch" "$(git rev-parse "refs/heads/$branch")" || rc=$?
    if [ "$rc" = 2 ]; then
      report gh-error "$branch"
      status=1
      continue
    fi
    verdict=removed
    if [ "$rc" = 1 ]; then
      rc=0
      unused "$branch" || rc=$?
      if [ "$rc" = 2 ]; then
        report gh-error "$branch"
        status=1
        continue
      fi
      [ "$rc" = 0 ] || continue
      verdict=unused
    fi
    if [ "$dry" = 1 ]; then
      report would-rm "$branch"
    elif git branch -D "$branch" >/dev/null; then
      report "$verdict" "$branch"
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)
fi

git worktree prune
exit "$status"
