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
sudo -H nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#robMBP \
  --option extra-substituters "https://cache.numtide.com https://pi.cachix.org https://nix-community.cachix.org" \
  --option extra-trusted-public-keys "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
chsh -s /run/current-system/sw/bin/fish
```

This one command builds nix-darwin, activates the config, and runs home-manager (it's wired in as a darwin module). After the first run, `darwin-rebuild` is on PATH.

## Bootstrapping Linux (standalone home-manager)

Targets the `qnm@omarchy` / `qnm@penguin` outputs in `flake.nix`, for a
non-NixOS host with the standard Nix installer (Omarchy, Crostini).

Prerequisites:

* Nix with flakes enabled — https://nixos.org/download
* Git, and GitHub auth for the private [qnm/skills](https://github.com/qnm/skills) checkout. The checkout is cloned through `gh` (keyring auth), so `gh auth login` is enough.
* 1Password desktop app → Settings → Developer: enable **"Integrate with 1Password CLI"**, as on macOS. Needed by the `_1password-shell-plugins` wrappers for `gh`, `aws`, etc., but *not* for the skills checkout.

Then:

```
gh repo clone qnm/home
cd home
sudo ./setup-nix-caches.sh
nix run .#home-manager -- switch -b backup --flake .#"qnm@omarchy"
```

`.#home-manager` is an `apps` output pinned to the flake's `home-manager`
input (`release-26.05`, matching `nixpkgs`), so the switch does not pull
`home-manager/master` or its own nixpkgs. Always pass `--flake .#<host>`:
the CLI is a driver, the modules still come from the flake.

`setup-nix-caches.sh` is the Linux counterpart to the `/etc/nix/nix.custom.conf`
block in [darwin/base.nix](darwin/base.nix): it adds the numtide cache to the
system Nix config and restarts the daemon. It must run as root — see
[Binary caches](#binary-caches).

## Binary caches

`claude-code` and `wrap-buddy` come from [cache.numtide.com](https://cache.numtide.com), `pi` from [pi.cachix.org](https://pi.cachix.org), and bun2nix's Bun toolchain from [nix-community.cachix.org](https://nix-community.cachix.org). None are in cache.nixos.org, so without these caches those packages build from source, which needs a reachable `codeload.github.com` and fails when that is not.

* **macOS:** [darwin/base.nix](darwin/base.nix) declares the caches in `/etc/nix/nix.custom.conf`, which Determinate's `nix.conf` includes. Put substituters there, not in `nix.conf` — Determinate overwrites that file. The `--option extra-substituters` flags in the first bootstrap command are only needed before that file exists.
* **Linux:** run `sudo ./setup-nix-caches.sh` once. It writes the same substituters and keys to `/etc/nix/nix.conf` (or `nix.custom.conf` under Determinate) and restarts `nix-daemon`.

Either way the cache must be system-wide: `trusted-users` is `root`, and an untrusted user's substituter (including one from a flake's `nixConfig`) is ignored.

Two rules keep the caches working:

* Never add `inputs.nixpkgs.follows` to `llm-agents-nix`. It rebases them off the nixpkgs their CI built against, which changes the store hash and misses the cache every time.
* If a rebuild aborts with `Unexpected files in /etc`, Determinate rewrote `nix.custom.conf`. Run `shasum -a 256 /etc/nix/nix.custom.conf` and add the hash to `knownSha256Hashes` in [darwin/base.nix](darwin/base.nix).

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
