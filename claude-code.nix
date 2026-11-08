{
  config,
  pkgs,
  lib,
  ...
}:
let
  settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  declared = config.home.file.${settingsPath}.source;
in
{
  # Skills are cloned from their upstreams and wired up by ./skills.nix.
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    context = ./claude-code/CLAUDE.md;

    settings = {
      enabledPlugins = {
        "clangd-lsp@claude-plugins-official" = true;
        "amplitude@claude-plugins-official" = true;
        "growth-skills@growth-skills" = true;
        "pstack@pstack-claude" = true;
      };
      extraKnownMarketplaces = {
        pstack-claude = {
          source = {
            source = "github";
            repo = "michael-denyer/pstack-claude";
          };
        };
        growth-skills = {
          source = {
            source = "github";
            repo = "amberelectric/growth-skills";
          };
        };
      };
      disableWorkflows = true;
      cleanupPeriodDays = 999999999;
      permissions.deny = [
        "CronCreate"
        "CronDelete"
        "CronList"
      ];
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        CLAUDE_CODE_SUBAGENT_MODEL = "sonnet";
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = "400000";
      };
      statusLine = {
        type = "command";
        command = "bunx -y ccstatusline@latest";
        padding = 0;
        refreshInterval = 10;
      };
      sandbox = {
        enabled = true;
        excludedCommands = [
          "op *"
          "gh *"
        ];
        network = {
          allowMachLookup = [ "com.apple.trustd.agent" ];
        };
      };
    };
  };

  home.file.${settingsPath}.enable = lib.mkForce false;

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target=${lib.escapeShellArg settingsPath}
    previous=${lib.escapeShellArg "${config.programs.claude-code.configDir}/.settings-declared.json"}
    base=$(${pkgs.coreutils}/bin/mktemp)
    if [ -f "$target" ] && [ ! -L "$target" ]; then cat "$target" >"$base"; else echo '{}' >"$base"; fi
    [ -f "$previous" ] || echo '{}' >"$previous"
    merged=$(${pkgs.coreutils}/bin/mktemp)
    ${lib.getExe pkgs.jq} -s -f ${./claude-code/merge-settings.jq} "$base" "$previous" ${declared} >"$merged"
    run rm -f "$target"
    run install -m 600 "$merged" "$target"
    run install -m 600 ${declared} "$previous"
    rm -f "$base" "$merged"
  '';
}
