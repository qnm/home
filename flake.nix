{
  description = "Home Manager Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
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
            nixGL.packages = nixgl.packages;
            nixGL.defaultWrapper = "mesa";
            nixGL.installScripts = [ "mesa" ];

            xdg.configFile."systemd/user/cros-garcon.service.d/override.conf".text = ''
              [Service]
              Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
              Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
            '';
          })
          ./home.nix
        ];
        extraSpecialArgs = {
          inherit nixgl;
        };
      });
    };
  };
}
