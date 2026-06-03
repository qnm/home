{ pkgs, ... }:
{
  home.file.".claude/skills/hegelian-dialectic-skill/SKILL.md".source =
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/KyleAMathews/hegelian-dialectic-skill/refs/heads/main/SKILL.md";
      hash = "sha256-hhAKJTTg5D+UpTETunCmYj54X5qx9ERu2gZXZ1UcPN0=";
    };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    settings = {
      enabledPlugins = {
        "clangd-lsp@claude-plugins-official" = true;
      };
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
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
