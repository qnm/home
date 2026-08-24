{ pkgs, ... }:
let
  quintSkills = "${pkgs.quint-llm-kit-src}/quint-llm-kit-plugin/skills";
in
{
  home.file.".claude/skills/hegelian-dialectic-skill/SKILL.md".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/KyleAMathews/hegelian-dialectic-skill/refs/heads/main/SKILL.md";
    hash = "sha256-hhAKJTTg5D+UpTETunCmYj54X5qx9ERu2gZXZ1UcPN0=";
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    # quint-llm-kit ships as a plugin, but its entire payload is these three
    # skills, so install them directly rather than registering a marketplace
    # (which home-manager would then own, clobbering claude-plugins-official).
    # The `agentic/` slash commands are deliberately omitted: they assume the
    # kit's Docker image and its container-path MCP servers.
    skills = {
      quint-lang = "${quintSkills}/quint-lang";
      quint-modeling = "${quintSkills}/quint-modeling";
      quint-execute-spec = "${quintSkills}/quint-execute-spec";
    };

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
