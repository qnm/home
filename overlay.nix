{ pkgs, ... }:
let
  overlay = pkgs.writeShellApplication {
    name = "claude-overlay";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      root="$HOME/Developer/qnm/home/overlays"
      if [ "''${1:-}" = --check ]; then
        exec python3 ${./overlay/overlay-hook.py} --check "$root"
      fi
      exec python3 ${./overlay/overlay-hook.py} "$root"
    '';
  };
  hooks = [
    {
      type = "command";
      command = "${overlay}/bin/claude-overlay";
    }
  ];
in
{
  home.packages = [ overlay ];

  programs.claude-code.settings.hooks = {
    PostToolUse = [
      {
        matcher = "Skill|Read";
        inherit hooks;
      }
    ];
    UserPromptSubmit = [ { inherit hooks; } ];
  };
}
