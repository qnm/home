## Worktree

- **After** "read the tree you are about to ship.": a worktree you named in a handover belongs to the session that took it. Before you commit in any worktree, read `git log` for commits you didn't make and `git status` for files you never edited. If either shows up, another writer holds the tree: stop, and don't stage, commit or reset there.

## Size and stacks

- **In** "or `gh pr create --base <parent-branch>`": create a stack child as a draft: `origin pr create --status draft --base <parent-branch>` or `gh pr create --draft --base <parent-branch>`.

## Readiness

- **Replace** "**Readiness.** Open every PR ready, never as a draft.": open every PR as a draft, never ready. A built-in PR tool can default to ready, so set `draft: true` on every creation call through it. With Origin, pass `--status draft`. With `gh`, pass `--draft`. If a PR still opens ready, run `origin pr edit <number> --status draft` or `gh pr ready <number> --undo`. Moving a PR into review is the user's call. Never mark one ready yourself, not even on a green PR.
