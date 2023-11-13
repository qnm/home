{ config, pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      
      
    };
  };

  
  # managed by fleek, modify ~/.fleek.yml to change installed packages
  
  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages = [
    # user selected packages
    pkgs.shadowenv
    pkgs.neofetch
    pkgs.ripgrep
    pkgs.curl
    pkgs.unzip
    pkgs.tmux
    pkgs.terraform
    pkgs.terraformer
    pkgs.awscli2
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
    pkgs.alacritty
    pkgs.yadm
    pkgs.graphviz
    pkgs.dconf2nix
    pkgs.ruby_3_2
    pkgs.devbox
    pkgs._1password-gui
    # Fleek Bling
    pkgs.git
    pkgs.htop
    pkgs.github-cli
    pkgs.glab
    pkgs.fzf
    pkgs.ripgrep
    pkgs.vscode
    pkgs.just
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  fonts.fontconfig.enable = true; 
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;
}
