{ pkgs, lib, ... }:
{
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
      "pop"
      "android-studio"
      "linear-linear"
      "notion"
      "orbstack"
      "miniconda"
    ];

    taps = [
    ];

    masApps = {
      XCode = 497799835;
    };
  };
}
