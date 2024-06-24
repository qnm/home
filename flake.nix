{
  description = "Home Manager Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
