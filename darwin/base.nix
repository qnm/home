{ pkgs, lib, ... }:
{
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  programs.zsh.enable = true;
  programs.fish.enable = true;

  # System Apps
  environment.systemPackages = with pkgs; [
    kitty
    terminal-notifier
  ];

  nix = {
    package = pkgs.nix;
    gc.automatic = true;
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
          "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [
        "@admin" # covers wheel group
      ];
    };
  };

  nix.configureBuildUsers = true;

  # Enable experimental nix command and flakes
  nix.extraOptions = ''
  '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
    extra-platforms = x86_64-darwin aarch64-darwin
    extra-nix-path = nixpkgs=flake:nixpkgs
  '';

  # Setup Keyboard
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # I'd rather not have telemetry on my package manager.
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    brews = [
    ];

    # Update these applicatons manually.
    # As brew would update them by unninstalling and installing the newest
    # version, it could lead to data loss.
    casks = [
      "firefox"
      "unnaturalscrollwheels" # Enable natural scrolling in the trackpad but regular scroll on an external mouse
      "zed" # whilst it cannot be built on macos
      "1password"
      "steam"
      "ollama"
    ];

    taps = [
    ];

    masApps = {
      OnePasswordForSafari = 1569813296;
      Magnet = 441258766;
      Amphetamine = 937984704;
      LocalSend = 1661733229;
      OllamaSpring = 6502970995;
      HomeAssistant = 1099568401;
    };
  };
}
