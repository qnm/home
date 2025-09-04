{ ... }:
{
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  home.username = "qnm";
  home.homeDirectory = "/Users/qnm";
  programs.git = {
    enable = true;
    aliases = {
      pushall = "!git remote | xargs -L1 git push --all";
      graph = "log --decorate --oneline --graph";
      add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
    };
    userName = "Rob Sharp";
    userEmail = "rob@sharp.id.au";
    extraConfig = {
      feature.manyFiles = false;
      init.defaultBranch = "main";
      gpg.format = "ssh";
    };

    signing = {
      key = "";
      signByDefault = builtins.stringLength "" > 0;
    };

    lfs.enable = true;
    ignores = [
      ".direnv"
      "result"
    ];
  };

}
