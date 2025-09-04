{ ... }:
{
  # FEEL FREE TO EDIT: This file is NOT managed by fleek.

  programs.bash = {
    enable = true;
    profileExtra = ''
      export XDG_DATA_DIRS=$HOME/.home-manager-share:$XDG_DATA_DIRS;
    '';
  };
}
