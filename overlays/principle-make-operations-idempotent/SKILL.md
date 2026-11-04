## The test

- **After** "3. Does re-execution converge to the same end state?":
  4. Which fields does this operation own, and what else writes the same record? Converge only the owned fields. A reconciler that treats the whole record as its own reverts every other writer on the next rerun.
  5. If it converges by skipping records that already exist, which fields does that make permanent? A wrong first write, like a placeholder ID, now survives every rerun. Validate those fields at the boundary (refuse a test value on prod), and ship or ticket a repair mode in the same change. A warning in prose is not a repair path.
