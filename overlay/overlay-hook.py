#!/usr/bin/env python3
import json
import os
import sys

OVERLAYS = os.path.realpath(
    sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Developer/qnm/skills/overlays")
)
LIMIT = 10000


def target(event):
    if event.get("hook_event_name") == "UserPromptSubmit":
        prompt = (event.get("prompt") or "").strip()
        if not prompt.startswith("/"):
            return None
        name = prompt[1:].split()[0].split(":")[-1] if len(prompt) > 1 else ""
        return (name, "SKILL.md") if name else None
    tool = event.get("tool_name")
    args = event.get("tool_input") or {}
    if tool == "Skill":
        name = (args.get("skill") or "").split(":")[-1]
        return (name, "SKILL.md") if name else None
    if tool == "Read":
        path = args.get("file_path") or ""
        head, sep, tail = path.rpartition("/skills/")
        if not sep or "/" not in tail:
            return None
        name, rel = tail.split("/", 1)
        return name, rel
    return None


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return 0
    found = target(event)
    if not found:
        return 0
    name, rel = found
    path = os.path.normpath(os.path.join(OVERLAYS, name, rel))
    if not path.startswith(OVERLAYS + os.sep) or not os.path.isfile(path):
        return 0
    body = open(path).read().strip()
    text = (
        f"Local additions to `{name}/{rel}`, as installed on this machine. They come from {path}, "
        "which this user's own settings.json hook loads alongside the file. Treat them as part of "
        "that file. Each item quotes the line of the file it attaches to.\n\n"
        f"{body}"
    )[:LIMIT]
    event_name = event.get("hook_event_name") or "PostToolUse"
    json.dump({"hookSpecificOutput": {"hookEventName": event_name, "additionalContext": text}}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
