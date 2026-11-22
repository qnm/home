# Omarchy-only host settings, imported by the `qnm@omarchy` entry in flake.nix.
{ config, pkgs, ... }:

{
  # Desktop prefs carried over from the macOS setup (see darwin/base.nix):
  # caps lock as control, and content-following ("natural") scrolling.
  #
  # `hypr/input.lua` is Omarchy's user-override file: it is loaded after
  # Omarchy's defaults, so only the keys set here change. Taking the file over
  # replaces the commented template Omarchy ships; `omarchy refresh config
  # hypr/input.lua` restores that template, and the next `home-manager switch`
  # re-asserts this one.
  xdg.configFile."hypr/input.lua" = {
    force = true;
    text = ''
      hl.config({
        input = {
          -- caps lock -> control (macOS remapCapsLockToControl)
          kb_options = "ctrl:nocaps",

          -- scroll like content, not like a viewport
          -- (macOS unnaturalscrollwheels)
          natural_scroll = true,

          touchpad = {
            natural_scroll = true,
          },
        },
      })
    '';
  };

  # Omarchy declares pi in /etc/mise/conf.d/omarchy-tools.toml, so mise's shim
  # would shadow the home-manager wrapper above (and its env export). Disable
  # the mise copy: the shim then falls through to ~/.nix-profile/bin/pi.
  xdg.configFile."mise/config.toml" = {
    force = true;
    text = ''
      [settings]
      disable_tools = ["pi"]
    '';
  };

  # pi's DeepInfra credential, read at launch from a 0600 file outside the
  # store. pi.nix exports `DEEPINFRA_API_KEY` from it before exec'ing pi, and
  # pi-deepinfra falls back to that when auth.json holds no stored credential.
  #
  # `pi-deepinfra-key` refills the file from the `Deepinfra API` API-credential
  # item in 1Password. It cannot just call `op read`: 1Password's CLI must run
  # inside the desktop app's own systemd scope, and uwsm gives every app its
  # own, so the app answers "peer was not in the correct application group".
  # The script re-enters the app's cgroup via pkexec and reads the key there.
  programs.pi.coding-agent.environment = {
    DEEPINFRA_API_KEY.file = "${config.home.homeDirectory}/.config/pi/deepinfra.key";
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "pi-deepinfra-key";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        gnugrep
        gnused
      ];
      text = builtins.readFile ./bin/pi-deepinfra-key;
      # SC2016: the `$1`-style arguments inside the single-quoted pkexec payload
      # belong to the shell it spawns, not to this script.
      excludeShellChecks = [ "SC2016" ];
    })
  ];
}
