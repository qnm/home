{ pkgs, ... }:
let
  overlay = pkgs.writeShellApplication {
    name = "claude-overlay";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${./overlay/overlay-hook.py} "$HOME/Developer/qnm/skills/overlays"'';
  };
  hooks = [
    {
      type = "command";
      command = "${overlay}/bin/claude-overlay";
    }
  ];
in
{
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
