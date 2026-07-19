/**
 * Selftest for scope-filter.mjs — pure function, no sui needed.
 */
import { filterByScope } from '../../../../scripts/scope-filter.mjs';

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

const files = [
  '/tmp/mtg/sources/fund.move',
  '/tmp/mtg/sources/math128.move',
  '/tmp/mtg/sources/math256.move',
  '/tmp/mtg/sources/defi/oracle.move',
  '/tmp/mtg/sources/utils/vectors.move',
];

// single target
const r1 = filterByScope(files, ['fund.move']);
check('single target: 1 file', r1.length === 1);
check('single target: correct file', r1[0].endsWith('fund.move'));

// multiple targets
const r2 = filterByScope(files, ['fund.move', 'oracle.move']);
check('multi target: 2 files', r2.length === 2);
check('multi target: fund', r2.some(f => f.endsWith('fund.move')));
check('multi target: oracle', r2.some(f => f.endsWith('oracle.move')));

// no match
const r3 = filterByScope(files, ['nonexistent.move']);
check('no match: 0 files', r3.length === 0);

// empty scope (edge case)
const r4 = filterByScope(files, []);
check('empty scope: 0 files', r4.length === 0);

// partial filename match (should NOT match "math128" when scope is "math1")
const r5 = filterByScope(files, ['math1']);
check('partial name: no false match', r5.length === 0);

// full filename match with subdirectory
const r6 = filterByScope(files, ['vectors.move']);
check('subdir match: finds vectors', r6.length === 1);

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('scope-pure-fn selftest: all checks passed');
  process.exit(0);
}
