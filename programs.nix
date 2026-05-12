{ config, pkgs, lib, ... }:
{
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.dircolors.enable = true;
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--type-add=tsx:*.tsx"
    ];
  };
  programs.mergiraf.enable = true;
  programs.difftastic.enable = true;

  programs.ghostty = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin pkgs.ghostty-bin;
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "CaskaydiaCove Nerd Font Mono";
      font-size = 15;
      shell-integration-features = "no-cursor,sudo,no-title";
      cursor-style = "block";
      background-opacity = 0.96;
      mouse-hide-while-typing = true;
      mouse-scroll-multiplier = 2;
      window-padding-balance = true;
      window-save-state = "always";
      macos-titlebar-style = "transparent";
      window-colorspace = "display-p3";
      keybind = [
        "shift+enter=text:\\n"
      ];
    };
    installVimSyntax = true;
    enableFishIntegration = true;
  };
  # programs.goose-cli.enable = true;
  # Zed binary comes from the `zed` Homebrew cask (see darwin/base.nix).
  # Settings/keymap live as plain JSON in this repo and are symlinked into
  # ~/.config/zed/ via mkOutOfStoreSymlink so Zed can write back to them.
  home.file.".config/zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Developer/qnm/home/zed/settings.json";
  home.file.".config/zed/keymap.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Developer/qnm/home/zed/keymap.json";
}
