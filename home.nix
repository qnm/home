{ pkgs, lib, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  unsupported = builtins.abort "Unsupported Platform";
in
{
  imports = [
    # ./1password.nix
    ./work.nix
    ./path.nix
    ./shell.nix
    ./user.nix
    ./aliases.nix
    ./programs.nix
    ./claude-code.nix
    ./herdr.nix
    ./openwhispr.nix
  ];

  # Single source of truth for theming; per-program modules follow this flavor.
  # Opt individual programs out with `catppuccin.<program>.enable = false;`.
  catppuccin = {
    enable = true;
    flavor = "mocha";
    # upstream still targets `programs.gemini-cli`, renamed to
    # `programs.antigravity-cli` in home-manager 26.05; we use neither
    gemini-cli.enable = false;
  };

  programs.pi.coding-agent.enable = true;
  programs.pi.coding-agent.settings.shellPath = "${pkgs.fish}/bin/fish";
  programs.pi.coding-agent.settings.defaultProvider = "deepinfra";
  programs.pi.coding-agent.settings.defaultModel = "moonshotai/Kimi-K2.7-Code";
  programs.pi.coding-agent.settings.packages = [
    # shared
    "npm:pi-lsp"
    "npm:@narumitw/pi-lsp"
    "npm:@narumitw/pi-github-pr"
    "npm:pi-deepinfra"
    # work
    "npm:pi-linear"
  ];
  programs.pi.catppuccin.enable = true;

  home.username = "qnm";
  home.homeDirectory =
    if isLinux then
      "/home/qnm"
    else if isDarwin then
      "/Users/qnm"
    else
      unsupported;

  systemd.user.services = lib.mkIf isLinux {
    cosmic-display = {
      Unit.Description = "Set cosmic display settings";
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "oneshot";
        ExecStart = "/usr/bin/cosmic-randr mode DP-3 3440 1440 --refresh 144 --adaptive-sync true";
      };
    };
  };

  xdg.configFile."cosmic/com.system76.CosmicComp/v1/xkb_config".text = ''
    (
      rules: "",
      model: "pc105",
      layout: "us",
      variant: "",
      options: Some("ctrl:nocaps"),
      repeat_delay: 600,
      repeat_rate: 25,
    )
  '';

  xdg.configFile."cosmic/com.system76.CosmicComp/v1/input_config".text = ''
    (
      state: Enabled,
      acceleration: Some((
        profile: None,
        speed: -0.3291627775420733,
      )),
      scroll_config: Some((
        method: None,
        natural_scroll: Some(true),
        scroll_button: None,
        scroll_factor: None,
      )),
    )
  '';

  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages =
    with pkgs;
    (
      [
        nixd
        nil
        nixfmt
        cargo
        pkg-config
        openssl
        devenv
        shadowenv
        curl
        unzip
        # yadm
        jq
        wget
        gnupg
        devbox
        curl
        unzip
        tmux
        localsend
        hurl
        discord
        nodejs_22
        ngrok
        yt-dlp
        libffi
        htop
        glab
        fzf
        just
        kitty-themes
        nix-search-cli
        ast-grep
        codespelunker
        spr
        pkgs.gh-stack
        qmd
        uv
        # herdr is installed by ./herdr.nix alongside its config
        # Migrated from Homebrew
        redis
        postgresql_14
      ]
      ++ lib.optionals isLinux [
        # GNU/Linux packages
      ]
      ++ lib.optionals isDarwin [
        # macOS packages
        cocoapods
        colima
        docker
        docker-compose
        docker-buildx
        monitorcontrol
      ]
    );

  home.sessionVariables = lib.mkIf isDarwin {
    DOCKER_HOST = "unix://$HOME/.colima/default/docker.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    NODE_OPTIONS = "--dns-result-order=ipv4first";
  };

  fonts.fontconfig.enable = true;
  home.stateVersion = "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;

  # Darwin-specific settings - link apps instead of copying
  targets.darwin.linkApps.enable = lib.mkIf isDarwin true;
}
