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
    terminal-notifier
    unnaturalscrollwheels
  ];

  nix = {
    enable = false;
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
