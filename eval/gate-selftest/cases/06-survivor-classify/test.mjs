/**
 * Selftest for classify.mjs — synthetic inputs, no sui needed.
 * Tests the pure classification function directly.
 */
import { classifySurvivors } from '../../../../scripts/classify.mjs';

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

// Synthetic: two drop-assert survivors on same file, same abort code (redundant guards)
const allResults = [
  { file: 'sources/locker.move', line: 10, mutation: 'drop-assert', desc: 'drop', original: 'assert!(amount > 0, EZero)', killed: false },
  { file: 'sources/locker.move', line: 15, mutation: 'drop-assert', desc: 'drop', original: 'assert!(amount > 0, EZero)', killed: false },
  { file: 'sources/locker.move', line: 12, mutation: 'flip-gt', desc: 'flip', original: 'who == owner', killed: true },
  { file: 'sources/locker.move', line: 18, mutation: 'flip-lte', desc: 'flip', original: 'amount <= balance', killed: true },
];

const allAsserts = [
  { file: 'sources/locker.move', line: 10, code: 'EZero', type: 'assert' },
  { file: 'sources/locker.move', line: 15, code: 'EZero', type: 'assert' },
  { file: 'sources/locker.move', line: 12, code: 'ENotOwner', type: 'assert' },
  { file: 'sources/locker.move', line: 18, code: 'EOverBalance', type: 'assert' },
];

const { reframed, probeResults } = classifySurvivors(allResults, allAsserts);

// Both drop-assert survivors should be reframed
check('reframed count', reframed.length === 2);
check('both have evidence', reframed.every(r => r.evidence !== null));
check('evidence says suspected-equivalent', reframed.every(r => r.evidence.includes('suspected-equivalent')));
check('evidence says mutual redundancy', reframed.every(r => r.evidence.includes('mutual redundancy')));

// Probe should identify the redundant pair
check('probe count', probeResults.length === 1);
check('probe code', probeResults[0].code === 'EZero');
check('probe lines', probeResults[0].lines.includes(10) && probeResults[0].lines.includes(15));

// Non-redundant survivor should NOT get evidence
const soloResults = [
  { file: 'sources/x.move', line: 5, mutation: 'drop-assert', desc: 'drop', original: 'assert!(a > 0, EA)', killed: false },
  { file: 'sources/x.move', line: 10, mutation: 'flip-gt', desc: 'flip', original: 'b > c', killed: false },
];
const soloAsserts = [
  { file: 'sources/x.move', line: 5, code: 'EA', type: 'assert' },
];
const solo = classifySurvivors(soloResults, soloAsserts);
check('solo drop: no evidence (only one site)', solo.reframed[0].evidence === null);
check('solo flip: no evidence (not drop-assert)', solo.reframed[1].evidence === null);
check('solo: no probe', solo.probeResults.length === 0);

// Zero survivors
const empty = classifySurvivors(allResults.map(r => ({ ...r, killed: true })), allAsserts);
check('empty: no reframed', empty.reframed.length === 0);

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('classify selftest: all checks passed');
  process.exit(0);
}
