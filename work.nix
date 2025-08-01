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

  home.packages = with pkgs; [
    zoom-us
    slack
    watchman
    # android-studio won't run on m3
    # cypress won't install on aarch64-darwin

    # for commits
    husky

    # for k8s
    # tilt broken build
    yarn

    awscli2
    ssm-session-manager-plugin
    aws-vault
    aws-sam-cli

    poetry
    sqlfluff
    nodePackages.aws-cdk

    # gcloud
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.pubsub-emulator
      google-cloud-sdk.components.cloud_sql_proxy
    ])

    # Data Build Tool with adapters
    (dbt.withAdapters (adapters: [
      adapters.dbt-snowflake
    ]))
    libpq

    _1password-cli
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
