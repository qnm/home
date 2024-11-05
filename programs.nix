{ pkgs, misc, ... }: {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.dircolors.enable = true;
    programs.gh.enable = true;
}
