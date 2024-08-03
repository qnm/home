{
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  description = "Fleek Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Overlays
    nixGL.url = "github:nix-community/nixGL";
    nixGL.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs = { self, nixpkgs, nixGL, home-manager, alacritty-theme, ... }@inputs: {
    # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
    # defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;
    
    # Available through 'home-manager --flake .#your-username@your-hostname'
    
    homeConfigurations = {
    
      "qnm@macbookpro.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./macbook.local/qnm.nix
          ./macbook.local/custom.nix
          ({
           nixpkgs.overlays = [ alacritty-theme.overlays.default ];
           home = {
             username = "qnm";
             homeDirectory = "/Users/qnm";
           };
          })

        ];
      };
      
      "qnm@moocow" = home-manager.lib.homeManagerConfiguration {
        # pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
	pkgs = import nixpkgs { system = "x86_64-linux"; allowUnfree = true; };
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./fedora/qnm.nix
          ./fedora/custom.nix
          ({
           nixpkgs.overlays = [ nixGL.overlay ];
          })

        ];
      };
      
      "qnm@windoze" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./windoze/qnm.nix
          ./windoze/custom.nix
          ({
           nixpkgs.overlays = [];
          })

        ];
      };
      
      "qnm@robBook.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./robBook.local/qnm.nix
          ./robBook.local/custom.nix
          ({
           nixpkgs.overlays = [];
          })

        ];
      };
      
    };
  };
}
