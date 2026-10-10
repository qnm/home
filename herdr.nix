{ config, pkgs, ... }:
let
  # herdr-mirror ships no Nix packaging. Its herdr-plugin.toml carries a
  # [[build]] step that downloads a prebuilt binary, which is no use in a
  # read-only store, so we build from source and drop the result at the
  # relative path the manifest's commands name. herdr only runs [[build]] from
  # `herdr plugin install|link`; loading the registry never builds, so the
  # store copy is taken as-is.
  herdr-mirror = pkgs.rustPlatform.buildRustPackage rec {
    pname = "herdr-mirror";
    version = "0.4.0";

    src = pkgs.fetchFromGitHub {
      owner = "nikok6";
      repo = "herdr-mirror";
      rev = "v${version}";
      hash = "sha256-XfTUh4naeb5z+Gq+eGm5p0E4gAS8gWQJWaVy2Na6YH8=";
    };

    cargoHash = "sha256-sXHOIeyX/Skpk7J0+dWVCpspYOew+tbWxeaJnKpoRpw=";

    # unit tests only, and they exercise ssh/docker plumbing we can't reach in
    # the sandbox
    doCheck = false;

    # herdr runs manifest commands with the plugin root as cwd and resolves
    # `./target/release/herdr-mirror` against it, so the checkout has to live
    # in the store beside the binary.
    postInstall = ''
      cp -r . $out/plugin
      rm -rf $out/plugin/target
      mkdir -p $out/plugin/target/release
      ln -s $out/bin/herdr-mirror $out/plugin/target/release/herdr-mirror
    '';

    meta = {
      description = "Mirror a remote herdr server's workspaces and agents into the local sidebar";
      homepage = "https://github.com/nikok6/herdr-mirror";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.unix;
      mainProgram = "herdr-mirror";
    };
  };

  mirrorRoot = "${herdr-mirror}/plugin";

  awakeVersion = "0.2.2";

  awakeRoot = pkgs.fetchFromGitHub {
    owner = "susomejias";
    repo = "herdr-awake";
    rev = "71c90c3e7809732c1e44336632893a65306db0ef";
    hash = "sha256-OH17INV6IyGvaUMzf4rXIecBvLt7ot02BpzKMAkN/kg=";
  };

  sbxVersion = "0.1.0";

  sbxRoot = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr-sbx-plugin";
    version = sbxVersion;

    src = pkgs.fetchFromGitHub {
      owner = "dirien";
      repo = "herdr-sbx-plugin";
      rev = "v${sbxVersion}";
      hash = "sha256-kmWO0c6ahLWOd696fM+UtPfgONXjWs1XxYSH1dA8iIg=";
    };

    installPhase = ''
      cp -r . $out
      echo ${pkgs.nodejs}/bin/node > $out/bin/node-path
    '';
  };
in
{
  # herdr comes from the flake input's overlay (see `herdr` in flake.nix); the
  # flake ships no home-manager module, so its config is managed here.
  home.packages = [
    pkgs.herdr
    herdr-mirror
  ];

  # herdr's plugin registry. Only identity and paths go here: on every load
  # herdr re-reads herdr-plugin.toml from manifest_path and refreshes the
  # actions, events and panes it caches in this file, so listing them would
  # just be a copy that goes stale.
  xdg.configFile."herdr/plugins.json".text = builtins.toJSON [
    {
      plugin_id = "mirror";
      name = "Herdr Mirror";
      version = herdr-mirror.version;
      min_herdr_version = "0.7.2";
      manifest_path = "${mirrorRoot}/herdr-plugin.toml";
      plugin_root = mirrorRoot;
      enabled = true;
      source.kind = "local";
    }
    {
      plugin_id = "herdr.awake";
      name = "Herdr Awake";
      version = awakeVersion;
      min_herdr_version = "0.7.0";
      manifest_path = "${awakeRoot}/herdr-plugin.toml";
      plugin_root = "${awakeRoot}";
      enabled = true;
      source.kind = "local";
    }
    {
      plugin_id = "sbx.sandbox";
      name = "Docker Sandboxes (sbx)";
      version = sbxVersion;
      min_herdr_version = "0.9.0";
      manifest_path = "${sbxRoot}/herdr-plugin.toml";
      plugin_root = "${sbxRoot}";
      enabled = true;
      source.kind = "local";
    }
  ];

  # The plugin's keybindings reach the CLI through this fixed path. Left alone,
  # `herdr-mirror start` creates it pointing at a store path nothing holds a
  # root on; managing it here repoints it on each switch instead, and the
  # plugin never replaces a link that already resolves.
  home.file.".local/bin/herdr-mirror".source = "${herdr-mirror}/bin/herdr-mirror";

  programs.claude-code.settings.hooks.SessionStart = [
    {
      hooks = [
        {
          type = "command";
          command = "${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh session";
        }
      ];
    }
  ];

  # herdr rewrites config.toml itself (onboarding state, anything changed from
  # its UI), so the file lives in this repo and is symlinked out of the store —
  # a store path is read-only and every such write fails with EACCES.
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Developer/qnm/home/herdr/config.toml";
}
