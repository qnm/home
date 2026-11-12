{ pkgs, ... }:
let
  worktreeguard = pkgs.writeShellApplication {
    name = "claude-worktreeguard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnugrep
      pkgs.git
    ];
    text = builtins.readFile ./worktreeguard/worktreeguard.sh;
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${worktreeguard}/bin/claude-worktreeguard";
        }
      ];
    }
  ];
}
