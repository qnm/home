{ pkgs, ... }:
let
  replysign = pkgs.writeShellApplication {
    name = "claude-replysign";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep pkgs.gnused ];
    text = builtins.readFile ./replysign/replysign.sh;
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [ { type = "command"; command = "${replysign}/bin/claude-replysign"; } ];
    }
  ];
}
