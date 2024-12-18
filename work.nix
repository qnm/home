{ pkgs, ... }:

let
  androidPath = "$HOME/Library/Android/sdk";
in {
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages

      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home.packages = [
    pkgs.zoom-us
    pkgs.slack
    pkgs.watchman
    # pkgs.android-studio won't run on m3
    # pkgs.cypress won't isnstall on aarch64-darwin

    # for commits
    pkgs.husky

    # for k8s
    # pkgs.tilt broken build

    pkgs.awscli2
    pkgs.ssm-session-manager-plugin
    pkgs.aws-vault
    # pkgs.aws-sam-cli

    pkgs.poetry
    pkgs.sqlfluff
    pkgs.nodePackages.aws-cdk
  ];

  home.sessionPath = [
    (androidPath + "/emulator")
    (androidPath + "/platform-tools")
  ];

  home.shellAliases = {
    # this is the profile I created in Android Studio
    "droid" = "~/Library/Android/sdk/emulator/emulator -avd \"Pixel_4a_API_35\"";
  };

  programs.java = {
    enable = true;
    package = pkgs.zulu17;
  };

  programs.rbenv = {
    enable = true;
    plugins = [
      {
        name = "ruby-build";
        src = pkgs.fetchFromGitHub {
          owner = "rbenv";
          repo = "ruby-build";
          rev = "v20241105";
          hash = "sha256-VutUrVO6+7mGNOYnK8f+2epAbaiqNboelh8MSFz0WaI=";
        };
      }
    ];
  };

  # programs.awscli = {
  #   enable = true;
  #   settings = {
  #     "default" = {
  #       region = "ap-southeast-2";
  #       output = "json";
  #     };
  #   };
  # };
}
