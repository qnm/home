{ pkgs, misc, lib, ... }:
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

with lib.hm.gvariant;

{
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 
  fonts.fontconfig.enable = true;

  home.packages = [
    # user selected packages
    pkgs.gnomeExtensions.pop-shell
    pkgs.gnome-extension-manager
  ];

  dconf.settings = {
    "com/system76/hidpi" = {
      enable = true;
      mode = "hidpi";
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri-dark = "file:///usr/share/backgrounds/pop/ferdinand-stohr-149422.jpg";
      primary-color = "#000000";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/input-sources" = {
      current = mkUint32 0;
      per-window = false;
      sources = [ (mkTuple [ "xkb" "au" ]) ];
      xkb-options = [ "ctrl:nocaps" ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-antialiasing = "rgba";
      font-hinting = "slight";
      gtk-theme = "Adwaita";
      cursor-theme = "Adwaita";
      icon-theme = "Adwaita";
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = true;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/privacy" = {
      report-technical-problems = false;
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///usr/share/backgrounds/pop/ferdinand-stohr-149422.jpg";
      primary-color = "#000000";
      secondary-color = "#000000";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [ "pop-cosmic@system76.com" "pop-shell@system76.com" "system76-power@system76.com" "ubuntu-appindicators@ubuntu.com" "cosmic-dock@system76.com" "cosmic-workspaces@system76.com" "caffeine@patapon.info" "appindicatorsupport@rgcjonas.gmail.com" "user-theme@gnome-shell-extensions.gcampax.github.com" "openweather-extension@jenslody.de" "nano-system-monitor@eeeeeio" "ding@rastersoft.com" "Vitals@CoreCoding.com" ];
      favorite-apps = [ "pop-cosmic-launcher.desktop" "pop-cosmic-workspaces.desktop" "pop-cosmic-applications.desktop" "org.gnome.Epiphany.desktop" "org.mozilla.firefox.desktop" "com.mastermindzh.tidal-hifi.desktop" "hu.irl.cameractrls.desktop" "md.obsidian.Obsidian.desktop" "code.desktop" "com.onepassword.OnePassword.desktop" "org.signal.Signal.desktop" "org.gnome.Terminal.desktop" "org.gnome.Nautilus.desktop" "io.elementary.appcenter.desktop" "gnome-control-center.desktop" "de.haeckerfelix.Shortwave.desktop" "org.gnome.Fractal.desktop" ];
      welcome-dialog-last-shown-version = "42.0";
    };

    "org/gnome/shell/extensions/caffeine" = {
      user-enabled = false;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false;
      extend-height = false;
      intellihide = true;
      manualhide = false;
    };

    "org/gnome/shell/extensions/pop-shell" = {
      active-hint = false;
      gap-inner = mkUint32 1;
      gap-outer = mkUint32 1;
      tile-by-default = false;
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Catppuccin-Frappe-Standard-Rosewater-dark";
    };

    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
    };

    "org/gnome/terminal/legacy/profiles:" = {
      default = "95894cfd-82f7-430d-af6e-84d168bc34f5";
      list = [ "de8a9081-8352-4ce4-9519-5de655ad9361" "71a9971e-e829-43a9-9b2f-4565c855d664" "5083e06b-024e-46be-9cd2-892b814f1fc8" "95894cfd-82f7-430d-af6e-84d168bc34f5" ];
    };

    "org/gnome/terminal/legacy/profiles:/:5083e06b-024e-46be-9cd2-892b814f1fc8" = {
      background-color = "#24273a";
      cursor-background-color = "#f4dbd6";
      cursor-colors-set = true;
      cursor-foreground-color = "#24273a";
      foreground-color = "#cad3f5";
      highlight-background-color = "#24273a";
      highlight-colors-set = true;
      highlight-foreground-color = "#5b6078";
      palette = [ "#494d64" "#ed8796" "#a6da95" "#eed49f" "#8aadf4" "#f5bde6" "#8bd5ca" "#b8c0e0" "#5b6078" "#ed8796" "#a6da95" "#eed49f" "#8aadf4" "#f5bde6" "#8bd5ca" "#a5adcb" ];
      use-theme-colors = false;
      visible-name = "Catppuccin Macchiato";
    };

    "org/gnome/terminal/legacy/profiles:/:71a9971e-e829-43a9-9b2f-4565c855d664" = {
      background-color = "#303446";
      cursor-background-color = "#f2d5cf";
      cursor-colors-set = true;
      cursor-foreground-color = "#303446";
      foreground-color = "#c6d0f5";
      highlight-background-color = "#303446";
      highlight-colors-set = true;
      highlight-foreground-color = "#626880";
      palette = [ "#51576d" "#e78284" "#a6d189" "#e5c890" "#8caaee" "#f4b8e4" "#81c8be" "#b5bfe2" "#626880" "#e78284" "#a6d189" "#e5c890" "#8caaee" "#f4b8e4" "#81c8be" "#a5adce" ];
      use-theme-colors = false;
      visible-name = "Catppuccin Frappe";
    };

    "org/gnome/terminal/legacy/profiles:/:95894cfd-82f7-430d-af6e-84d168bc34f5" = {
      background-color = "#1e1e2e";
      cursor-background-color = "#f5e0dc";
      cursor-colors-set = true;
      cursor-foreground-color = "#1e1e2e";
      foreground-color = "#cdd6f4";
      highlight-background-color = "#1e1e2e";
      highlight-colors-set = true;
      highlight-foreground-color = "#585b70";
      login-shell = true;
      palette = [ "#45475a" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#bac2de" "#585b70" "#f38ba8" "#a6e3a1" "#f9e2af" "#89b4fa" "#f5c2e7" "#94e2d5" "#a6adc8" ];
      use-theme-colors = false;
      visible-name = "Catppuccin Mocha";
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      background-color = "rgb(0,43,54)";
      cursor-colors-set = false;
      foreground-color = "rgb(131,148,150)";
      highlight-colors-set = false;
      login-shell = true;
      palette = [ "rgb(7,54,66)" "rgb(220,50,47)" "rgb(133,153,0)" "rgb(181,137,0)" "rgb(38,139,210)" "rgb(211,54,130)" "rgb(42,161,152)" "rgb(238,232,213)" "rgb(0,43,54)" "rgb(203,75,22)" "rgb(88,110,117)" "rgb(101,123,131)" "rgb(131,148,150)" "rgb(108,113,196)" "rgb(147,161,161)" "rgb(253,246,227)" ];
      use-theme-colors = false;
      use-theme-transparency = true;
    };

    "org/gnome/terminal/legacy/profiles:/:de8a9081-8352-4ce4-9519-5de655ad9361" = {
      background-color = "#eff1f5";
      cursor-background-color = "#dc8a78";
      cursor-colors-set = true;
      cursor-foreground-color = "#eff1f5";
      foreground-color = "#4c4f69";
      highlight-background-color = "#eff1f5";
      highlight-colors-set = true;
      highlight-foreground-color = "#acb0be";
      palette = [ "#5c5f77" "#d20f39" "#40a02b" "#df8e1d" "#1e66f5" "#ea76cb" "#179299" "#acb0be" "#6c6f85" "#d20f39" "#40a02b" "#df8e1d" "#1e66f5" "#ea76cb" "#179299" "#bcc0cc" ];
      use-theme-colors = false;
      visible-name = "Catppuccin Latte";
    };

    "org/gnome/tweaks" = {
      show-extensions-notice = false;
    };
  };
}
