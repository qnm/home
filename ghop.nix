{ pkgs, ... }:
let
  wrapper = pkgs.writeShellApplication {
    name = "gh";
    text = ''
      real_gh_dir=${pkgs.gh}/bin
    ''
    + builtins.readFile ./ghop/ghop.sh;
  };
  gh = pkgs.symlinkJoin {
    name = "gh-op-${pkgs.gh.version}";
    paths = [
      wrapper
      pkgs.gh
    ];
    meta.mainProgram = "gh";
  };
in
{
  programs._1password-shell-plugins.plugins = [ gh ];
  programs.gh.package = gh;
}
