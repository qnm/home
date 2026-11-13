# Working style

## Agent-friendly architecture

We assume many contributors arrive with a narrow prompt, a few nearby files, and no complete model. The framework makes the locally obvious change the globally correct change. Unsafe shortcuts fail with an error that names the supported owner or API.

This page defines the contributor context model and the architecture choices that keep repeated local edits from coupling the application.

## Contract

A coding agent usually optimizes for what fits in its context:

- copy the nearest working pattern;
- edit the file already open;
- choose the shortest path that compiles;
- avoid deleting code whose callers are not visible;
- follow the requested implementation even when it conflicts with a system invariant.

These behaviors are predictable inputs to the framework design. We follow five rules:

1. The conventional path requires fewer decisions than a shortcut.
2. Forbidden dependencies fail mechanically.
3. Every durable value has one obvious writer.
4. New product work adds isolated files rather than branches in shared roots.
5. Exceptions are narrow, explicit, and reviewed as architecture changes.

## Forbidden

1. Code Comments

## Guidelines

1. All copy (PR descriptions e.g.) should use extremely short and simple language
2. If my request rests on a misunderstanding, say so and correct it before you act, even if that means not doing what I asked.
3. Push back when you disagree. Don't go along quietly.
4. Never use cloud, remote or managed agents unless I sign it off. Local subagents are fine.
5. Before you update a PR description, read the current one. I may have edited it.

## Enforced rules

| Rule | Enforced by |
| --- | --- |
| A `!` command is at most 100 characters. Longer ones go in a script. | `handoffwrap` Stop hook |
| A `!` command never runs `sudo`. It goes to a terminal tab. | `handoffwrap` Stop hook |
| An `sbx` delete in a `!` command carries `--force`. | `handoffwrap` Stop hook |

@~/.claude/pstack-models.md
@~/Developer/qnm/skills/skill-routing.md
