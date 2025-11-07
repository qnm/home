{
  description = "Home Manager Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/25.05";
    };

    password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nix-darwin,
      nixpkgs,
      nixgl,
      password-shell-plugins,
      home-manager,
      ...
    }:
    {
      darwinConfigurations = {
        "robMBP" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            # load base darwin
            ./darwin/base.nix

            # load work darwin
            ./darwin/work.nix

            # setup home-manager
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                # include the home-manager module
                users.qnm =
                  { ... }:
                  {
                    imports = [
                      password-shell-plugins.hmModules.default
                      ./home.nix
                    ];
                  };
                backupFileExtension = "backup";
              };

              users.users.qnm.home = "/Users/qnm";
            }
          ];
        };
      };

      homeConfigurations = {
        "qnm@penguin" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            allowUnfree = true;
            overlays = [ nixgl.overlay ];
          };
          modules = [
            (
              { ... }:
              {
                nixGL.packages = nixgl.packages;
                nixGL.defaultWrapper = "mesa";
                nixGL.addScripts = [ "mesa" ];

                xdg.configFile."systemd/user/cros-garcon.service.d/override.conf".text = ''
                  [Service]
                  Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
                  Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
                '';
              }
            )
            password-shell-plugins.hmModules.default
            ./home.nix
          ];
          extraSpecialArgs = {
            inherit nixgl;
          };
        };
      };
    };
}
