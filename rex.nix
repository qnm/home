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
  agent = "org.nix-community.home.rex-restore";
  retry = pkgs.writeShellScriptBin "rex-restore-retry" ''
    set -eu
    dir=${lib.escapeShellArg stateDir}
    domain=gui/$(/usr/bin/id -u)
    if [ ! -e "$dir/programs.json.previous" ]; then
      echo "rex-restore-retry: no earlier snapshot at $dir/programs.json.previous" >&2
      exit 1
    fi
    /bin/launchctl bootout "$domain/${agent}" 2>/dev/null || true
    cp "$dir/programs.json.previous" "$dir/programs.json"
    rm -f "$dir/programs.json.restored-for"
    /bin/launchctl bootstrap "$domain" "$HOME/Library/LaunchAgents/${agent}.plist"
    echo "Restore restarted. Progress is in $dir/rex-restore.log"
  '';
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults.${domain} = builtins.fromJSON (builtins.readFile ./rex/defaults.json);

  home.activation.rexThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write ${domain} Workspace.customThemes -data \
      "$(${pkgs.jq}/bin/jq -c . ${./rex/themes.json} | tr -d '\n' | /usr/bin/xxd -p | tr -d '\n')"
  '';

  home.packages = [ retry ];

  home.file.".config/rex/init.lua".source = ./rex/init.lua;

  home.activation.rexConfigReload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${lib.escapeShellArg rex} --autostart=false server status >/dev/null 2>&1; then
      run ${lib.escapeShellArg rex} --autostart=false config reload >/dev/null
    fi
  '';

  home.activation.rexSkill =
    lib.hm.dag.entryAfter
      [
        "claudeSettings"
        "skills"
      ]
      ''
        if [ -x ${lib.escapeShellArg rex} ]; then
          run ${lib.escapeShellArg rex} --autostart=false skill setup --agent claude --session-naming >/dev/null \
            || echo "rex: cannot install the Claude skill, run 'rex skill status'"
        fi
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
