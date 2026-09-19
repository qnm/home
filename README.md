# Home Manager Configuration

Home manager and nix-darwin configuration for personal machines.

## Bootstrapping macOS

Prerequisites:

* Determinate Nix — https://determinate.systems/
* Homebrew — https://brew.sh (nix-darwin manages casks/taps via the `homebrew` module)
* Hostname matches a `darwinConfigurations` key in `flake.nix` (e.g. `robMBP`). Check with `scutil --get LocalHostName`; set with `sudo scutil --set LocalHostName robMBP` if needed.
* Username matches `system.primaryUser` (currently `qnm`).
* GitHub auth for `git clone` (`gh auth login`, or the 1Password SSH agent).
  Every agent skill comes from the private
  [qnm/skills](https://github.com/qnm/skills), so without credentials the first
  `switch` warns and leaves `~/.claude/skills` empty instead of failing.
* 1Password desktop app → Settings → Developer: enable **"Integrate with 1Password CLI"** (and "Use the SSH agent"). Required by the `_1password-shell-plugins` wrappers for `gh`, `aws`, etc. — without it they fail with `Shell Plugins can only be used with the 1Password app integration enabled`. The toggle can get reset by 1Password updates.

Then:

```
gh repo clone qnm/home
cd home
sudo -H nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#robMBP
chsh -s /run/current-system/sw/bin/fish
```

This one command builds nix-darwin, activates the config, and runs home-manager (it's wired in as a darwin module). After the first run, `darwin-rebuild` is on PATH.

## Skills

Agent skills live entirely in the private
[qnm/skills](https://github.com/qnm/skills), which vendors each upstream as a
git submodule, carries the manifest of what installs under which name, and
carries the local edits as patches. Nothing is vendored here: this repository
is public.

[skills.nix](skills.nix) holds no list of skills. It guarantees that checkout
and its submodules are in place, then runs `skills-patch`, which applies the
patches and writes `~/.claude/skills` from the manifest. pi is pointed at the
same directory and discovers them at run time.

So adding, renaming, patching or removing a skill is a change to that repo and
a `skills-patch link`, never a rebuild. `darwin-rebuild` is only needed if
`skills.nix` itself changes. See that repo's `update-skills` and
`patch-a-skill` skills for the procedures.

`skills-patch` verbs: `status`, `link` to rewrite the symlinks, `apply` to
replay patches, `capture` to compile local edits back into patches, `reset` to
discard them.

A submodule with uncaptured edits is reported and left alone rather than being
reset, and a repo that cannot be fetched warns instead of failing the rebuild.
