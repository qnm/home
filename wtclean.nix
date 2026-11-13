{ pkgs, ... }:
let
  wt-clean = pkgs.writeShellApplication {
    name = "wt-clean";
    runtimeInputs = [
      pkgs.git
      pkgs.gawk
      pkgs.gnugrep
      pkgs.coreutils
    ];
    text = builtins.readFile ./wtclean/wt-clean.sh;
  };
in
{
  home.packages = [ wt-clean ];
}
