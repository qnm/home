{ pkgs, misc, ... }: {
   home.shellAliases = {
    "fast.ai" = "docker run --gpus all -it --rm -p 8888:8888 -v .:/home/jovyan/work egineering/fastai:fastai-basic-dev-latest";
    "hm-switch" = "home-manager switch -b backup --flake . #qnm";
    # https://github.com/ollama/ollama/issues/2934
    "unload-nvidia" = "sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm";
    };
}
