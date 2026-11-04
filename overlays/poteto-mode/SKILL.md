## Non-negotiables

- **After** "Cite only principles whose leaf SKILL.md you read this session.": make that checkable. When a principle first shapes a decision, add a todo to read its leaf and check the work against it. Before the reply, drop any citation whose read todo is still open. A todo that names a skill (`blast-radius`, `deslop`, `no-comments`) closes only after a `Skill` call to it. A summary of facts you gathered another way leaves it open.
- **Before** "Nontrivial change, architecture decision": Before the first tool call → match the task to a playbook (see **Playbooks**), open its file, and open a todolist whose first items are its steps, copied in verbatim, before any task-specific todos. A step you choose not to do stays in the list with a one-line `skip: <reason>`. A deliverable the user named, such as "write it up on the card", adds a step. It is never the reason to skip the steps after it.
- **After** "Reserve the question for a genuine product or preference call": when the user asks to change a value or threshold (a cutoff, a date, a limit), ask what the new value is for before offering build options, and always list an option that changes no code, such as keeping the value and fixing the affected cases by hand.
- **After** "choose its organizing structure per": this applies to investigations too. When the same guard or check repeats in three or more consumers, report the missing structural owner as a finding: a new consumer gets the unsafe default. First check whether a type already forces the check (a union that must be narrowed, a branded type). If it does, the compiler owns it, and the finding is only the consumers that forward the whole value unread.
- **Before** "Docs, RFCs, readmes, PR descriptions, or commit messages": A live test ends in a way you can't explain (a disconnect, an early exit, a stop you didn't trigger) → report it as inconclusive and run it again. Don't explain the anomaly away ("I assume you closed it") and call the run a pass.
- **Replace** "Agent-facing prose also follows the": agent-facing prose follows the **growth-skills:writing-for-agents** skill.
- **Before** "Before commit → the **deslop** skill": Backgrounding a command, or reading any task-completion notice → the notice's exit code is the last command's, so `cmd > log; tail log` reports `tail`. End with `echo exit=$?` right after the real command, or use `set -o pipefail`. Read the log for the tool's success marker before you say it finished. The notice alone is never evidence. Don't change the working tree while a backgrounded check reads it. If you did, re-run the check on the changed files before you trust its verdict.
- **Before** "A defect found mid-task → severity decides its artifact":
  - About to write stored data outside a test (a staging or prod run, a backfill, an admin command) → run the **pstack:blast-radius** skill on every stored field the write touches, and list each reader and writer in the design. Another writer of the same record decides which fields this write may own.
  - A question about whether a type, field or value exists or is used anywhere → search the code first. Prod data needs an interactive login and only samples what exists today, so use it to back up the code, not replace it.
  - A change that would alter what a shared dev command, local config or env default does for the people who already run it → add an opt-in sibling and keep the original's behaviour. Repurposing the original is the user's call, so ask it as its own question, not as one step of a plan. Checking how a pasted or peer agent's plan works doesn't check its scope.
- **Before** "Broken skill mid-task → fix it in its own PR": Proving a test guards a merged fix → reverse-apply that fix's own commit (`git diff <c>^ <c> -- <file> | git apply -R`), run the test, see it fail, then restore and see it pass. A mutation you design yourself proves less than the real pre-fix state.

## Subagents

- **After** "or a babysit watcher.": before calling a delegate stalled or replacing it, read its branch from your own worktree with `git log origin/main..<branch>`, since worktrees share refs. An empty `git ls-remote` and old file mtimes can't show unpushed commits. Brief code delegates to hand back a pushed branch or its commit SHAs, and forbid them from spawning a further background agent. A delegate that must commit runs as a session in its own worktree, not as an `Agent` with worktree isolation, where hooks can refuse every `git commit`. When you take over a delegate's branch, keep its `Co-Authored-By` trailers as written.
- **Before** "A review gate stays closed when no independent reviewer can run.": **Brief a planner with the problem, not the candidates.** A planning or design brief states the goal and constraints, and asks the planner to list the option space and question each constraint before comparing anything. Listing "(a) vs (b)" in the brief caps the plan at those two.

## Writing the reply

- **Before** "Short declarative sentences.":
  - **Answer every queued message.** When the user sent several messages since your last reply, answer each one, even if the answer is a one-line "no". A question sent alongside an actionable request is the one that gets dropped.
  - **Lead with the corrected verdict.** When new evidence reverses an earlier answer, the reply's first sentence is the new yes or no, and it says the old claim is withdrawn. Findings that still hold come after.

## Playbooks

- **After** "A reported defect to reproduce, root-cause, and fix": a ticket URL with "fix", "repro" or "ticket to PR" runs the whole chain, from repro to a draft PR to a ticket comment that links it.
- **After** "File: `playbooks/worktree-cleanup.md`.": Worktree cleanup also covers "remove these worktrees", "delete merged branches", "tidy up branches or worktrees after merge", and removing worktrees or deleting branches as one step of a broader sweep, including the session's own.
