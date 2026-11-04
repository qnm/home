## Steps

- **Before** "1. Route through the **how** skill.": 0. Pin the premise before you read code.
  - Run `git fetch` in every repo the question touches, including sibling repos. Report how far `HEAD` is behind `origin/<default>`, and read code from `origin/<default>`. A local checkout goes stale without warning, and a "present" or "missing" verdict read off it can be wrong.
  - Resolve every ID or number in the prompt before you start. Try `gh pr view <n>` in this repo and each sibling (`-R <owner>/<repo>`), and the tracker for ticket keys. A number that matches nothing here usually names something in another repo. An unresolved ID means the premise is still unchecked, so never record it as "no match" and carry on.
- **After** "4. Apply the **unslop** skill to the reply.": 5. If the user gives a go-ahead to change code, this playbook ends. Before the first edit, open the Bug fix or Feature playbook and rebuild the todolist from its steps. Its gates (deslop, no-comments, the PR-body and ticket skills) don't apply otherwise.
- **Replace** "hand back to the user and re-route to Bug fix or Feature.": hand back to the user, and on their go-ahead follow step 5.
