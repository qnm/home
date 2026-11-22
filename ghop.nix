{ pkgs, lib, ... }:
let
  wrapper = pkgs.writeShellApplication {
    name = "gh";
    text = ''
      real_gh_dir=${pkgs.gh}/bin
    ''
    + builtins.readFile ./ghop/ghop.sh;
  };
  gh = pkgs.symlinkJoin {
    name = "gh-op-${pkgs.gh.version}";
    paths = [
      wrapper
      pkgs.gh
    ];
    meta.mainProgram = "gh";
  };
in
{
  programs._1password-shell-plugins.plugins = [ gh ];
  programs.gh.package = gh;

  # The "Integrate with 1Password CLI" toggle that the `gh-op` wrapper depends
  # on is GUI-only (and its value in settings.json is HMAC-signed, so it can't
  # be set from here). When it is off, `op plugin run` fails and git can no
  # longer get GitHub credentials. On Linux point the credential helper at the
  # real gh (which authenticates from gh's own keyring), the same escape hatch
  # `rotate-gh-token` uses. macOS keeps the 1Password wrapper.
  programs.git.settings.credential =
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkForce {
      "https://github.com" = {
        helper = [
          ""
          "${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
      "https://gist.github.com" = {
        helper = [
          ""
          "${pkgs.gh}/bin/gh auth git-credential"
        ];
      };
    });
}
