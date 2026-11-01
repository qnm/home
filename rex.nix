{ pkgs, lib, ... }:
let
  domain = "com.superlogical.rex";
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults.${domain} = builtins.fromJSON (builtins.readFile ./rex/defaults.json);

  home.activation.rexThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write ${domain} Workspace.customThemes -data \
      "$(${pkgs.jq}/bin/jq -c . ${./rex/themes.json} | tr -d '\n' | /usr/bin/xxd -p | tr -d '\n')"
  '';
}
