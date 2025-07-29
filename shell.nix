{ pkgs, ... }: {
  programs._1password-shell-plugins = {
    # enable 1Password shell plugins for bash, zsh, and fish shell
    enable = true;
    # the specified packages as well as 1Password CLI will be
    # automatically installed and configured to use shell plugins
    plugins = with pkgs; [gh awscli2];
  };

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
    initContent = ''
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

    plugins = [
      {
        name="foreign-env";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-foreign-env";
          rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
          sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
        };
      }
      {
        name="fisher";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "fisher";
          rev = "1f0dc2b4970da160605638cb0f157079660d6e04";
          sha256 = "pR5RKU+zIb7CS0Y6vjx2QIZ8Iu/3ojRfAcAdjCOxl1U=";
        };
      }
      {
        name="nvm.fish";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "nvm.fish";
          rev = "a0892d0bb2304162d5faff561f030bb418cac34d";
          sha256 = "GTEkCm+OtxMS3zJI5gnFvvObkrpepq1349/LcEPQRDo=";
        };
      }
      {
        name="fish-nvm";
        src = pkgs.fetchFromGitHub {
          owner = "FabioAntunes";
          repo = "fish-nvm";
          rev = "57ddb124cc0b6ae7e2825855dd34f33b8492a35b";
          sha256 = "wB1p4MWKeNdfMaJlUwkG+bJmmEMRK+ntykgkSuDf6wE=";
        };
      }
    ];

    shellInit =
      ''
        if test -d /opt/homebrew
            # Homebrew is installed on MacOS
            /opt/homebrew/bin/brew shellenv | source
        end

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
                fish_add_path "/opt/homebrew/Caskroom/miniconda/base/bin"
            end
        end
        # <<< conda initialize <<<

        set -x PKG_CONFIG_PATH "${pkgs.openssl.dev}/lib/pkgconfig" $PKG_CONFIG_PATH

        # set up cargo
        fish_add_path "$HOME/.cargo/bin/"

        # set up direnv
        direnv hook fish | source
      '';
  };
}
