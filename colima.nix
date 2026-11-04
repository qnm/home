{ pkgs, lib, ... }:
let
  colimaNoSave = pkgs.writeShellApplication {
    name = "colima";
    text = ''
      if [ "''${1:-}" = start ]; then
        shift
        exec ${lib.getExe pkgs.colima} start --save-config=false "$@"
      fi
      exec ${lib.getExe pkgs.colima} "$@"
    '';
  };
  colima = pkgs.symlinkJoin {
    name = "colima";
    paths = [
      colimaNoSave
      pkgs.colima
    ];
    meta.mainProgram = "colima";
  };
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  services.colima = {
    enable = true;
    package = colima;
    profiles.default = {
      isActive = true;
      isService = false;
      settings = {
        cpu = 6;
        memory = 8;
        disk = 100;
        rootDisk = 20;
        arch = "aarch64";
        runtime = "docker";
        hostname = "colima";
        autoActivate = true;
        network.mode = "shared";
        vmType = "vz";
        portForwarder = "ssh";
        rosetta = true;
        binfmt = true;
        mountType = "virtiofs";
        mountInotify = true;
        sshConfig = true;
      };
    };
  };
}
