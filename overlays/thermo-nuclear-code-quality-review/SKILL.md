## Non-Negotiable Additional Standards

- **After** "Do not over-index on micro-optimizations": read the ticket before the diff. The branch name or PR title carries the ticket ID. Fetch it. Review the diff against what was asked for as well as against these standards. Structural review is blind to the requirement, and restructuring is the most expensive place to be wrong about one: a remediation built on a misread spec entrenches the deviation in a new type, its tests and the PR body. Where the change departs from the ticket, say so. A deliberate departure is fine, but surfacing it is the reviewer's job.
- When the branch has no diff, don't invent a scope. Run `git fetch` first. If the user named a PR or ticket, resolve it, including in sibling repos (`gh pr view <n> -R <repo>`), and review it with `gh pr diff <n>`. Review a whole module only after the user confirms that scope, and review it on `origin/<default>`, not the local checkout.

## Primary Review Questions

- **After** "Is this orchestration more sequential or less atomic": does the change match the ticket, and where it doesn't, is that deliberate? If a proposal names a new concept, what domain claim does it rest on, and where does the code enforce it?

## Preferred Remedies

- **In** "Replace condition chains with a typed model or explicit dispatcher.": naming a new concept is the expensive remedy. A domain noun spreads into types, tests, PR bodies and reviewers' heads faster than it can be unwound. Before proposing one: state the domain claim the name asserts and where the code enforces it; search for the word already in use, since existing vocabulary that disagrees is evidence against the name; and check what the name would have to know. Take a name the domain owner rejects as settled on the first pass.
- Reusing a stored name isn't free either. Moving an existing stored field to a new meaning and adding a new name for the old one makes every reader switch to `newField ?? oldField`, and readers nobody edited silently change meaning. When a diff changes what a stored field means, check what it holds on the base branch first. If existing readers are already right, keep the field and add a new one for the new fact. A bug the PR claims to fix that can't happen on the base branch is the tell: the change created it.

## Approval Bar

- **After** "If those conditions are not met, leave explicit, actionable feedback": say what you didn't check. This review is structural, so it's not a merge verdict, and "approve, all findings closed" reads as one. Either verify the change against its ticket and say so, or state plainly that spec conformance was out of scope.
