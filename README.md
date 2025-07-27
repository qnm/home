# Home Manager Configuration

More to be done, but this seems to get us up and running with the old fleek configuration.

```
gh repo clone qnm/home
cd home
export NIXPKGS_ALLOW_UNFREE=1
nix run . switch
home-manager switch -b backup --impure --flake . #qnm
```

## Manual Installation

* docker.io
* steam
* nvidia-container-toolkit
* mesa-utils
* nvidia-modprobe

## Bootstrapping from MacOS

* Install Nix using https://determinate.systems/

## Updating MacOS

* `sudo ./rebuild-mac.sh`
