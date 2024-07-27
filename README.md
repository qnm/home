# Home Manager Configuration

More to be done, but this seems to get us up and running with the old fleek configuration.

```
gh repo clone qnm/home
cd home
nix run . switch
home-manager switch -b backup --flake . #qnm
```

## Reference

- [home-manager](https://nix-community.github.io/home-manager/)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)

## Usage

Aliases were added to the config to make it easier to use. To use them, run the following commands:

```bash
# To change into the fleek generated home-manager directory
$ fleeks
# To apply the configuration
$ apply-$(hostname)
```

Your actual aliases are listed below:
    fleeks = "cd ~/.local/share/fleek";

    latest-fleek-version = "nix run https://getfleek.dev/latest.tar.gz -- version";

    update-fleek = "nix run https://getfleek.dev/latest.tar.gz -- update";
