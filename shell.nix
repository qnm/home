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

      export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig
    '';
  };

  programs.fish = {
    enable = true;

    plugins = [{
      name="foreign-env";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "plugin-foreign-env";
        rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
        sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
      };
    }];

    shellInit =
      ''
        # nix
        if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            fenv source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        end

        # >>> conda initialize >>>
        # !! Contents within this block are managed by 'conda init' !!
        if test -f /opt/homebrew/Caskroom/miniconda/base/bin/conda
            eval /opt/homebrew/Caskroom/miniconda/base/bin/conda "shell.fish" "hook" $argv | source
        else
            if test -f "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
                . "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
            else
                set -x PATH "/opt/homebrew/Caskroom/miniconda/base/bin" $PATH
            end
        end
        # <<< conda initialize <<<

        set -x PKG_CONFIG_PATH "${pkgs.openssl.dev}/lib/pkgconfig" $PKG_CONFIG_PATH
        set -x PATH "$HOME/.cargo/bin/" $PATH
      '';
  };
}
