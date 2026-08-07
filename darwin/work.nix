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
      "aws-sam-cli"
      "snowflake-cli"
      "watchman"
      "colima"
    ];

    # Update these applicatons manually.
    # As brew would update them by unninstalling and installing the newest
    # version, it could lead to data loss.
    casks = [
      "pop-app"
      "android-studio"
      "linear"
      "notion"
      "miniconda"
      "aws-vpn-client"
      "dbeaver-community"
      "claude"
      "copilot-cli"
      "docker/tap/sbx"
    ];

    taps = [
      "docker/tap"
    ];

    extraConfig = ''
      tap "docker/tap", trusted: true
    '';

    # Install manually: Xcode (xcode-select --install or App Store)
    masApps = { };
  };
}
