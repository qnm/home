{ pkgs, ... }:
let
  handoffwrap = pkgs.writeShellApplication {
    name = "claude-handoffwrap";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.coreutils ];
    text = builtins.readFile ./handoffwrap/handoffwrap.sh;
  };
in
{
  programs.claude-code.settings.hooks.Stop = [
    { hooks = [ { type = "command"; command = "${handoffwrap}/bin/claude-handoffwrap"; } ]; }
  ];
}
