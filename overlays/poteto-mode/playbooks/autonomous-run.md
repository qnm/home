## Steps

- **After** "State the exit condition as a checkable predicate": before fanning out parallel workers, check free disk (`df -h`) and name any shared resource that forces work to run one at a time, such as a single local stack behind a lock. Size the worker count to both: each worktree costs its own install and build output, and a full disk corrupts Docker and fails commits.
- **After** "Put out-of-band fixes in their own PR.": when the user forbids pushing or opening PRs, still build each side fix on its own local branch off trunk, commit it, and list it in the reply as a branch ready to push, not as a caveat or an env-var workaround.
