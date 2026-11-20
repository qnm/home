import { existsSync } from 'node:fs';
import { join } from 'node:path';

const SOURCE_FILE = /\.(?:ts|tsx|js|jsx|mjs|cjs|py|go|rs|java|kt|swift|rb)$/;
const DUMP_LINES = 60;
const BYPASS = /\bTRAIL_BYPASS=1\b/;

const SEARCH_REASON =
  'This repo has a trail graph. Search code with it, not grep or rg: ' +
  '`trail grep "<literal>"` finds every occurrence, grouped by symbol. ' +
  '`trail ask "<task>" --source` finds the code and shows it. ' +
  'Add `--in <path>/` to search one project. ' +
  'Searching logs, docs or generated files? Run the same command again with `TRAIL_BYPASS=1 ` in front.';

const DUMP_REASON =
  'This repo has a trail graph. Don\'t print a whole source file: ' +
  '`trail skeleton <file>` lists its API with line ranges. ' +
  'Then read only the range you need with the Read tool or `sed -n <a>,<b>p <file>`. ' +
  'Need the whole file? Run the same command again with `TRAIL_BYPASS=1 ` in front.';

function segments(command) {
  return command
    .split(/&&|\|\||[;|\n`]|\$\(/)
    .map((s) => s.trim().split(/\s+/).filter(Boolean))
    .map((words) => {
      let i = 0;
      while (i < words.length && /^[A-Za-z_]\w*=/.test(words[i])) i++;
      return words.slice(i);
    })
    .filter((words) => words.length > 0);
}

function isRecursiveFlag(word) {
  return word === '--recursive' || /^-[A-Za-z]*[rR][A-Za-z]*$/.test(word);
}

function isSearch([cmd, ...args]) {
  if (cmd === 'rg') return true;
  if (cmd === 'git' && args[0] === 'grep') return true;
  return (cmd === 'grep' || cmd === 'egrep') && args.some(isRecursiveFlag);
}

function headLines(args) {
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    const inline = /^(?:-n?|--lines=)(\d+)$/.exec(a);
    if (inline) return Number(inline[1]);
    if (a === '-n' && /^\d+$/.test(args[i + 1] ?? '')) return Number(args[i + 1]);
  }
  return 10;
}

function readsSource(args) {
  return args.some((a) => !/^[<>]/.test(a) && SOURCE_FILE.test(a));
}

function isDump([cmd, ...args]) {
  if (args.some((a) => /^[<>]/.test(a))) return false;
  if (cmd === 'cat') return readsSource(args);
  if (cmd === 'head') return headLines(args) >= DUMP_LINES && readsSource(args);
  return false;
}

export function routeToTrail(input, dir) {
  const command = input?.tool_input?.command;
  if (typeof command !== 'string' || BYPASS.test(command)) return null;
  if (!dir || !existsSync(join(dir, '.trail', 'cache'))) return null;
  const segs = segments(command);
  if (segs.some(isSearch)) return { permissionDecision: 'deny', reason: SEARCH_REASON };
  if (segs.some(isDump)) return { permissionDecision: 'deny', reason: DUMP_REASON };
  return null;
}
