{ pkgs, ... }:
{
  # Skills are cloned from their upstreams and wired up by ./skills.nix.
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    settings = {
      enabledPlugins = {
        "clangd-lsp@claude-plugins-official" = true;
        "amplitude@claude-plugins-official" = true;
        "growth-skills@growth-skills" = true;
      };
      extraKnownMarketplaces = {
        growth-skills = {
          source = {
            source = "github";
            repo = "amberelectric/growth-skills";
          };
        };
      };
      disableWorkflows = true;
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
}
