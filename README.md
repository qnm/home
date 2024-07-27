# Home Manager Configuration

More to be done, but this seems to get us up and running with the old fleek configuration.

```
gh repo clone qnm/home
cd home
nix run . switch
home-manager switch -b backup --flake . #qnm
```

## Manual Installation

* docker.io
* steam
* nvidia-container-toolkit
* mesa-utils
* nvidia-modprobe
