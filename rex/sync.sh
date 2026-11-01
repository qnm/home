#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

plist="$(mktemp)"
trap 'rm -f "$plist"' EXIT
/usr/bin/defaults export com.superlogical.rex "$plist"

python3 - "$dir" "$plist" <<'PY'
import json
import plistlib
import sys

dir = sys.argv[1]
with open(sys.argv[2], "rb") as f:
    live = plistlib.load(f)

defaults_path = f"{dir}/defaults.json"
with open(defaults_path) as f:
    tracked = json.load(f)

for key in tracked:
    if key in live:
        tracked[key] = live[key]
    else:
        print(f"missing in macOS defaults, kept: {key}")

with open(defaults_path, "w") as f:
    json.dump(tracked, f, indent=2)
    f.write("\n")

with open(f"{dir}/themes.json", "w") as f:
    json.dump(json.loads(live["Workspace.customThemes"]), f, indent=2)
    f.write("\n")

untracked = sorted(set(live) - set(tracked) - {"Workspace.customThemes"})
if untracked:
    print("untracked keys (add to defaults.json to sync):")
    for key in untracked:
        print(f"  {key}")
PY
