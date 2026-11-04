## Candidate learnings

- **After** "Append new candidate learnings here":

### A fix that removes output an operator was checking

- Confidence: candidate
- Skip when: never skip the check itself. When a finding asks to log, print or show less (drop a record from a log, shorten a preview, stop echoing input), first ask whether a human used that output to decide something, such as the preview before a `y/n` prompt on a prod write. If they did, the fix must add a replacement signal that carries the same check without the risky field, or the dismissal must say why the check is safe to lose.
- Do not skip when: the output leaks a secret, a credential or customer data. Fix it, and still give the operator a safe signal for the same check.
- Example signal: "serializes the whole first record" on a CLI whose confirm prompt the operator read field by field before each run.
- Source: one bulk promo-code load. The fix removed the first code from the pre-confirm preview, which was how each file was tied to its campaign.
