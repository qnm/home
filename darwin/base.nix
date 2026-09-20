{ pkgs, lib, ... }:
{
  # set version
  system.stateVersion = 4;
  system.primaryUser = "qnm";

  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # System Apps
  environment.systemPackages = with pkgs; [
    unnaturalscrollwheels
  ];

  nix = {
    enable = false;
  };

  environment.etc."nix/nix.custom.conf" = {
    # the stock file the determinate installer leaves behind. without this
    # nix-darwin refuses to take the file over.
    knownSha256Hashes = [ "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa" ];
    text = ''
      extra-substituters = https://cache.numtide.com https://herdr.cachix.org
      extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= herdr.cachix.org-1:3nH7IStRsS0ASfdonA0DCRR2ZrSCeWitZ7Kwew0cR4I=
    '';
  };

  # Setup Keyboard
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
    };
  };

  # hack in the obsidian cli
  programs.fish.shellAliases = {
    obsidian = "/Applications/Obsidian.app/Contents/MacOS/Obsidian";
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # I'd rather not have telemetry on my package manager.
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    brews = [
      # wrangler now comes from nixpkgs-unstable via the flake overlay; 26.05's
      # build is still broken on macOS (pnpm/DTS EBADF)
    ];

    # Update these applicatons manually.
    # As brew would update them by unninstalling and installing the newest
    # version, it could lead to data loss.
    casks = [
      "firefox"
      "1password"
      "steam"
      "ollama-app"
      "google-chrome"
      "home-assistant"
      "keepingyouawake"
      "zed"
      "bysiber/cleardisk/cleardisk"
    ];

    taps = [
      "bysiber/cleardisk"
    ];

    # trusted: true is not supported until nix-darwin 26.11+, use extraConfig for now
    extraConfig = ''
      tap "bysiber/cleardisk", trusted: true
    '';

    # Install manually from App Store: Kagi
    masApps = { };
  };
}
