# Omarchy-only host settings, imported by the `qnm@omarchy` entry in flake.nix.
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
}
