{
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  description = "Fleek Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.1.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Overlays
    

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    
    # Available through 'home-manager --flake .#your-username@your-hostname'
    
    homeConfigurations = {
    
      "qnm@macbook.local" = home-manager.lib.homeManagerConfiguration {
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
           nixpkgs.overlays = [];
          })

        ];
      };
      
      "qnm@fedora" = home-manager.lib.homeManagerConfiguration {
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
          ./fedora/qnm.nix
          ./fedora/custom.nix
          ({
           nixpkgs.overlays = [];
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
