{ pkgs, ... }:
{
  # System Apps
  environment.systemPackages = with pkgs; [
    # Data Build Tool with adapters
    (dbt.withAdapters (adapters: [
      # adapters.dbt-snowflake
    ]))
    libpq
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    brews = [
      "go@1.20"
      "nvm"
      "postgresql@14"
      "redis"
      "cocoapods"
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
      "aws-vpn-client"
    ];

    taps = [
    ];

    masApps = {
      XCode = 497799835;
    };
  };
}
