{ pkgs, ... }:
let
  pushgate = pkgs.writeShellApplication {
    name = "claude-pushgate";
    runtimeInputs = [
      pkgs.jq
      pkgs.gnugrep
    ];
    text = builtins.readFile ./pushgate/pushgate.sh;
  };
  hook = [
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          command = "${pushgate}/bin/claude-pushgate";
        }
      ];
    }
  ];
in
{
  programs.claude-code.settings.hooks = {
    PreToolUse = hook;
    PostToolUseFailure = hook;
    PermissionDenied = hook;
  };
}
