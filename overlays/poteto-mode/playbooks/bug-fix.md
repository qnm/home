## Steps

- **Before** "1. Reproduce it yourself on the matching surface": create the **Opening a PR** worktree first, so the fix you verify is the fix you ship. Before you reproduce, read every ticket the source links, issue and comments, through the tracker MCP. The site, account or input you need is often already there, so don't ask the user for it.
- **After** "Ask the user only with a stated, specific reason": when the repo has no driver skill for that surface, run **pstack:create-verification-skill** for it after the repro so the next run doesn't rediscover the bring-up. On a visual surface, capture the failure now on the base commit. That capture is the PR's "before".
- **After** "Confirm the surviving *mechanism* with runtime evidence": when the defect is a corrupted stored value, list every writer of that field, and every reader of the key that led to the bad write, before you call the mechanism confirmed. The ticket's hypothesis names one writer, and a sibling path on the same key stays broken after the fix.
- **In** "4. Verify on the same surface.": verify from the worktree branch, with the same input. On a visual surface, capture it again. That capture is the PR's "after".
- **In** "6. Run **Opening a PR**.": put the before and after captures in the body.
- **After** "6. Run **Opening a PR**.": 7. If the task came from a ticket, post the root cause, fix, verification and PR URL to the ticket. Do this after step 6, never before: a comment written before the PR exists is stale as soon as it opens.

## Run the whole chain

A deliverable the user names, such as "write it up on the card", adds a step. It doesn't end the chain. Only an explicit "no PR" or "investigate only" stops before step 6, and "the user did not ask for a PR" is not a valid `skip:` reason.

- **In** "**Reply:** what was broken, root cause, fix, how you verified.": also give the PR link and the ticket comment.
