{
  description = "Home Manager Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Overlays
    nixGL.url = "github:nix-community/nixGL";
    nixGL.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nix-darwin, nixpkgs, nixGL, home-manager, ... }@inputs: {
    # defaultPackage.x86_64-linux = home-manager.defaultPackage.x86_64-linux;
    # defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;

    # Available through 'home-manager --flake .#your-username@your-hostname'
    darwinConfigurations = {
          "macbookpro" = nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              # load base darwin
              ./darwin/base.nix
              # load work darwin
              ./darwin/work.nix
              #
              # setup home-manager
              home-manager.darwinModules.home-manager
              ({
                home-manager = {
                  # include the home-manager module
                  users.qnm = import ./home.nix;
                };
                users.users.qnm.home = "/Users/qnm";
              })
            ];
            specialArgs = {
              inherit inputs;
            };
          };
        };

    homeConfigurations = {
      "qnm@pop-os" = home-manager.lib.homeManagerConfiguration {
        # pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
	    pkgs = import nixpkgs { system = "x86_64-linux"; allowUnfree = true; };
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix
          ./work.nix
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
