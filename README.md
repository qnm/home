# Fleek Configuration

nix home-manager configs created by [fleek](https://github.com/ublue-os/fleek).

# Bootstrapping

To add a new computer, firstly install Nix to your OS. I prefer the Determinate Systems installer.

They have a [package for MacOS](https://determinate.systems/posts/graphical-nix-installer) or you can install with [their command line installer](https://github.com/DeterminateSystems/nix-installer)

Once you have Nix, we can use

`nix-shell -p gh`

to get ourselves a nix shell with Github's `gh` tool, from there we can login

`gh auth login`

Once logged in, we add our new computer to the configuration

`nix run "https://getfleek.dev/latest.tar.gz" -- join https://github.com/qnm/home.git`

There's a few questions to answer to complete the git setup like 'name' and 'email' but that should be it!


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
