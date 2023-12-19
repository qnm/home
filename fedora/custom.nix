{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  programs.bash = {
    enable = true;
    profileExtra = ''
      export XDG_DATA_DIRS=$HOME/.home-manager-share:$XDG_DATA_DIRS;
      export DOCKER_HOST = unix://$XDG_RUNTIME_DIR/podman/podman.sock;
    '';
  };
}
