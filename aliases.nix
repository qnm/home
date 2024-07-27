{ pkgs, misc, ... }: {
   home.shellAliases = {
    "fast.ai" = "docker run --gpus all -it --rm -p 8888:8888 -v .:/home/jovyan/work egineering/fastai:fastai-basic-dev-latest";
    "hm-switch" = "home-manager switch -b backup --flake . #qnm";
    };
}
