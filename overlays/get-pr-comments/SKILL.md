## Workflow

These replace the four upstream steps. The PR may be one the user names by number or URL, not only the current branch's. A reviewer named with no PR means the current branch's PR.

### 1. Resolve the PR and its code

```bash
gh pr view <n> --repo <owner/repo> --json title,body,state,headRefName,files
```

The PR's code is on `headRefName`, not in your working tree. A file the review names may not exist where you are. Read the branch without switching to it:

```bash
git worktree list
git show <ref>:<path>
git grep -n <symbol> <ref> -- <paths>
```

`git checkout` fails if another worktree holds the branch. Then that worktree is where edits belong, and every later command needs its absolute path. Pipe git output through `| cat`. If a diff will be parsed, pass `--no-ext-diff` after the subcommand (`git diff --no-ext-diff …`).

### 2. Fetch both kinds of comment

```bash
gh api repos/<owner/repo>/pulls/<n>/comments --paginate
gh api repos/<owner/repo>/issues/<n>/comments --paginate
```

The first is review threads on lines, the second is conversation comments. Filter with `--jq`; bot comments can be huge.

### 3. Judge each comment

Group by whether it's real, and say which. A comment asserting something about existing code ("I worry some caller does X") is a **pstack:blast-radius** question. Prove it and answer with the proof.

A comment asking whether something can happen at run time ("what if the status write fails after the data write?") is settled by running it. Write a throwaway test from the repo's real factories that drives the named path, run it, paste what it printed, and delete the test. Answer yes or no first, then the evidence.

### 4. Reply inside the thread

Reply to the thread's root review-comment id, not the issue endpoint, or it lands outside the thread:

```bash
gh api repos/<owner/repo>/pulls/<n>/comments/<thread-root-id>/replies \
  -F body=@/abs/path/reply.md --jq '.html_url'
```

Write the body to a file first so backticks and newlines survive. Ask for `.html_url` so you can hand over the permalink.

Posting is outward-facing: show the draft and get approval first. To fix a reply already up, edit it in place with `gh api -X PATCH repos/<owner/repo>/pulls/comments/<id> -F body=@<abs path>`, not a second reply.

When `gh` is blocked and you hand the command to the user, give absolute paths and `--repo`: their `!` shell starts in your last working directory. Mark a reply command "run once". It already posted if it printed a URL.
