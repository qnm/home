{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    brews = [
      "csvkit"
      "duckdb"
      "go@1.20"
      "nvm"
      "postgresql@14"
      "redis"
      "cocoapods"
      "aws-sam-cli"
      "withgraphite/tap/graphite"
    ];

    # Update these applicatons manually.
    # As brew would update them by unninstalling and installing the newest
    # version, it could lead to data loss.
    casks = [
      "pop-app"
      "android-studio"
      "linear-linear"
      "notion"
      "orbstack"
      "miniconda"
      "aws-vpn-client"
      "dbeaver-community"
      "claude"
      "copilot-cli"
    ];

    taps = [
      "withgraphite/tap"
    ];

    masApps = {
      XCode = 497799835;
    };
  };
}
