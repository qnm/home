{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
in
{
  # herdr comes from the flake input's overlay (see `herdr` in flake.nix); the
  # flake ships no home-manager module, so config.toml is generated here.
  home.packages = [ pkgs.herdr ];

  xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" {
    # herdr isn't covered by catppuccin/nix, so the flavor is set here rather
    # than following the global `catppuccin.flavor` in home.nix.
    theme = {
      name = "catppuccin";
      auto_switch = true;
      light_name = "catppuccin-latte";
      dark_name = "catppuccin";
    };

    ui = {
      show_agent_labels_on_pane_borders = true;

      # Put each agent's own session name in its sidebar row. The default rows
      # are [["state_icon", "workspace", "tab"], ["agent"]], so every pane in a
      # repo reads as the workspace label ("amber-core") — the session name is
      # carried in the terminal_title_stripped token, which the default layout
      # leaves out.
      sidebar.agents.rows = [
        [
          "state_icon"
          "workspace"
          "tab"
        ]
        [ "terminal_title_stripped" ]
        [ "agent" ]
      ];

      # Background notifications go to the macOS notifier rather than herdr's
      # own in-terminal toast, so `ui.toast.herdr.position` doesn't apply.
      toast = {
        delivery = "system";
        delay_seconds = 1;
      };
    };

    experimental = {
      kitty_graphics = true;
    };
  };
}
