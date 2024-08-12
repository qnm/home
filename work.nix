{ config, pkgs, misc, inputs, lib, allowed-unfree-packages, androidPath, ... }:

{
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages

      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home.packages = [
    pkgs.zoom-us
    pkgs.slack-dark
    pkgs.watchman
    # pkgs.android-studio won't run on m3
    # pkgs.zulu17
  ];

  home.sessionPath = [
    (androidPath + "/emulator")
    (androidPath + "/platform-tools")
  ];

  programs.java = {
    enable = true;
    package = pkgs.zulu17;
  };
}
