import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { routeToTrail } from './route.js';

const indexed = mkdtempSync(join(tmpdir(), 'trail-route-'));
mkdirSync(join(indexed, '.trail', 'cache'), { recursive: true });
const plain = mkdtempSync(join(tmpdir(), 'trail-route-'));

const decide = (command, dir = indexed) => routeToTrail({ tool_input: { command } }, dir)?.reason.split(':')[0] ?? 'allow';
const SEARCH = 'This repo has a trail graph. Search code with it, not grep or rg';
const DUMP = 'This repo has a trail graph. Don\'t print a whole source file';

const cases = [
  ['cd services/backend && grep -rln "LifecycleEvent\\|lifecycle-event" src', SEARCH],
  ["grep -rn \"'SiteClosedEvent'\\|'SiteFrmpEvent'\" src", SEARCH],
  ['grep --recursive foo .', SEARCH],
  ['grep -Fr foo src', SEARCH],
  ['rg handleLifecycleEvent', SEARCH],
  ['git grep -n foo', SEARCH],
  ['FOO=1 rg foo', SEARCH],
  ['cat types.ts | head -150', DUMP],
  ['head -150 src/types.ts', DUMP],
  ['head -n 200 src/types.ts', DUMP],
  ['sed -n 255,275p services/x/handleLifecycleEvent.ts', 'allow'],
  ['head -20 src/types.ts', 'allow'],
  ['grep foo src/types.ts', 'allow'],
  ['git log --oneline | grep fix', 'allow'],
  ['cat README.md', 'allow'],
  ['cat > src/new.ts <<EOF', 'allow'],
  ['cat <<EOF > src/new.ts', 'allow'],
  ['TRAIL_BYPASS=1 grep -rn ERROR inc112-logs', 'allow'],
  ['TRAIL_BYPASS=1 cat src/types.ts', 'allow'],
  ['ls src', 'allow'],
];

for (const [command, want] of cases) {
  test(`${want === 'allow' ? 'allows' : 'denies'}: ${command}`, () => {
    assert.equal(decide(command), want);
  });
}

test('allows everything in a repo with no trail graph', () => {
  assert.equal(decide('grep -rn foo src', plain), 'allow');
  assert.equal(decide('cat src/types.ts', plain), 'allow');
});

test('allows a payload with no command', () => {
  assert.equal(routeToTrail({}, indexed), null);
});
