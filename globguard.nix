{ pkgs, ... }:
let
  globguard = pkgs.writeShellApplication {
    name = "claude-globguard";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnugrep
      pkgs.gnused
      pkgs.coreutils
    ];
    text = builtins.readFile ./globguard/globguard.sh;
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${globguard}/bin/claude-globguard";
        }
      ];
    }
  ];
}
