{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.# zsh
  programs.zsh.profileExtra = ''
    [ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh
    export XCURSOR_PATH=$XCURSOR_PATH:/usr/share/icons:~/.local/share/icons:~/.icons:~/.nix-profile/share/icons
  '';
  programs.zsh.enableCompletion = true;
  programs.zsh.enable = true;

  # hack for brew
  # https://discourse.nixos.org/t/brew-not-on-path-on-m1-mac/26770/3
  #
  # hack for conda
  # copied from `conda init zsh`
  programs.zsh = {
    initExtra = ''
      if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # >>> conda initialize >>>
      # !! Contents within this block are managed by 'conda init' !!
      __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
      if [ $? -eq 0 ]; then
          eval "$__conda_setup"
      else
          if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
              . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
          else
              export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
          fi
      fi
      unset __conda_setup
      # <<< conda initialize <<<
    '';
  };
}
