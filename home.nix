{ config, pkgs, lib, inputs, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported platform";
  nixGL = inputs.nixGL.packages."${pkgs.system}".nixGLDefault;
in
{
  imports = [
    ## Modularize your home.nix by moving statements into other files
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

  home.stateVersion = "24.05"; # Don't change this. This will not upgrade your home-manager.
  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  programs.kitty = {
    enable = true;
    settings.font_size = 14;
    theme = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;
  };

  home.packages = with pkgs; ([
    # Common packages
    hello
    (python311.withPackages (ppkgs: [
      ppkgs.virtualenv
      ppkgs.notebook
    ]))
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
    nodejs_18
    yt-dlp
    libffi
    htop
    glab
    fzf
    just
    kitty-themes
    nix-search-cli
  ] ++ lib.optionals isLinux [
    # GNU/Linux packages
  ]
  ++ lib.optionals isDarwin [
    # macOS packages
  ]);
}

