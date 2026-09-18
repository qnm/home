{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Skills are git checkouts under ~/Developer, one per upstream, pinned by
  # revision in ./skills-sources.nix. Each skill directory is symlinked into
  # ~/.claude/skills out-of-store, so edits are live without a rebuild, and the
  # checkout they point into keeps its own history.
  #
  # Nothing is vendored here: this repository is public, and the upstreams are
  # fetched at activation rather than republished.
  #
  # `programs.claude-code.skills` is deliberately not used: it links each skill
  # recursively, file by file, which defeats an out-of-store symlink.
  root = "${config.home.homeDirectory}/Developer";

  sources = import ./skills-sources.nix { inherit lib; };

  paths = lib.concatMapAttrs (
    _: source: lib.mapAttrs (_: dir: "${root}/${source.clone}/${dir}") source.skills
  ) sources;

  names = lib.concatMap (source: lib.attrNames source.skills) (lib.attrValues sources);

  collisions = lib.unique (lib.filter (name: lib.count (other: other == name) names > 1) names);

  git = "${pkgs.git}/bin/git";

  ensure =
    source:
    "ensureSkillSource ${lib.escapeShellArg source.url} ${lib.escapeShellArg "${root}/${source.clone}"} ${lib.escapeShellArg (toString source.rev)}";
in
{
  assertions = [
    {
      assertion = collisions == [ ];
      message = "skills-sources.nix: more than one source claims ${lib.concatStringsSep ", " collisions}";
    }
  ];

  home.file = lib.mapAttrs' (
    name: path:
    lib.nameValuePair ".claude/skills/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink path;
    }
  ) paths;

  # pi: list of skill dirs passed via repeated `--skill`.
  programs.pi.coding-agent.skills = lib.attrValues paths;

  # Runs after the write boundary and before linkGeneration, so the checkouts
  # exist by the time the symlinks into them are written. A source that cannot
  # be fetched warns and leaves its symlinks dangling rather than failing the
  # whole activation, and a checkout with local changes is never moved.
  home.activation.skillSources = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    ensureSkillSource() {
      local url="$1" dir="$2" rev="$3"

      if [ ! -d "$dir/.git" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$dir")"
        if ! $DRY_RUN_CMD ${git} clone --quiet "$url" "$dir"; then
          echo "skills: cannot clone $url, its skills will dangle in ~/.claude/skills"
          return
        fi
      fi

      if [ -z "$rev" ] || [ ! -d "$dir/.git" ]; then
        return
      fi

      if [ "$(${git} -C "$dir" rev-parse HEAD 2>/dev/null)" = "$rev" ]; then
        return
      fi

      if [ -n "$(${git} -C "$dir" status --porcelain)" ]; then
        echo "skills: $dir has local changes, leaving it where it is instead of moving to $rev"
        return
      fi

      if ! ${git} -C "$dir" cat-file -e "$rev^{commit}" 2>/dev/null; then
        $DRY_RUN_CMD ${git} -C "$dir" fetch --quiet origin
      fi

      $DRY_RUN_CMD ${git} -C "$dir" checkout --quiet --detach "$rev" \
        || echo "skills: cannot check out $rev in $dir"
    }

    ${lib.concatStringsSep "\n" (map ensure (lib.attrValues sources))}
  '';
}
