## When this fires

Also run it, before you write anything down, for:

- Your own claim before it goes into a ticket, plan, doc, commit or PR body, or before you tell the user their premise is wrong or skip a re-test: "that is the whole fix", "same behaviour", "no code change needed".
- A risk you're about to report, such as an IAM or access gap you "could not confirm". Look for a sibling consumer that already does the same thing on the same role or path. If one exists, the risk is gone. Report it only if none does.
- A hunt for every path that reaches a value ("find every send path"). Search the code that reads the value, not the channel word. A target never found leaves the verdict open.
- A changed return shape or signature on a shared function. A green typecheck proves only the typed callers moved. Doubles typed `as any` or a bare `jest.fn().mockResolvedValue(...)` still return the old shape. Grep every test file for mocks of the symbol, and run each touched package's format, lint and test gates.
- A validator or schema that starts accepting a new variant. Trace it on origin after a fetch, not the local checkout.
- A prod write or backfill to a stored field. List every reader first, including displays, and for a Mailchimp or CRM field its journeys and automations.
- A change to a dev script, local config or env default. The people who run it are its consumers, and grep finds none of them. Name them from the script's header, README and package.json entry. The proof is the resolved config (`serverless print` or equivalent) before and after, with any override set. If the old command now gives a different result, add a sibling entry point instead.
- A tool, emulator or architecture recommendation that rests on a capability claim ("it runs Lambdas"). Probe it before you recommend it.

## Proof

- **After** "Step 4 is usually one small script": the harness must be able to fail. A run that only prints matches can't tell "equivalent" from "didn't test the case that differs". Add the case you know diverges as a control and let it print the difference. If every case passes and you knew one shouldn't, you tested the wrong cases.
- A verdict about main holds only at the commit you checked. In the same turn as each write that repeats a verdict (a card, a doc edit, a subagent brief), fetch origin and run `git log <checked-sha>..origin/main -- <paths the verdict cites>`. If anything landed, check again before you write.

## Steps

- **Before** "6. For a big or wide change, run it as an `arena`.": if the change moves who is eligible for something, count each group it moves. Run a read-only prod query for how many records gain and how many lose, and put the numbers in the PR before it leaves draft. If you can't run the count, the PR says "count not run". A list of who gains and loses with no numbers is a claim, not a check.
