# Home Manager Configuration

Home manager and nix-darwin configuration for personal machines.

## Bootstrapping macOS

Prerequisites:

* Determinate Nix — https://determinate.systems/
* Homebrew — https://brew.sh (nix-darwin manages casks/taps via the `homebrew` module)
* Hostname matches a `darwinConfigurations` key in `flake.nix` (e.g. `robMBP`). Check with `scutil --get LocalHostName`; set with `sudo scutil --set LocalHostName robMBP` if needed.
* Username matches `system.primaryUser` (currently `qnm`).
* GitHub auth for `git clone` (`gh auth login`, or the 1Password SSH agent). The
  skills in [qnm/skills](https://github.com/qnm/skills) come from a private
  repo, so without credentials the first `switch` warns and leaves those skills
  dangling in `~/.claude/skills` instead of failing.
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

Agent skills are git checkouts under `~/Developer`, one per upstream, listed in
[skills-sources.nix](skills-sources.nix). `skills.nix` clones each one at
activation, pins it to the recorded revision, and symlinks every skill
directory into `~/.claude/skills` with `mkOutOfStoreSymlink`, passing the same
paths to pi. A skill can be edited in place and takes effect without a rebuild.

Nothing is vendored: this repository is public, so upstream skills are fetched
rather than republished. Adding an upstream skill is adding its name to a list
in `skills-sources.nix`.

Anything needing local edits lives in the private
[qnm/skills](https://github.com/qnm/skills) instead, so the upstream checkouts
stay clean and bumping a revision is a plain fast-forward. That repo's README
records which of its skills are forks, what changed, and their licenses.

A checkout with uncommitted changes is never moved by activation, and an
upstream that cannot be fetched warns instead of failing the rebuild.

## Updating macOS

```
sudo -H ./rebuild-mac.sh
```

## Linux (home-manager only)

```
gh repo clone qnm/home
cd home
nix run home-manager/release-25.11 -- switch --flake .#qnm@pop-os
```

Replace `qnm@pop-os` with the matching entry in `homeConfigurations` (e.g. `qnm@penguin`).

### Manual Installation (Linux)

* docker.io
* steam
* nvidia-container-toolkit
* mesa-utils
* nvidia-modprobe
