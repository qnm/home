#!/usr/bin/env python3
import glob
import json
import os
import re
import sys

LIMIT = 10000
ANCHOR = re.compile(r'^\s*(?:[-*]|\d+\.)\s+\*\*(?:After|Before|Replace|In)\*\*\s+"([^"]+)"')
HOME = os.path.expanduser("~")


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


def overlay(root, name, rel):
    path = os.path.normpath(os.path.join(root, name, rel))
    if path.startswith(root + os.sep) and os.path.isfile(path):
        return path
    return None


def inject(roots):
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return 0
    found = target(event)
    if not found:
        return 0
    name, rel = found
    parts = []
    for root in roots:
        path = overlay(root, name, rel)
        if path:
            parts.append(
                f"Local additions to `{name}/{rel}`, as installed on this machine. They come from {path}, "
                "which this user's own settings loads alongside the file. Treat them as part of that file. "
                "Each item quotes the line of the file it attaches to.\n\n" + open(path).read().strip()
            )
    if not parts:
        return 0
    text = "\n\n".join(parts)[:LIMIT]
    event_name = event.get("hook_event_name") or "PostToolUse"
    json.dump({"hookSpecificOutput": {"hookEventName": event_name, "additionalContext": text}}, sys.stdout)
    return 0


def version_key(path):
    return [int(p) if p.isdigit() else 0 for p in re.split(r"[.\-]", path.split("/")[-3])]


def installed(name):
    local = os.path.join(HOME, ".claude/skills", name)
    if os.path.isfile(os.path.join(local, "SKILL.md")):
        return local
    cached = glob.glob(os.path.join(HOME, ".claude/plugins/cache/*/*/*/skills", name))
    return max(cached, key=version_key) if cached else None


def flat(text):
    return re.sub(r"\s+", " ", text)


def check(roots):
    problems = []
    for root in roots:
        if not os.path.isdir(root):
            continue
        for name in sorted(os.listdir(root)):
            if not os.path.isdir(os.path.join(root, name)):
                continue
            base = installed(name)
            if not base:
                problems.append(f"{root}/{name}: no installed skill by that name")
                continue
            for dirpath, _, files in os.walk(os.path.join(root, name)):
                for f in files:
                    path = os.path.join(dirpath, f)
                    rel = os.path.relpath(path, os.path.join(root, name))
                    if len(open(path).read()) > LIMIT:
                        problems.append(f"{path}: over {LIMIT} characters")
                    upstream = os.path.join(base, rel)
                    if not os.path.isfile(upstream):
                        problems.append(f"{path}: {name} has no {rel}")
                        continue
                    text = flat(open(upstream).read())
                    for lineno, line in enumerate(open(path), 1):
                        m = ANCHOR.match(line)
                        if m and flat(m.group(1)) not in text:
                            problems.append(f'{path}:{lineno}: "{m.group(1)}" is not in {upstream}')
    for p in problems:
        print(p)
    return 1 if problems else 0


def main():
    args = sys.argv[1:]
    mode = check if args[:1] == ["--check"] else inject
    roots = [os.path.realpath(r) for r in (args[1:] if mode is check else args)]
    return mode(roots)


if __name__ == "__main__":
    sys.exit(main())
