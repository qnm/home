#!/usr/bin/env bash
# Make the binary caches this config relies on available to Nix system-wide:
#
#   cache.numtide.com        prebuilt claude-code / wrap-buddy (llm-agents-nix)
#   pi.cachix.org            prebuilt pi packages
#   nix-community.cachix.org bun2nix's Bun toolchain (used by pi)
#
# None are in cache.nixos.org. Without them those packages build from source,
# which needs codeload.github.com and fails whenever that is unreachable.
#
# The macOS equivalent is the `/etc/nix/nix.custom.conf` entry in
# darwin/base.nix. This script is for the standalone home-manager path
# (Linux, non-NixOS) documented in README.md.
#
# Nix silently ignores a substituter configured by an untrusted user, so this
# has to run as root. It is idempotent - safe to re-run.
set -euo pipefail

readonly MARK_BEGIN="# >>> home: nix binary caches >>>"
readonly MARK_END="# <<< home: nix binary caches <<<"

readonly SUBSTITUTERS="https://cache.numtide.com https://pi.cachix.org https://nix-community.cachix.org"
readonly PUBLIC_KEYS="niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

if [[ ${EUID} -ne 0 ]]; then
  echo "error: must run as root (try: sudo $0)" >&2
  exit 1
fi

# Determinate Nix rewrites /etc/nix/nix.conf, so its settings live in
# nix.custom.conf (which nix.conf includes). Prefer that file when it exists.
if [[ -e /etc/nix/nix.custom.conf ]] || grep -qs 'nix\.custom\.conf' /etc/nix/nix.conf 2>/dev/null; then
  conf=/etc/nix/nix.custom.conf
  mkdir -p "$(dirname "$conf")"
else
  conf=/etc/nix/nix.conf
fi
touch "$conf"

# Replace anything this script (or an earlier, unmanaged run) previously wrote:
# the marked block, plus bare extra-substituters / extra-trusted-public-keys
# lines. Other settings are preserved.
tmp=$(mktemp)
awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
  $0 == b { skip = 1; next }
  $0 == e { skip = 0; next }
  skip { next }
  /^extra-substituters =/ { next }
  /^extra-trusted-public-keys =/ { next }
  { print }
' "$conf" >"$tmp"
cat >>"$tmp" <<EOF
$MARK_BEGIN
extra-substituters = $SUBSTITUTERS
extra-trusted-public-keys = $PUBLIC_KEYS
$MARK_END
EOF
mv "$tmp" "$conf"
# mktemp creates 0600; nix.conf must stay world-readable or non-root Nix
# silently reads no config at all.
chmod 0644 "$conf"
echo "wrote binary caches to $conf"

# Reload the daemon so it picks up the new config. Prefer the socket unit when
# the host uses socket activation.
restarted=
for unit in nix-daemon.socket nix-daemon.service; do
  if systemctl list-unit-files "$unit" >/dev/null 2>&1; then
    systemctl restart "$unit" 2>/dev/null && restarted="$restarted $unit"
  fi
done
if [[ -n $restarted ]]; then
  echo "restarted:$restarted"
elif command -v launchctl >/dev/null 2>&1; then
  launchctl kickstart -k system/org.nixos.nix-daemon && echo "restarted nix-daemon"
fi

echo
echo "effective substituters:"
nix show-config 2>/dev/null | grep -iE '^(substituters|trusted-public-keys)' || true
