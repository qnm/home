{
  description = "Home Manager Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/26.05";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents-nix = {
      url = "github:numtide/llm-agents.nix";
    };

    pi = {
      url = "github:lukasl-dev/pi.nix";
    };

    pi-catppuccin = {
      url = "github:otahontas/pi-coding-agent-catppuccin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # deliberately not following our nixpkgs: herdr pins nixos-unstable plus a
    # rust-overlay toolchain, and won't build against 26.05
    herdr = {
      url = "github:herdrdev/herdr/v0.8.0";
    };

    # skills only; not a flake
    quint-llm-kit = {
      url = "github:quint-co/quint-llm-kit";
      flake = false;
    };
  };

  outputs =
    {
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      nixgl,
      password-shell-plugins,
      home-manager,
      claude-code-nix,
      llm-agents-nix,
      pi,
      pi-catppuccin,
      catppuccin,
      herdr,
      quint-llm-kit,
      ...
    }:
    let
      overlays = [
        (final: prev: {
          claude-code = claude-code-nix.packages.${prev.stdenv.hostPlatform.system}.default;
          qmd = llm-agents-nix.packages.${prev.stdenv.hostPlatform.system}.qmd;
          gh-stack = nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.gh-stack;
          herdr = herdr.packages.${prev.stdenv.hostPlatform.system}.default;
          quint-llm-kit-src = quint-llm-kit;
        })
      ];

      piBunModule =
        { pkgs, ... }:
        {
          programs.pi.coding-agent.package = pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent-bun;
        };
    in
    {
      darwinConfigurations = rec {
        robMBPWifi = robMBP;
        "robMBP" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
            inherit overlays;
          };
          modules = [
            # load base darwin
            ./darwin/base.nix

            # load work darwin
            ./darwin/work.nix

            # setup home-manager
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                # include the home-manager module
                users.qnm =
                  { ... }:
                  {
                    imports = [
                      password-shell-plugins.hmModules.default
                      catppuccin.homeModules.catppuccin
                      pi.homeModules.coding-agent
                      pi-catppuccin.homeManagerModules.default
                      piBunModule
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
        "qnm@pop-os" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = overlays ++ [ nixgl.overlay ];
          };
          modules = [
            (
              { ... }:
              {
                targets.genericLinux.nixGL.packages = nixgl.packages;
                targets.genericLinux.nixGL.defaultWrapper = "mesa";
              }
            )
            password-shell-plugins.hmModules.default
            catppuccin.homeModules.catppuccin
            pi.homeModules.coding-agent
            pi-catppuccin.homeManagerModules.default
            piBunModule
            ./home.nix
          ];
          extraSpecialArgs = {
            inherit nixgl;
          };
        };
        "qnm@penguin" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = overlays ++ [ nixgl.overlay ];
          };
          modules = [
            (
              { ... }:
              {
                targets.genericLinux.nixGL.packages = nixgl.packages;
                targets.genericLinux.nixGL.defaultWrapper = "mesa";

                xdg.configFile."systemd/user/cros-garcon.service.d/override.conf".text = ''
                  [Service]
                  Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
                  Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
                '';
              }
            )
            password-shell-plugins.hmModules.default
            catppuccin.homeModules.catppuccin
            pi.homeModules.coding-agent
            pi-catppuccin.homeManagerModules.default
            piBunModule
            ./home.nix
          ];
          extraSpecialArgs = {
            inherit nixgl;
          };
        };
      };
    };
}
