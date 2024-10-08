{ config, pkgs, misc, inputs, lib, allowed-unfree-packages, ... }:

let
  nixGL = inputs.nixGL.packages."${pkgs.system}".nixGLDefault;
in
rec {
  imports = [
    # todo: remove when https://github.com/nix-community/home-manager/pull/5355 gets merged:
    # (builtins.fetchurl {
    #   url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
    #   sha256 = "0g5yk54766vrmxz26l3j9qnkjifjis3z2izgpsfnczhw243dmxz9";
    # })
    ./work.nix
    ./path.nix
    ./shell.nix
    ./user.nix
    ./aliases.nix
    ./programs.nix
  ];

  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages

      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  # managed by fleek, modify ~/.fleek.yml to change installed packages

  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages =
    let
      # nixGLwrap = config.lib.nixGL.wrap;
      basic_pkgs = [
        # (nixGLwrap pkgs.mesa-demos)
    # nixGL
    (pkgs.python311.withPackages (ppkgs: [
      ppkgs.virtualenv
      ppkgs.notebook
    ]))
    pkgs.cargo
    pkgs.pkg-config
    pkgs.openssl
    pkgs.devenv
    pkgs.shadowenv
    pkgs.ripgrep
    pkgs.curl
    pkgs.unzip
    pkgs.yadm
    pkgs.jq
    pkgs.wget
    pkgs.gnupg
    pkgs.yadm
    pkgs.dconf2nix
    pkgs.devbox
    pkgs.curl
    pkgs.unzip
    pkgs.tmux
    pkgs.localsend
    pkgs.hurl
    pkgs.discord
    pkgs.nodejs_18
    pkgs.ngrok
    pkgs.yt-dlp
    pkgs.libffi
    pkgs.htop
    pkgs.glab
    pkgs.fzf
    pkgs.just
    pkgs.kitty-themes
    pkgs.nix-search-cli
    ];
    in
    basic_pkgs;

  fonts.fontconfig.enable = true;
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;

  programs.alacritty = {
    enable = true;
    settings.font.size = 14;
  };

  programs.kitty = {
    enable = true;
    settings.font_size = 14;
    theme = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;
  };
}
