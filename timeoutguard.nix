{ pkgs, ... }:
let
  timeoutguard = pkgs.writeShellApplication {
    name = "claude-timeoutguard";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep ];
    text = builtins.readFile ./timeoutguard/timeoutguard.sh;
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [
    {
      matcher = "Bash";
      hooks = [ { type = "command"; command = "${timeoutguard}/bin/claude-timeoutguard"; } ];
    }
  ];
}
