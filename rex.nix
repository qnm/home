{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "com.superlogical.rex";
  rex = "${config.home.homeDirectory}/.local/bin/rex";
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults.${domain} = builtins.fromJSON (builtins.readFile ./rex/defaults.json);

  home.activation.rexThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write ${domain} Workspace.customThemes -data \
      "$(${pkgs.jq}/bin/jq -c . ${./rex/themes.json} | tr -d '\n' | /usr/bin/xxd -p | tr -d '\n')"
  '';

  home.activation.rexInit = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    cfg=${lib.escapeShellArg "${config.home.homeDirectory}/.config/rex/init.lua"}
    line='dofile("${./rex/init.lua}")'
    if [ -L "$cfg" ]; then
      run rm "$cfg"
    fi
    if [ -z "''${DRY_RUN:-}" ]; then
      mkdir -p "$(dirname "$cfg")"
      touch "$cfg"
      {
        printf '%s\n' "$line"
        ${pkgs.gnugrep}/bin/grep -v '^dofile("/nix/store/[^"]*")$' "$cfg" || true
      } > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    fi
  '';

  home.file.".local/bin/rex" = {
    source = config.lib.file.mkOutOfStoreSymlink "/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
    force = true;
  };

  home.activation.rexConfigReload = lib.hm.dag.entryAfter [ "rexInit" ] ''
    if ${lib.escapeShellArg rex} --autostart=false server status >/dev/null 2>&1; then
      run ${lib.escapeShellArg rex} --autostart=false config reload >/dev/null
    fi
  '';

  home.activation.rexSkill =
    lib.hm.dag.entryAfter
      [
        "claudeSettings"
        "skills"
      ]
      ''
        if [ -x ${lib.escapeShellArg rex} ]; then
          run ${lib.escapeShellArg rex} --autostart=false skill setup --agent claude --session-naming >/dev/null \
            || echo "rex: cannot install the Claude skill, run 'rex skill status'"
        fi
      '';
}
