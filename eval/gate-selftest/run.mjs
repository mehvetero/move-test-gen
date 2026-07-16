#!/usr/bin/env node

/**
 * gate-selftest — regression suite for scripts/check-coverage.mjs (the lab's scorer).
 *
 * Replays every parser trap found during the five review rounds (2026-07-14/15)
 * as pinned cases: comma-in-condition, trailing comments, `//` and `)` inside
 * string literals, three multiline assert styles, commented-out test attributes,
 * bare #[expected_failure] inflation, shared-abort-code warning — plus one
 * KNOWN LIMITATION pinned on purpose (case 05).
 *
 * Layer 1 + exit codes only: fully deterministic, no sui required, no network.
 * Run from the repo root:   node eval/gate-selftest/run.mjs
 * Point at another gate:    GATE=path/to/check-coverage.mjs node eval/gate-selftest/run.mjs
 *
 * Exit 0 = every case green (safe to trust the scorer / safe to ship a gate change).
 * Exit 1 = a pinned behavior changed — fix the gate or consciously re-pin the case.
 */

import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { spawnSync } from 'child_process';
import { fileURLToPath } from 'url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..', '..');
const GATE = process.env.GATE || join(repoRoot, 'scripts', 'check-coverage.mjs');

if (!existsSync(GATE)) {
  console.error(`gate not found: ${GATE}`);
  console.error('run from the repo root, or set GATE=path/to/check-coverage.mjs');
  process.exit(2);
}

const casesDir = join(here, 'cases');
let pass = 0;
let fail = 0;

for (const name of readdirSync(casesDir).sort()) {
  const dir = join(casesDir, name);
  const exp = JSON.parse(readFileSync(join(dir, 'expected.json'), 'utf8'));

  const r = spawnSync(process.execPath, [GATE, join(dir, 'sources'), join(dir, 'tests')], {
    encoding: 'utf8',
    timeout: 30000,
  });
  const out = (r.stdout || '') + (r.stderr || '');
  const errs = [];

  const grab = (re) => {
    const m = out.match(re);
    return m ? m[1] : null;
  };

  const asserts = Number(grab(/Asserts found:\s+(\d+)/));
  const covered = grab(/Covered:\s+(\d+\/\d+)/);

  if (exp.asserts !== undefined && asserts !== exp.asserts) {
    errs.push(`asserts found: ${asserts}, expected ${exp.asserts}`);
  }
  if (exp.covered !== undefined && covered !== exp.covered) {
    errs.push(`covered: ${covered}, expected ${exp.covered}`);
  }
  if (exp.exit !== undefined && r.status !== exp.exit) {
    errs.push(`exit code: ${r.status}, expected ${exp.exit}`);
  }
  for (const s of exp.stdout_contains || []) {
    if (!out.includes(s)) errs.push(`output missing: "${s}"`);
  }
  for (const s of exp.stdout_absent || []) {
    if (out.includes(s)) errs.push(`output must NOT contain: "${s}"`);
  }

  if (errs.length) {
    fail++;
    console.log(`✗ ${name}`);
    for (const e of errs) console.log(`    ${e}`);
  } else {
    pass++;
    console.log(`✓ ${name}${exp.note ? '  — ' + exp.note.split('.')[0] : ''}`);
  }
}

console.log(`\ngate-selftest: ${pass}/${pass + fail} cases green`);
if (fail > 0) {
  console.log('a pinned behavior changed — fix the gate, or consciously update the case and say why in the commit.');
  process.exit(1);
}
