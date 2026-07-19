/**
 * Selftest: baseline 0-tests warning.
 * Runs the gate with --mutate against a scenario with empty tests/.
 * Expects: exit 1 + "0 tests" or "empty check" in output.
 * Requires sui CLI on PATH (this is a Layer 2 test).
 */
import { spawnSync } from 'child_process';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..', '..', '..', '..');
const GATE = join(repoRoot, 'scripts', 'check-coverage.mjs');

// Use scenario 10's sources with its empty tests/ (gitkeep only)
const scenario = join(repoRoot, 'eval', 'scenarios', '10-suitears-fixedpoint');
const sources = join(scenario, 'sources');
const tests = join(scenario, 'tests');

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

// Check if sui is available — if not, skip gracefully
const suiCheck = spawnSync('sui', ['--version'], { encoding: 'utf8', shell: true, timeout: 10000 });
if (!suiCheck.stdout || !suiCheck.stdout.includes('sui')) {
  console.log('baseline-zero-tests selftest: SKIPPED (sui CLI not on PATH)');
  process.exit(0);
}

const r = spawnSync(process.execPath, [GATE, sources, tests, '--mutate'], {
  encoding: 'utf8',
  timeout: 120000,
  cwd: repoRoot,
});
const out = (r.stdout || '') + (r.stderr || '');

check('exit code is 1 (not 0)', r.status === 1);
check('output contains 0-test warning', out.includes('0 tests') || out.includes('empty check'));
check('output does NOT say "Mutations:"', !out.includes('Mutations:'));

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('baseline-zero-tests selftest: all checks passed');
  process.exit(0);
}
