# Home Manager Configuration

Home manager and nix-darwin configuration for personal machines.

## Bootstrapping macOS

Prerequisites:

* Determinate Nix — https://determinate.systems/
* Homebrew — https://brew.sh (nix-darwin manages casks/taps via the `homebrew` module)
* Hostname matches a `darwinConfigurations` key in `flake.nix` (e.g. `robMBP`). Check with `scutil --get LocalHostName`; set with `sudo scutil --set LocalHostName robMBP` if needed.
* Username matches `system.primaryUser` (currently `qnm`).

Then:

```
gh repo clone qnm/home
cd home
sudo -H nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#robMBP
chsh -s /run/current-system/sw/bin/fish
```

This one command builds nix-darwin, activates the config, and runs home-manager (it's wired in as a darwin module). After the first run, `darwin-rebuild` is on PATH.

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
