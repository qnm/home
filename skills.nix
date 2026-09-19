{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Every skill lives in ~/Developer/qnm/skills: hand-written ones at the top
  # level, upstreams vendored as git submodules under upstream/. That repo also
  # owns the manifest (skills.toml) and the local edits (patches/), so adding,
  # renaming or patching a skill is a change to one repo and never a rebuild.
  #
  # This module's whole job is to guarantee the repo is there and let
  # `skills-patch` do the rest. ~/.claude/skills is written by the tool rather
  # than home.file, because a home.file set is fixed at eval time and the
  # manifest is deliberately not.
  #
  # Nothing is vendored here: this repository is public.
  repo = "${config.home.homeDirectory}/Developer/qnm/skills";

  claude = "${config.home.homeDirectory}/.claude/skills";

  # `git diff` is unusable raw here: a global diff.external rewrites it into
  # something that is not a patch, silently and with a zero exit. Every read of
  # a diff goes through diff_of.
  skills-patch = pkgs.writeShellApplication {
    name = "skills-patch";
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
      patches="$repo/patches"
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
          echo "skills-patch: no source named $1 in the manifest" >&2
          return 1
        fi
        if [ "$sub" = "." ]; then echo "$repo"; else echo "$repo/$sub"; fi
      }

      vendored() { sources | awk '$2 != "." { print $1, $2 }'; }

      diff_of() { git -C "$1" -c diff.external= diff --no-ext-diff --binary -- "''${@:2}"; }

      changed_of() { git -C "$1" -c diff.external= diff --no-ext-diff --name-only; }

      dirs_of() { skills | awk -v s="$1" '$1 == s { print $3 }'; }

      # The tree is "as captured" when every skill's diff is byte for byte its
      # patch file, and nothing outside a skill has changed. That is the only
      # dirty state apply may safely rebuild from.
      as_captured() {
        local name=$1 tree=$2 rowsource skill dir path covered want have
        while read -r rowsource skill dir; do
          [ "$rowsource" = "$name" ] || continue
          want=""
          [ -e "$patches/$name/$skill.patch" ] && want=$(cat "$patches/$name/$skill.patch")
          have=$(diff_of "$tree" "$dir")
          [ "$want" = "$have" ] || return 1
        done < <(skills)

        while read -r path; do
          [ -n "$path" ] || continue
          covered=0
          for dir in $(dirs_of "$name"); do
            case "$path" in "$dir"/*) covered=1 ;; esac
          done
          [ "$covered" = 1 ] || return 1
        done < <(changed_of "$tree")
        return 0
      }

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
            echo "skills-patch: $name has no directory at $target"
            failed=1
            continue
          fi
          ln -sfn "$target" "$claude/$name"
        done < <(skills)

        if [ "$(sort "$want" | uniq -d | wc -l | tr -d ' ')" != 0 ]; then
          echo "skills-patch: two sources claim $(sort "$want" | uniq -d | tr '\n' ' ')"
          failed=1
        fi

        for existing in "$claude"/*; do
          [ -L "$existing" ] || continue
          name=$(basename "$existing")
          case "$(readlink "$existing")" in "$repo"/*) ;; *) continue ;; esac
          if ! grep -qxF "$name" "$want"; then
            rm -f "$existing"
            echo "skills-patch: $name is no longer in the manifest, unlinked"
          fi
        done
        rm -f "$want"
        return "$failed"
      }

      apply() {
        local failed=0 name submodule tree patch
        while read -r name submodule; do
          [ -n "$name" ] || continue
          tree="$repo/$submodule"

          if [ ! -e "$tree/.git" ]; then
            echo "skills-patch: $submodule is not checked out, run 'git -C $repo submodule update --init'"
            failed=1
            continue
          fi

          if [ -n "$(git -C "$tree" status --porcelain)" ]; then
            if ! as_captured "$name" "$tree"; then
              echo "skills-patch: $name has uncaptured edits, left as is (capture, or reset to discard)"
              continue
            fi
            git -C "$tree" checkout -- .
          fi

          for patch in "$patches/$name"/*.patch; do
            [ -e "$patch" ] || continue
            if ! git -C "$tree" apply -p1 "$patch"; then
              echo "skills-patch: $patch does not apply to $name"
              failed=1
            fi
          done
        done < <(vendored)
        return "$failed"
      }

      capture() {
        local failed=0 name submodule tree path covered dir rowsource skill out body stale base
        while read -r name submodule; do
          [ -n "$name" ] || continue
          tree="$repo/$submodule"
          [ -e "$tree/.git" ] || continue

          while read -r path; do
            [ -n "$path" ] || continue
            covered=0
            for dir in $(dirs_of "$name"); do
              case "$path" in "$dir"/*) covered=1 ;; esac
            done
            if [ "$covered" = 0 ]; then
              echo "skills-patch: $name edit outside any skill, not captured: $path"
              failed=1
            fi
          done < <(changed_of "$tree")

          mkdir -p "$patches/$name"
          while read -r rowsource skill dir; do
            [ "$rowsource" = "$name" ] || continue
            out="$patches/$name/$skill.patch"
            body=$(diff_of "$tree" "$dir")
            if [ -n "$body" ]; then
              printf '%s\n' "$body" > "$out"
              echo "skills-patch: captured $skill"
            elif [ -e "$out" ]; then
              rm -f "$out"
              echo "skills-patch: $skill matches upstream, dropped its patch"
            fi
          done < <(skills)

          for stale in "$patches/$name"/*.patch; do
            [ -e "$stale" ] || continue
            base=$(basename "$stale" .patch)
            if ! skills | awk -v s="$name" -v k="$base" '$1 == s && $2 == k { f = 1 } END { exit !f }'; then
              rm -f "$stale"
              echo "skills-patch: $base is not a skill of $name, dropped its patch"
            fi
          done
        done < <(vendored)
        return "$failed"
      }

      reset() {
        local name submodule tree
        while read -r name submodule; do
          [ -n "$name" ] || continue
          tree="$repo/$submodule"
          [ -e "$tree/.git" ] || continue
          if [ -n "$(git -C "$tree" status --porcelain)" ]; then
            git -C "$tree" checkout -- .
            git -C "$tree" clean -qfd
            echo "skills-patch: $name back to pristine"
          fi
        done < <(vendored)
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
          elif as_captured "$name" "$tree"; then
            echo "$name: $changed file(s) changed, all captured"
          else
            echo "$name: $changed file(s) changed, NOT captured"
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
        apply) apply ;;
        capture) capture ;;
        reset) reset ;;
        status) status ;;
        *)
          echo "usage: skills-patch [link|apply|capture|reset|status]" >&2
          exit 2
          ;;
      esac
    '';
  };

  gitBin = "${pkgs.git}/bin/git";
in
{
  home.packages = [ skills-patch ];

  # pi discovers skills from a directory at run time, so it needs no eval-time
  # list and stays in step without a rebuild.
  programs.pi.coding-agent.settings.skills = [ claude ];

  # Runs after linkGeneration, because ~/.claude/skills is no longer a
  # home.file set: linking earlier would have this generation's links removed
  # as the previous generation's are cleaned up. A repo that cannot be fetched
  # warns rather than failing the whole activation, and local edits are never
  # discarded: `apply` reports an uncaptured tree and moves on.
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
      $DRY_RUN_CMD ${skills-patch}/bin/skills-patch apply \
        || echo "skills: some patches did not apply, run 'skills-patch status'"
      $DRY_RUN_CMD ${skills-patch}/bin/skills-patch link \
        || echo "skills: some skills could not be linked, run 'skills-patch status'"
    fi
  '';
}
