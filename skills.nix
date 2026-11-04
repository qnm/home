{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Every skill lives in ~/Developer/qnm/skills: hand-written ones at the top
  # level, upstreams vendored as git submodules under upstream/. That repo also
  # owns the manifest (skills.toml) and the local edits (overlays/), so adding,
  # removing or changing a skill is a change to one repo and never a rebuild.
  #
  # This module's whole job is to guarantee the repo is there and let
  # `skills-link` do the rest. ~/.claude/skills is written by the tool rather
  # than home.file, because a home.file set is fixed at eval time and the
  # manifest is deliberately not.
  #
  # Nothing is vendored here: this repository is public.
  repo = "${config.home.homeDirectory}/Developer/qnm/skills";

  claude = "${config.home.homeDirectory}/.claude/skills";

  skills-link = pkgs.writeShellApplication {
    name = "skills-link";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.python3
    ];
    text = ''
      repo=${lib.escapeShellArg repo}
      claude=${lib.escapeShellArg claude}
      manifest="$repo/skills.toml"

      # Rows are read from the manifest at run time, never baked in.
      #   sources: <source> <submodule-or-.>
      #   skills:  <source> <install-name> <dir-relative-to-source>
      rows() {
        python3 - "$manifest" "$1" <<'PY'
      import sys, tomllib
      manifest, what = sys.argv[1], sys.argv[2]
      with open(manifest, "rb") as fh:
          data = tomllib.load(fh)
      out = []
      for source, body in data.items():
          sub = body.get("submodule", ".")
          if what == "sources":
              out.append(f"{source} {sub}")
              continue
          for key, value in body.items():
              if key in ("submodule", "renamed"):
                  continue
              for name in value:
                  out.append(f"{source} {name} {key + '/' + name if key else name}")
          for name, path in body.get("renamed", {}).items():
              out.append(f"{source} {name} {path}")
      try:
          print("\n".join(out))
      except BrokenPipeError:
          pass
      PY
      }

      # Read once: these are consulted inside loops, and a python start per
      # lookup is the difference between instant and a visible pause.
      SOURCE_ROWS=$(rows sources)
      SKILL_ROWS=$(rows skills)

      sources() { printf '%s\n' "$SOURCE_ROWS"; }
      skills() { printf '%s\n' "$SKILL_ROWS"; }

      root_of() {
        local sub
        sub=$(sources | awk -v s="$1" '$1 == s { print $2 }')
        if [ -z "$sub" ]; then
          echo "skills-link: no source named $1 in the manifest" >&2
          return 1
        fi
        if [ "$sub" = "." ]; then echo "$repo"; else echo "$repo/$sub"; fi
      }

      vendored() { sources | awk '$2 != "." { print $1, $2 }'; }

      # ~/.claude/skills is ours: every link in it points into the repo. One
      # that no longer has a manifest row is a skill that was removed.
      link() {
        local failed=0 source name dir target existing want
        mkdir -p "$claude"
        want=$(mktemp)
        while read -r source name dir; do
          [ -n "$name" ] || continue
          printf '%s\n' "$name" >> "$want"
          local root
          if ! root=$(root_of "$source"); then
            failed=1
            continue
          fi
          target="$root/$dir"
          if [ ! -d "$target" ]; then
            echo "skills-link: $name has no directory at $target"
            failed=1
            continue
          fi
          ln -sfn "$target" "$claude/$name"
        done < <(skills)

        if [ "$(sort "$want" | uniq -d | wc -l | tr -d ' ')" != 0 ]; then
          echo "skills-link: two sources claim $(sort "$want" | uniq -d | tr '\n' ' ')"
          failed=1
        fi

        for existing in "$claude"/*; do
          [ -L "$existing" ] || continue
          name=$(basename "$existing")
          case "$(readlink "$existing")" in "$repo"/*) ;; *) continue ;; esac
          if ! grep -qxF "$name" "$want"; then
            rm -f "$existing"
            echo "skills-link: $name is no longer in the manifest, unlinked"
          fi
        done
        rm -f "$want"
        return "$failed"
      }

      status() {
        local name submodule tree changed linked dangling
        while read -r name submodule; do
          [ -n "$name" ] || continue
          tree="$repo/$submodule"
          if [ ! -e "$tree/.git" ]; then
            echo "$name: not checked out"
            continue
          fi
          changed=$(git -C "$tree" status --porcelain | wc -l | tr -d ' ')
          if [ "$changed" = 0 ]; then
            echo "$name: pristine at $(git -C "$tree" rev-parse --short HEAD)"
          else
            echo "$name: $changed file(s) edited in place; move them to overlays/ and check out the submodule"
            git -C "$tree" status --short | sed 's/^/  /'
          fi
        done < <(vendored)

        linked=$(skills | wc -l | tr -d ' ')
        dangling=0
        for existing in "$claude"/*; do
          [ -L "$existing" ] && [ ! -e "$existing" ] && dangling=$((dangling + 1))
        done
        echo "links: $linked in the manifest, $dangling dangling"
      }

      case "''${1:-status}" in
        link) link ;;
        status) status ;;
        *)
          echo "usage: skills-link [link|status]" >&2
          exit 2
          ;;
      esac
    '';
  };

  gitBin = "${pkgs.git}/bin/git";
in
{
  home.packages = [ skills-link ];

  # pi discovers skills from a directory at run time, so it needs no eval-time
  # list and stays in step without a rebuild.
  programs.pi.coding-agent.settings.skills = [ claude ];

  # Runs after linkGeneration, because ~/.claude/skills is no longer a
  # home.file set: linking earlier would have this generation's links removed
  # as the previous generation's are cleaned up. A repo that cannot be fetched
  # warns rather than failing the whole activation.
  home.activation.skills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -d ${lib.escapeShellArg repo}/.git ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname ${lib.escapeShellArg repo})"
      $DRY_RUN_CMD ${gitBin} clone --quiet --recurse-submodules \
        https://github.com/qnm/skills ${lib.escapeShellArg repo} \
        || echo "skills: cannot clone qnm/skills, ~/.claude/skills will be empty"
    fi

    if [ -d ${lib.escapeShellArg repo}/.git ]; then
      $DRY_RUN_CMD ${gitBin} -C ${lib.escapeShellArg repo} submodule update --init --quiet \
        || echo "skills: cannot update submodules"
      $DRY_RUN_CMD ${gitBin} -C ${lib.escapeShellArg repo} config core.hooksPath .githooks
      $DRY_RUN_CMD ${skills-link}/bin/skills-link link \
        || echo "skills: some skills could not be linked, run 'skills-link status'"
    fi
  '';
}
