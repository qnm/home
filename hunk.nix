{ pkgs, ... }:
{
  home.packages = [ pkgs.hunk ];
  home.file.".config/rex/hunk".source = ./hunk;
}
