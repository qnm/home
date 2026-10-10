{ pkgs, ... }:
let
  heavylock = pkgs.writeShellApplication {
    name = "claude-heavylock";
    runtimeInputs = [
      pkgs.jq
      pkgs.flock
      pkgs.gnugrep
    ];
    text = builtins.readFile ./heavylock/heavylock.sh;
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${heavylock}/bin/claude-heavylock";
        }
      ];
    }
  ];
}
