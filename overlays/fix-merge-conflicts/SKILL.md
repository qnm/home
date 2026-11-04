## Trigger

- Also use it when a rebase reports that a merge driver resolved a conflict (mergiraf, a custom driver, any "Solved N conflicts" line). That leaves nothing for `git status` to show, and the resolution is unreviewed.

## Workflow

- **In** "1. Detect all conflicting files from git status": a driver-resolved conflict appears in neither, so also read the rebase output for the driver's own report and treat every file it names as unreviewed. Conflicts can come in diff3 form, with a `||||||| <sha>` base section between `<<<<<<<` and `=======`. A script that rewrites markers must match the `|||||||` line, with the SHA as a variable, or it keeps the base text as if it were one side's.
- **Replace** "2. Resolve each conflict with minimal, correctness-first edits.": for each conflict, read why each side changed: the commit messages, the PRs and the tickets they link. Resolve it with minimal, correctness-first edits that keep both intents. Don't invent new behaviour.
- **After** "5. Run compile, lint, and relevant tests.":
  - For a merge from the base branch, the signal is the PR's own package check and tests. A pre-commit hook that lints every staged file also lints everything the base brought in. It can fail on the base's own code, or be killed when several agents run at once. If it fails or is killed, say so. Don't skip it silently, and when you say CI covers what the hook skipped, name what CI actually lints.
  - Count what the base brings in before you resolve: `git diff --name-only HEAD...origin/<base> | wc -l`. At hundreds of files, the hook can run out of memory, and a bigger heap doesn't fix it. Say so up front and offer to rebase the PR's own commits instead, which lints only those. A rebase rewrites the branch, so the user decides. Never offer `--no-verify`.
  - A merge with no conflict markers can still break the branch. After any base merge, check: each `package.json` the merge touched for a name in both `dependencies` and `devDependencies` (a dependency linter such as knip fails on it); the PR body's standing claims that the base just made false; and repo-wide checks that walk every file of a kind (every `serverless.*.yml`, every handler), run locally.

## Driver-resolved conflicts

A driver that reports success has still made an editorial choice nobody read. Diff each file it named against the branch you rebased onto, with the external diff off:

```sh
git diff --no-ext-diff origin/<base>...HEAD -- <file>
```

Judge the result against the file's own convention, not the driver's output. A driver that keeps both sides can still be wrong at run time: two added steps that run together, where one reads state the other deletes, compile and race. Read what each kept block does, not only where it landed. If you resolved the conflict by hand before switching from merge to rebase, save that file before `git merge --abort` and diff the driver's output against it.

If the fix belongs in an earlier commit, repair it there rather than appending a fixup to the tip:

```sh
git commit --fixup <sha>
GIT_SEQUENCE_EDITOR=true git rebase --autosquash origin/<base>
```

Then prove the series survived against the pre-rebase head, which you must capture before you start:

```sh
git range-diff $(git merge-base <old-head> origin/<base>)..<old-head> origin/<base>..HEAD
```

Context-only differences mean the content is intact. Anything else is a resolution to look at again.

- Don't rename or renumber a migration file to fix its order after a merge. Check whether the runner enforces order first. A renamed migration runs again anywhere the old name already ran.
- When several agents merge the base into different branches at once, limit how many run together so each one's hooks and checks can finish.
