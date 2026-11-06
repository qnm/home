{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "com.superlogical.rex";
  rex = "${config.home.homeDirectory}/.local/bin/rex";
  stateDir = "${config.home.homeDirectory}/.local/state/rex-restore";
  restore = pkgs.writeShellScript "rex-restore" ''
    until [ -x ${lib.escapeShellArg rex} ] && ${lib.escapeShellArg rex} --autostart=false server status >/dev/null 2>&1; do
      sleep 5
    done
    exec ${lib.escapeShellArg rex} --autostart=false do --all ${./rex/restore.lua} \
      snapshot=${lib.escapeShellArg "${stateDir}/programs.json"}
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults.${domain} = builtins.fromJSON (builtins.readFile ./rex/defaults.json);

  home.activation.rexThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write ${domain} Workspace.customThemes -data \
      "$(${pkgs.jq}/bin/jq -c . ${./rex/themes.json} | tr -d '\n' | /usr/bin/xxd -p | tr -d '\n')"
  '';

  home.activation.rexRestoreStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg stateDir}
  '';

  launchd.agents.rex-restore = {
    enable = true;
    config = {
      ProgramArguments = [ "${restore}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "${stateDir}/rex-restore.log";
      StandardErrorPath = "${stateDir}/rex-restore.log";
    };
  };
}
