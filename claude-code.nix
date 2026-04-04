{ pkgs, ... }:
{
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
    };
  };
}
