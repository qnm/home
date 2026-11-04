{
  config,
  lib,
  pkgs,
  ...
}:
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
  herdr-reviewr = pkgs.rustPlatformUnstable.buildRustPackage rec {
    pname = "herdr-reviewr";
    version = "0.49.0";

    src = pkgs.fetchFromGitHub {
      owner = "persiyanov";
      repo = "herdr-reviewr";
      rev = "v${version}";
      hash = "sha256-Ko3q1ATlR7Gm4hknFV8N174oOZiPpRZfJp/zDW+UdvY=";
    };

    cargoHash = "sha256-s4H2RwDqe+b2OP5QuFa25kH27RT5x4ydXiFlHpgmWDQ=";

    doCheck = false;

    postInstall = ''
      cp -r . $out/plugin
      rm -rf $out/plugin/target
      mkdir -p $out/plugin/bin
      ln -s $out/bin/herdr-reviewr $out/plugin/bin/herdr-reviewr
    '';

    meta = {
      description = "Review agent-written diffs beside the chat and add line comments to the agent input";
      homepage = "https://github.com/persiyanov/herdr-reviewr";
      license = pkgs.lib.licenses.mit;
      platforms = pkgs.lib.platforms.unix;
      mainProgram = "herdr-reviewr";
    };
  };

  reviewrRoot = "${herdr-reviewr}/plugin";

  herdrLinear = pkgs.fetchFromGitHub {
    owner = "dantech99";
    repo = "herdr-linear";
    rev = "3f0232604a3fe2aa165de4e8fefe578825416f9d";
    hash = "sha256-vJyDGQISPedqHCazzJNs19OlHus2Jf+HfR4vt2yCo7Y=";
  };

  herdrAutomations = pkgs.fetchFromGitHub {
    owner = "DnzzL";
    repo = "herdr-automations";
    rev = "983aec905a49e678d8694a9ca70de77ea3f728c5";
    hash = "sha256-g/vHHbZpMoVgk7s+QXY/6v1iC8R7f87zIYb/gwxbKKk=";
  };

  appMods = {
    linear = {
      root = "${herdrLinear}/mods/linear";
      files = [
        "main.js"
        "mod.json"
        "linear.js"
        "open.js"
        "urls.js"
        "linear.svg"
      ];
    };
    linear-agent = {
      root = "${herdrLinear}/mods/linear-agent";
      files = [
        "main.js"
        "mod.json"
        "agents.js"
        "task.js"
      ];
    };
    automations = {
      root = "${herdrAutomations}/app/mods/automations";
      files = [
        "main.js"
        "mod.json"
        "automations.svg"
      ];
    };
  };

  appModFiles = lib.concatMapAttrs (
    name: mod:
    lib.listToAttrs (
      map (file: {
        name = "herdr-app/mods/${name}/${file}";
        value = {
          source = "${mod.root}/${file}";
          force = true;
        };
      }) mod.files
    )
  ) appMods;
in
lib.mkMerge [
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
        plugin_id = "persiyanov.reviewr";
        name = "reviewr";
        version = herdr-reviewr.version;
        min_herdr_version = "0.9.3";
        manifest_path = "${reviewrRoot}/herdr-plugin.toml";
        plugin_root = reviewrRoot;
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

    xdg.configFile."herdr-app/keys.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Developer/qnm/home/herdr-app/keys.json";
      force = true;
    };
  }
  { xdg.configFile = appModFiles; }
]
