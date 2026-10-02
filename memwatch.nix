{
  config,
  pkgs,
  lib,
  ...
}:
let
  memwatch = pkgs.writeShellApplication {
    name = "memwatch";
    text = builtins.readFile ./memwatch/memwatch.sh;
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ memwatch ];

  launchd.agents.memwatch = {
    enable = true;
    config = {
      ProgramArguments = [ "${memwatch}/bin/memwatch" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/memwatch.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/memwatch.log";
    };
  };
}
