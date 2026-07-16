/**
 * Selftest for classify.mjs — synthetic inputs, no sui needed.
 * Three branches: (a) joint killed → evidence, (b) joint survived → no evidence, (c) no candidates.
 */
import { classifySurvivors, identifyProbeCandidates, finalizeEvidence } from '../../../../scripts/classify.mjs';

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

// ── Shared test data ──

const redundantResults = [
  { file: 'sources/locker.move', line: 10, mutation: 'drop-assert', desc: 'drop', original: 'assert!(amount > 0, EZero)', killed: false },
  { file: 'sources/locker.move', line: 15, mutation: 'drop-assert', desc: 'drop', original: 'assert!(amount > 0, EZero)', killed: false },
  { file: 'sources/locker.move', line: 12, mutation: 'flip-gt', desc: 'flip', original: 'who == owner', killed: true },
  { file: 'sources/locker.move', line: 18, mutation: 'flip-lte', desc: 'flip', original: 'amount <= balance', killed: true },
];

const redundantAsserts = [
  { file: 'sources/locker.move', line: 10, code: 'EZero', type: 'assert' },
  { file: 'sources/locker.move', line: 15, code: 'EZero', type: 'assert' },
  { file: 'sources/locker.move', line: 12, code: 'ENotOwner', type: 'assert' },
  { file: 'sources/locker.move', line: 18, code: 'EOverBalance', type: 'assert' },
];

// ── (a) singles survive + joint killed → evidence ──

const resultA = classifySurvivors(redundantResults, redundantAsserts, [true]);
check('(a) reframed count', resultA.reframed.length === 2);
check('(a) both have evidence', resultA.reframed.every(r => r.evidence !== null));
check('(a) evidence says suspected-equivalent', resultA.reframed.every(r => r.evidence.includes('suspected-equivalent')));
check('(a) evidence says mutual redundancy', resultA.reframed.every(r => r.evidence.includes('mutual redundancy')));

// ── (b) singles survive + joint ALSO survives → no evidence (just undecidable) ──

const resultB = classifySurvivors(redundantResults, redundantAsserts, [false]);
check('(b) reframed count', resultB.reframed.length === 2);
check('(b) NO evidence when joint survives', resultB.reframed.every(r => r.evidence === null));

// ── (c) no candidates (solo survivors, different codes) ──

const soloResults = [
  { file: 'sources/x.move', line: 5, mutation: 'drop-assert', desc: 'drop', original: 'assert!(a > 0, EA)', killed: false },
  { file: 'sources/x.move', line: 10, mutation: 'flip-gt', desc: 'flip', original: 'b > c', killed: false },
];
const soloAsserts = [
  { file: 'sources/x.move', line: 5, code: 'EA', type: 'assert' },
];
const resultC = classifySurvivors(soloResults, soloAsserts);
check('(c) solo drop: no evidence', resultC.reframed[0].evidence === null);
check('(c) solo flip: no evidence', resultC.reframed[1].evidence === null);
check('(c) no probe outcomes', resultC.probeOutcomes.length === 0);

// ── Stage 1 isolation: identifyProbeCandidates ──

const { candidates } = identifyProbeCandidates(redundantResults, redundantAsserts);
check('candidates found', candidates.length === 1);
check('candidate code', candidates[0].code === 'EZero');
check('candidate lines', candidates[0].lines.includes(10) && candidates[0].lines.includes(15));

// ── Stage 2 isolation: finalizeEvidence ──

const survived = redundantResults.filter(r => !r.killed);
const withJoint = finalizeEvidence(survived, [{ ...candidates[0], jointKilled: true }]);
check('finalize with joint killed: evidence', withJoint.every(r => r.evidence !== null));
const withoutJoint = finalizeEvidence(survived, [{ ...candidates[0], jointKilled: false }]);
check('finalize with joint survived: no evidence', withoutJoint.every(r => r.evidence === null));

// ── Zero survivors ──

const empty = classifySurvivors(redundantResults.map(r => ({ ...r, killed: true })), redundantAsserts);
check('empty: no reframed', empty.reframed.length === 0);

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('classify selftest: all checks passed');
  process.exit(0);
}
