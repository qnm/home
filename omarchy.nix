# Omarchy-only host settings, imported by the `qnm@omarchy` entry in flake.nix.
{ config, ... }:

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

  # pi's DeepInfra credential, read at launch from a 0600 file outside the
  # store. pi.nix exports `DEEPINFRA_API_KEY` from it before exec'ing pi, and
  # pi-deepinfra falls back to that when auth.json holds no stored credential.
  #
  # This is a file rather than `op read` because 1Password's CLI must share the
  # desktop app's systemd scope, and Omarchy's uwsm gives every app its own, so
  # `op` is rejected with "peer was not in the correct application group".
  # Refill the file by hand from 1Password when the key rotates; note the
  # `Deepinfra` item there is stale (its password is not a valid API token).
  programs.pi.coding-agent.environment = {
    DEEPINFRA_API_KEY.file = "${config.home.homeDirectory}/.config/pi/deepinfra.key";
  };
}
