{ config, pkgs, misc, inputs, lib, allowed-unfree-packages, ... }:

let
  nixGL = inputs.nixGL.packages."${pkgs.system}".nixGLDefault;
in
rec {
  imports = [
    # todo: remove when https://github.com/nix-community/home-manager/pull/5355 gets merged:
    (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
      sha256 = "0g5yk54766vrmxz26l3j9qnkjifjis3z2izgpsfnczhw243dmxz9";
    })
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
    pkgs.devenv
    pkgs.tilt
    pkgs.shadowenv
    pkgs.neofetch
    pkgs.ripgrep
    pkgs.curl
    pkgs.unzip
    pkgs.tmux
    pkgs.terraform
    pkgs.terraformer
    pkgs.ssm-session-manager-plugin
    pkgs.asdf-vm
    pkgs.adrgen
    pkgs.hasura-cli
    pkgs.google-cloud-sdk
    pkgs.copilot-cli
    pkgs.yadm
    pkgs.jq
    pkgs.wget
    pkgs.gnupg
    # pkgs.alacritty
    # pkgs.alacritty-theme
    pkgs.yadm
    pkgs.graphviz
    pkgs.dconf2nix
    pkgs.ruby_3_2
    pkgs.devbox
    pkgs._1password-gui
    pkgs.docker
    pkgs.docker-compose
    pkgs.ripgrep
    pkgs.curl
    pkgs.unzip
    pkgs.tmux
    pkgs.localsend
    pkgs.hurl
    pkgs.discord
    pkgs.awscli2
    pkgs.nodejs_18
    pkgs.go
    pkgs.ngrok
    # pkgs.conda
    pkgs.cloudflared
    pkgs.yt-dlp
    pkgs.poetry
    pkgs.libffi
    # Fleek Bling
    pkgs.git
    pkgs.htop
    pkgs.github-cli
    pkgs.glab
    pkgs.fzf
    pkgs.ripgrep
    pkgs.vscode
    pkgs.just
    # pkgs.kitty-themes
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
    ];
    in
    basic_pkgs;

  fonts.fontconfig.enable = true;
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;

  programs.alacritty = {
    enable = true;
    # use a color scheme from the overlay
    settings.import = [ pkgs.alacritty-theme.catppuccin_mocha ];
    settings.font.size = 14;
  };

  programs.kitty = {
    enable = true;
    settings.font_size = 14;
    theme = "Catppuccin-Mocha";
    shellIntegration.enableZshIntegration = true;
  };
}
