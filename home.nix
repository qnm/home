{ config, pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported Platform";
in {
  imports = [
    ./work.nix
    ./path.nix
    ./shell.nix
    ./user.nix
    ./aliases.nix
    ./programs.nix
  ];

  home.username = "qnm";
  home.homeDirectory =
    if isLinux then "/home/qnm" else
    if isDarwin then "/Users/qnm" else unsupported;

  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages

      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages = with pkgs; ([
    nixd
    nil
    nixfmt-rfc-style
    cargo
    pkg-config
    openssl
    devenv
    shadowenv
    ripgrep
    curl
    unzip
    yadm
    jq
    wget
    gnupg
    yadm
    dconf2nix
    devbox
    curl
    unzip
    tmux
    localsend
    hurl
    discord
    nodejs_18
    ngrok
    yt-dlp
    libffi
    htop
    glab
    fzf
    just
    kitty-themes
    nix-search-cli
    fnm
  ]
  ++ lib.optionals isLinux [
    # GNU/Linux packages
  ]
  ++ lib.optionals isDarwin [
    # macOS packages
  ]);

  fonts.fontconfig.enable = true;
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;

  programs.kitty = {
    enable = true;
    settings.font_size = 12;
    themeFile = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;
    package = config.lib.nixGL.wrap pkgs.kitty;
  };
}
