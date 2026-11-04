## Steps

- **Replace** "Use the **plugin-dev:skill-development** skill": use the **growth-skills:writing-for-agents** skill.
- **After** "cross-skill links resolve.": for a script that prints verdicts, check that each lookup failure (a missing commit, a cache miss, a denied call) prints its own UNKNOWN state, never the confident negative.
- **After** "Test cases if structural. Skip if subjective.": a skill that ships scripts or drives a live system also gets a cold run: a fresh agent with no context follows it against a real target, later than your own runs. Pick inputs that reach each branch and each environment the request names. Its friction log is the test result. Fix the friction, then run it cold again.
