## Steps

- **After** "No inlined dumps.": when the plan changes a core domain entity, one explorer also searches the connected design-doc store (Notion, Confluence, or the repo's `docs/`) for an existing proposal on that entity, and the plan builds on it or says why not.
- **Replace** "Open the PR ready, never draft": open the PR as a draft, never ready, per **Opening a PR**. Use the run's built-in PR tool with `draft: true` when it has one, else `origin pr create --status draft --base <base-branch>` or `gh pr create --draft --base <base-branch>`.
