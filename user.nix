{ config, pkgs, misc, ... }: {
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      bbenoist.nix
      catppuccin.catppuccin-vsc
      esbenp.prettier-vscode
      mechatroner.rainbow-csv
    ];

    userSettings = {
      "workbench.colorTheme" = "Catppuccin Mocha";
      "editor.formatOnSave" = true;
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "extensions.experimental.affinity" = {
        "asvetliakov.vscode-neovim" = 1;
      };
      "git.autofetch" = true;
    };
  };

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    pkgs.vscode
    pkgs._1password
    pkgs._1password-gui
    pkgs.deno
    pkgs.llm
  ] ++ (lib.optionals pkgs.stdenv.isLinux [
      # linux only
      dconf2nix
      flatpak
      pkgs.gnome-tweaks
      pkgs.gnome-keyring
      pkgs.gnome-screenshot
      pkgs.nautilus
      gnome.gnome-shell-extensions
      # gnomeExtensions.appindicator
      # gnomeExtensions.pop-shell
      # gnomeExtensions.dash-to-dock
      # gnomeExtensions.caffeine
      gnome-extension-manager
      rocmPackages.rocminfo
      rocmPackages.hipcc
      tidal-hifi
      shortwave
      pkgs.signal-desktop
      pkgs.ollama-cuda
      (alpaca.override { ollama = ollama-cuda; } )
  ]);

  programs.gh = {
    enable = true;

    settings = {
      # Workaround for https://github.com/nix-community/home-manager/issues/4744
      version = 1;
    };
  };

  programs.bash = {
    enable = true;
    profileExtra = ''
      export XDG_DATA_DIRS=$HOME/.home-manager-share:$XDG_DATA_DIRS
    '';
  };

  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = ''
        rm -rf $HOME/.home-manager-share
        mkdir -p $HOME/.home-manager-share
        cp -Lr --no-preserve=mode,ownership ${config.home.homeDirectory}/.nix-profile/share/* $HOME/.home-manager-share
      '';
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_mocha";
      editor = {
        line-number = "relative";
        lsp.display-messages = true;
        cursorline = true;
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides = {
          render = true;
        };
      };
    };
    languages = {
      language = [
        {
          name = "ruby";
          config = {
            solargraph = {
              diagnostics = true;
              formatting = true;
            };
          };
        }
        {
          name = "tsx";
          formatter= {
            command = "cd $FILE_LOCATION && prettier";
            args = [
              "--config-precedence"
              "prefer-file"
              "--stdin-filepath"
              "file.tsx"
            ];
          };
        }
        {
          name = "javascript";
          formatter = {
            command = "prettier";
            args = [
              "--parser"
              "typescript"
            ];
          };
          auto-format = true;
        }
      ];
    };
    themes = {
      catpuccin_mocha_test = let
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
      in {
        "type" = yellow;
      };
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    extraConfig = ''
      set modeline
      set number " turn on line numbers

      " 80-col highlighting
      highlight OverLength ctermbg=red ctermfg=white guibg=#592929
      match OverLength /\%81v.\+/
      set colorcolumn=80

      " Identation
      set autoindent " Copy indent from current line when starting a new line
      set smarttab
      set tabstop=2 " Number of space og a <Tab> character
      set softtabstop=2
      set shiftwidth=2 " Number of spaces use by autoindent
      set expandtab " Pressing <Tab> puts spaces, and < and > for indenting uses psaces
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = ctrlp;
        config = ''
          let g:ctrlp_map = '<c-p>'
          let g:ctrlp_cmd = 'CtrlP'
          let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist)|(\.(swp|ico|git|svn))$'
        '';
      }
      {
        plugin = catppuccin-nvim;
        config = ''
          " theme
          syntax enable
          set background=dark
          colorscheme catppuccin-mocha
          set termguicolors
        '';
      }
      {
        plugin = coc-nvim;
        config = ''
          let g:coc_global_extensions = ['coc-solargraph']

          inoremap <silent><expr> <TAB>
                \ pumvisible() ? "\<C-n>" :
                \ <SID>check_back_space() ? "\<TAB>" :
                \ coc#refresh()
          inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

          function! s:check_back_space() abort
            let col = col('.') - 1
            return !col || getline('.')[col - 1]  =~# '\s'
          endfunction

          " Use <c-space> to trigger completion.
          if has('nvim')
            inoremap <silent><expr> <c-space> coc#refresh()
          else
            inoremap <silent><expr> <c-@> coc#refresh()
          endif

          " Follow definition
          nmap <silent> gd <Plug>(coc-definition)

        '';
      }
      lightline-vim
      coc-solargraph
      coc-tsserver
      coc-json
    ];

    extraPackages = with pkgs; [ fzf ];
    extraPython3Packages = ps: with ps; [ /* python-language-server */ ];
  };

  # gitconfig
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
          push = {
            autoSetupRemote = true;
          };
          core = {
            editor = "nvim";
            whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
          };
      };

      signing = {
          key = "";
          signByDefault = builtins.stringLength "" > 0;
      };

      lfs.enable = true;
      ignores = [ ".direnv" "result" ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      command_timeout = 1000;
      cmd_duration = {
        min_time = 5000;
        format = "took [$duration](bold yellow)";
      };
      git_metrics = {
        disabled = false;
      };
      time = {
        disabled = true;
        use_12hr = true;
        format = "[$time](bold yellow)";
      };
      directory = {
        read_only = " ";
        style = "bold blue";
      };
    };
  };
}
