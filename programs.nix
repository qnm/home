{ ... }: {
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.dircolors.enable = true;
    programs.gh.enable = true;
    programs.wezterm = {
        enable = true;
        extraConfig = ''
            local wezterm = require 'wezterm';

            return {
                color_scheme = "Catppuccin Mocha";
                font = wezterm.font 'FiraCode Nerd Font';
                font_size = 13.0;
                keys = {
                    {
                        key = 'r',
                        mods = 'CMD|SHIFT',
                        action = wezterm.action.ReloadConfiguration,
                    },
                };
            }
        '';
    };

    programs.zed-editor = {
        enable = true;
        extensions = [ "swift" "nix" "xy-zed" "catppuccin" "sql" ];
        userKeymaps = with builtins; fromJSON ''
            [
                {
                    "context": "Workspace",
                    "bindings": {}
                },
                {
                    "context": "Editor",
                    "bindings": {
                        "ctrl-k": "copilot::Suggest",
                        "ctrl-shift-k": "copilot::NextSuggestion",
                        "ctrl-j": "editor::AcceptInlineCompletion"
                    }
                }
            ]
        '';

        userSettings = with builtins; fromJSON ''
            {
                "editor.codeActionsOnSave": {
                    "source.fixAll.eslint": true
                },
                "features": {
                    "inline_completion_provider": "copilot"
                },
                "assistant": {
                        "default_model": {
                        "provider": "ollama",
                        "model": "llama3.2:1b-instruct-q5_0"
                    },
                    "version": "2"
                },
                "jupyter.enabled": true,
                "vim_mode": true,
                "ui_font_size": 16,
                "buffer_font_size": 16,
                "theme": {
                    "mode": "system",
                    "light": "One Light",
                    "dark": "Catppuccin Mocha"
                },
                "language_models": {
                    "ollama": {
                        "api_url": "http://localhost:11434"
                    }
                },
                "terminal": {
                    "font_family": "Menlo"
                },
                "lsp": {
                    "vtsls": {
                        "settings": {
                            "typescript": {
                                "preferences": {
                                    "importModuleSpecifier": "relative"
                                }
                            }
                        }
                    }
                }
            }
        '';
    };
}
