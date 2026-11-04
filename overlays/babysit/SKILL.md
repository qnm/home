## Steps

- **In** "Merge conflicts (`mergeStateStatus == DIRTY`)": this also covers a user asking for a rebase on a CLEAN PR. First check whether the PR was stacked on base PRs that have since been squash-merged (`gh pr list --head <base-branch> --state all --json state,mergedAt`). If one was, the conflicts are the base's old commits clashing with their own squash: don't resolve them, replay instead:
  - With one old base tip, use `git rebase --onto origin/main <old-base-tip>`. With merge commits from several bases there is no single tip. List this PR's own commits with `git log --no-merges --reverse --topo-order <head> ^origin/main ^<each merged base's head>`, then `git cherry-pick --empty=drop` each one.
  - Never send `cherry-pick --continue` output to `/dev/null`, and never fall back to `--skip`. After each commit, check that HEAD moved.
  - A clean cherry-pick or rebase step doesn't run the pre-commit hook. Typecheck every replayed commit yourself, for example `git rebase --exec '<typecheck>' origin/main`. Never report that "every commit went through the hook".
  - Prove nothing was lost: `git diff --no-ext-diff --stat HEAD $(git merge-tree --write-tree origin/main <old-head>)` must be empty. This holds when commits are dropped, folded or reordered. It proves the tip only, so keep the per-commit typecheck.
- **Replace** "poll `gh pr checks --watch`": run `gh pr checks <n> --watch --fail-fast` in the foreground with a long tool timeout. A backgrounded run counts only when its log shows named check rows; empty output means `gh` hit an auth prompt. Restart it after every push. Read the result from one query, not a grep: `gh pr view <n> --json headRefOid,statusCheckRollup -q '[.statusCheckRollup[] | (.conclusion // .state)] | group_by(.) | map("\(.[0])=\(length)") | join(" ")'`.
- A review-bot score counts only when its summary names the current `headRefOid`. After a force-push the old score is stale. Wait for a review of the new head.
- **After** "Cite each commit by SHA.": an approval the PR had at the start and lost is a step back; report it as one. After a rewrite, name each worktree with the branch checked out (`git worktree list`). Check it with `git -C <wt> status --short` and `git -C <wt> log --oneline <old-pushed-sha>..HEAD`, and give the resync command (`git -C <wt> checkout -B <branch> origin/<branch>`) only when both are empty.

## Hard rules

- **After** "clear it with the user first.": on an approved PR, say the force-push clears the approval and needs a new review, and prefer a path that keeps it. Offer only options these rules and the repo's hooks allow: a hook that failed for you fails the same way in the user's shell.
- Never force-push yourself, even with a lease. A hook blocks it, and the next git call gets denied too. Take the SHAs from earlier output and hand the user a `!` command: `git push --force-with-lease=<branch>:<old-sha> origin <new-sha>:refs/heads/<branch>`.
- **Replace** "`gh pr ready` only when all checks are green": never run `gh pr ready`. A PR stays a draft until the user marks it ready. Drive it to green and report; the last step is theirs.
