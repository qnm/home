{
  config,
  pkgs,
  lib,
  ...
}:
let
  kept = lib.filterAttrs (_: agent: agent.enable && agent.config.KeepAlive != null) (
    config.launchd.agents
  );
  agentsFile = pkgs.writeText "agents" (
    lib.concatStrings (
      lib.mapAttrsToList (
        name: agent: "${name}\t${agent.config.Label}\t${agent.config.StandardOutPath}\n"
      ) kept
    )
  );
  agents-status = pkgs.writeShellApplication {
    name = "agents-status";
    runtimeEnv.AGENTS_FILE = agentsFile;
    text = builtins.readFile ./agents-status/agents-status.sh;
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.packages = [ agents-status ];
}
