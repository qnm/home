{ config, pkgs, ... }: {
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      asvetliakov.vscode-neovim
      bbenoist.nix
      catppuccin.catppuccin-vsc
      esbenp.prettier-vscode
      mechatroner.rainbow-csv
      dbaeumer.vscode-eslint
      vscodevim.vim
      github.copilot
      esbenp.prettier-vscode
    ];

    userSettings = with builtins; fromJSON ''
    {
      "[sql]": {
        "editor.defaultFormatter": "dorzey.vscode-sqlfluff"
      },
      "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
      },
      "[typescriptreact]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
      },
      "editor.codeActionsOnSave": {
        "source.fixAll.eslint": "explicit"
      },
      "editor.formatOnSave": false,
      "editor.lineNumbers": "relative",
      "eslint.validate": [
        "javascript"
      ],
      "extensions.experimental.affinity": {
        "asvetliakov.vscode-neovim": 1
      },
      "git.autofetch": true,
      "sqlfluff.experimental.format.executeInTerminal": true,
      "sqlfluff.linter.run": "onSave",
      "terminal.integrated.inheritEnv": false,
      "typescript.tsdk": "./node_modules/typescript/lib",
      "typescript.enablePromptUseWorkspaceTsdk": true,
      "workbench.colorTheme": "Catppuccin Mocha",
      "vscode-neovim.neovimExecutablePaths.darwin": "/Users/qnm/.nix-profile/bin/nvim"
    }
    '';
  };

  home.packages = with pkgs; [
    deno
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    # nerd-fonts.fira-code
    # nerd-fonts.droid-sans-mono
    # llm
  ] ++ (lib.optionals pkgs.stdenv.isLinux [
      # linux only
      vscode
      dconf2nix
      flatpak
      # 1password-cli
      # 1password-gui
      # pkgs.gnome-tweaks
      # pkgs.gnome-keyring
      # pkgs.gnome-screenshot
      # pkgs.nautilus
      # gnome.gnome-shell-extensions
      # gnomeExtensions.appindicator
      # gnomeExtensions.pop-shell
      # gnomeExtensions.dash-to-dock
      # gnomeExtensions.caffeine
      # gnome-extension-manager
      # rocmPackages.rocminfo
      # rocmPackages.hipcc
      # tidal-hifi
      # shortwave
      # pkgs.signal-desktop
      # pkgs.ollama-cuda
      # (alpaca.override { ollama = ollama-cuda; } )
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
      coc-tsserver
      coc-json
    ];

    extraPackages = with pkgs; [ fzf ];
    extraPython3Packages = ps: [ /* python-language-server */ ];
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
