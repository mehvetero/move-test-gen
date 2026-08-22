#!/usr/bin/env node
/**
 * lint.mjs's runLint() used to hand each rule the RAW source. Rules
 * regex-match lines with no block-comment awareness of their own, so a
 * function commented out inside a Move block comment was flagged
 * identically to live code -- a clean-up commit that comments out dead
 * code would look like a fresh security regression.
 *
 * runLint() now strips block comments (via strip-comments.mjs's
 * stripBlockComments(), which preserves line count) once per file before
 * any rule sees it. This pins both directions on the real CLI entry point:
 * a commented-out unsafe function produces no finding, and a live control
 * function with the identical defect still does, at the right line number.
 */
import { mkdtempSync, mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { runLint } from '../../../../scripts/lint.mjs';

const errs = [];
function assert(label, cond) {
  if (!cond) errs.push(label);
}

const dir = mkdtempSync(join(tmpdir(), 'mtg-lint-comment-strip-'));
mkdirSync(join(dir, 'sources'), { recursive: true });
writeFileSync(join(dir, 'sources', 'a.move'), `module example::commented {
    public struct Pool has key { id: UID, balance: u64 }

    /*
    public fun drain(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
    */

    public fun live_unsafe(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}
`);

const { findings } = await runLint(join(dir, 'sources'));
const mov001 = findings.filter(f => f.rule === 'MOV-001');

assert(
  'a function entirely inside /* */ must not be flagged (was: "drain" at line 5)',
  !mov001.some(f => f.line === 5)
);
assert(
  'a live control function with the identical defect must still be flagged',
  mov001.some(f => f.line === 10)
);
assert(
  'exactly one finding total -- the commented function contributes none',
  mov001.length === 1
);

if (errs.length) {
  console.log(`${errs.length} case(s) failed:`);
  for (const e of errs) console.log(`  - ${e}`);
  process.exit(1);
}
console.log('block-commented-out code produces no lint findings; live code is unaffected');
process.exit(0);
