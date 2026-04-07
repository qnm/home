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
    ];

    # Install manually: Xcode (xcode-select --install or App Store)
    masApps = {};
  };
}
