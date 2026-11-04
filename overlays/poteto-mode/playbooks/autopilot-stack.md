## Steps

- **Before** "**Reply:** list each PR with its verdict":
  - **Set up once before fan-out.** Run the shared setup (install, registry auth) in the root before spawning owners, so a token failure is found once. Name the base branch (`origin/<trunk>` after a fetch) in every brief, because an isolated worktree starts from the root's HEAD.
  - **Resume with a location.** The harness removes an isolated worktree with no changes when its agent stops. When resuming an owner that stopped before editing, name where it should rebuild its worktree.
  - **Stop an owner that hands a step to the user.** An owner can't see the user's `!` output, so it retries and guesses. Stop it, check the result from the root, then resume it with that result.
  - **Audit a category, not a field.** When the diff audit finds a leak, name the property ("no customer PII in logs") and require an allowlist of safe fields. Never ask an owner to remove the one field you noticed. Grep every `console.` and `logger.` line the diff adds before passing it.
