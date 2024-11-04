{
  description = "Your dead simple Home Manager configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
     url = "github:LnL7/nix-darwin";
     inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, nixgl, home-manager, ... }@inputs: {
    darwinConfigurations = {
      "macbookpro" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # load base darwin
          ./darwin/base.nix
          # load work darwin
          ./darwin/work.nix

          # setup home-manager
          home-manager.darwinModules.home-manager
          ({
            home-manager = {
              # include the home-manager module
              users.qnm = import ./home.nix;
              backupFileExtension = "backup";
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
      "qnm@penguin" = home-manager.lib.homeManagerConfiguration ({
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          allowUnfree = true;
          overlays = [ nixgl.overlay ];
        };
        modules = [
          ({ pkgs, ...}: {
            # home.packages = with pkgs; [ nixgl.nixglMesa ];
          })
          ./home.nix
        ];
      });

      "qnm@macbookpro" = home-manager.lib.homeManagerConfiguration ({
        modules = [ (import ./home.nix) ];
        pkgs = import nixpkgs {
          system = "aarch64-darwin";   ## For M1/M2/etc Apple Silicon
        };
      });
    };
  };
}
