#!/usr/bin/env bash
set -euo pipefail

echo "==> Collecting nix garbage (older than 7 days)"
nix-collect-garbage --delete-older-than 7d

echo "==> Optimising nix store"
nix store optimise

echo "==> Done"
nix-store --gc --print-roots | head -20
