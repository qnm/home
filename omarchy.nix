# Omarchy-only host settings, imported by the `qnm@omarchy` entry in flake.nix.
{ pkgs, ... }:

let
  # 1Password reference for the DeepInfra API key. `op item get <item> --format
  # json` prints the exact `op://vault/item/field` to paste here.
  deepinfraKeyRef = "op://Private/DeepInfra/password";
in
{
  # Desktop prefs carried over from the macOS setup (see darwin/base.nix):
  # caps lock as control, and content-following ("natural") scrolling.
  #
  # `hypr/input.lua` is Omarchy's user-override file: it is loaded after
  # Omarchy's defaults, so only the keys set here change. Taking the file over
  # replaces the commented template Omarchy ships; `omarchy refresh config
  # hypr/input.lua` restores that template, and the next `home-manager switch`
  # re-asserts this one.
  # pi's DeepInfra credential comes from 1Password at launch instead of a
  # `deepinfra` entry in ~/.pi/agent/auth.json: pi.nix sources this file with
  # `set -a` before exec'ing pi, so the store holds only the `op read` command,
  # never the key. pi-deepinfra prefers a stored auth.json credential and falls
  # back to DEEPINFRA_API_KEY, so this takes over once the stored key is gone.
  programs.pi.coding-agent.environment = pkgs.writeText "pi-env.sh" ''
    DEEPINFRA_API_KEY="$(op read '${deepinfraKeyRef}')"
  '';

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
