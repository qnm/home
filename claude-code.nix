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
      };
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
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
