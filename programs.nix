{ pkgs, misc, ... }: {
    programs.direnv.enable = true; 
    programs.starship.enable = true;
    programs.dircolors.enable = true; 
    programs.git.enable = true; 
    programs.gh.enable = true; 
    programs.helix.enable = true; 
    programs.fish.enable = true;
    # programs.firefox.enabled = true;
}
