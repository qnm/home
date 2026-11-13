#!/usr/bin/env node
import { readFileSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

const PR_FETCH = "gh pr list --author @me --state all --limit 1000 --json number,state,headRefName,headRefOid > prs.json";
const here = dirname(fileURLToPath(import.meta.url));

function upstreamScript() {
  if (process.env.WORKTREE_AUDIT_UPSTREAM) return process.env.WORKTREE_AUDIT_UPSTREAM;
  const root = join(process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"), "plugins/cache/pstack-claude/pstack");
  const newest = readdirSync(root).sort((a, b) => a.localeCompare(b, undefined, { numeric: true })).at(-1);
  return join(root, newest, "skills/poteto-mode/scripts/worktree-audit.mjs");
}

function extendDisposable(disposable, lines) {
  const suffixes = lines.filter((line) => line.startsWith("*")).map((line) => line.slice(1));
  for (const line of lines.filter((line) => !line.startsWith("*"))) disposable.add(line);
  const exact = disposable.has.bind(disposable);
  disposable.has = (part) => exact(part) || suffixes.some((suffix) => part.endsWith(suffix));
}

export function distrustUniformChats(table, warn) {
  const [header, ...rows] = table.trimEnd().split("\n").map((line) => line.split("\t"));
  const chat = header.indexOf("LAST_CHAT");
  const bucket = header.indexOf("BUCKET");
  const live = rows.filter((row) => row[bucket] !== "prunable");
  const dates = new Set(live.map((row) => row[chat]));
  if (live.length < 3 || dates.size !== 1 || dates.has("-")) return table;
  warn(`warn: LAST_CHAT is ${[...dates][0]} on every row, so one chat named every worktree; the column is unknown. Get the in-use set from the user.`);
  for (const row of live) {
    row[chat] = "?";
    if (row[bucket] === "safe" || row[bucket] === "verify-recent-chat") row[bucket] = "review";
  }
  return [header, ...rows].map((row) => `${row.join("\t")}\n`).join("");
}

async function main() {
  const { values, positionals } = parseArgs({ options: { prs: { type: "string" } }, allowPositionals: true });
  const upstream = await import(pathToFileURL(upstreamScript()).href);
  for (const name of ["audit", "DISPOSABLE", "defaultTranscriptRoots"]) {
    if (!(name in upstream)) throw new Error(`${upstreamScript()} no longer exports ${name}; update ${fileURLToPath(import.meta.url)}`);
  }
  const lines = readFileSync(join(here, "disposable.txt"), "utf8").split("\n").map((line) => line.trim()).filter(Boolean);
  extendDisposable(upstream.DISPOSABLE, lines);

  const [repo = process.cwd(), ...roots] = positionals;
  const warn = (line) =>
    console.error(line.includes("gh pr list failed") ? `${line}\nwarn: run \`${PR_FETCH}\` from the shell, then pass --prs prs.json` : line);
  const table = upstream.audit({
    repo,
    transcripts: roots.length ? roots : upstream.defaultTranscriptRoots(),
    warn,
    ...(values.prs ? { gh: () => readFileSync(values.prs, "utf8") } : {}),
  });
  process.stdout.write(distrustUniformChats(table, warn));
}

await main();
