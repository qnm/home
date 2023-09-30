{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

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
}
