#!/usr/bin/env node

/**
 * eval/run.mjs — move-test-gen eval lab runner (v0: manual generation, automated scoring)
 *
 * The skill generates (a human fires the frozen template at Claude Code);
 * this runner scores, records, and decides retirement. Deterministic only.
 *
 * Commands (run from the repo root):
 *   node eval/run.mjs doctor
 *       env check: gate present, sui CLI vs each scenario's Move.toml pin.
 *   node eval/run.mjs score <scenario-dir> [--template main|varied] [--layer1-only]
 *       score the generated suite currently sitting in <scenario-dir>/tests/,
 *       archive it, restore the scenario, append the round record.
 *   node eval/run.mjs status
 *       campaign table across all scenarios.
 *
 * Protocol (from the CoalWash campaign record, adopted 2026-07-16):
 *   - findings = unpaired asserts ∪ surviving mutants (deterministic gate output)
 *   - a round is DRY when it adds zero new findings
 *   - after 2 consecutive dry rounds, the next round MUST use prompt-varied.template
 *   - a dry varied round closes the scenario: RETIRED
 *   - generated tests are archived and the scenario is restored every round
 *     (a caught artifact is reverted in the same round, never left in place)
 *   - figures live in eval/results/<scenario>/rounds.json — never edit by hand.
 */

import {
  readFileSync, writeFileSync, readdirSync, existsSync, mkdirSync,
  copyFileSync, unlinkSync,
} from 'fs';
import { join, dirname, resolve, relative, basename } from 'path';
import { spawnSync } from 'child_process';
import { fileURLToPath } from 'url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');
const GATE = join(repoRoot, 'scripts', 'check-coverage.mjs');
const RESULTS = join(here, 'results');

// ── helpers ──────────────────────────────────────────────────────────

const die = (msg) => { console.error(`✗ ${msg}`); process.exit(2); };

function suiVersion() {
  const r = spawnSync('sui', ['--version'], { encoding: 'utf8', shell: true, timeout: 15000 });
  const m = ((r.stdout || '') + (r.stderr || '')).match(/sui\s+(\d+\.\d+\.\d+)/);
  return m ? m[1] : null;
}

function tomlPin(scenarioDir) {
  const p = join(scenarioDir, 'Move.toml');
  if (!existsSync(p)) return null;
  const m = readFileSync(p, 'utf8').match(/rev\s*=\s*"([^"]+)"/);
  return m ? m[1] : null;
}

function listMoveFiles(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((f) => f.endsWith('.move'));
}

function normPath(p) {
  // stable finding keys across OS and cwd: forward slashes, path from 'sources/' or 'tests/'
  const s = p.replace(/\\/g, '/');
  const i = s.search(/(sources|tests)\//);
  return i >= 0 ? s.slice(i) : s;
}

function loadRounds(scenName) {
  const p = join(RESULTS, scenName, 'rounds.json');
  return existsSync(p) ? JSON.parse(readFileSync(p, 'utf8')) : [];
}

function saveRounds(scenName, rounds) {
  const dir = join(RESULTS, scenName);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'rounds.json'), JSON.stringify(rounds, null, 2) + '\n');
}

function trailingDry(rounds) {
  let n = 0;
  for (let i = rounds.length - 1; i >= 0; i--) {
    if (rounds[i].dry) n++;
    else break;
  }
  return n;
}

function verdict(rounds) {
  const last = rounds[rounds.length - 1];
  const dry = trailingDry(rounds);
  if (last && last.dry && last.template === 'varied' && dry >= 3) return 'RETIRED';
  if (dry >= 2) return 'VARIED-SWEEP-REQUIRED';
  return 'CONTINUE';
}

// ── gate invocation + parsing ────────────────────────────────────────

function runGate(scenarioDir, { mutate, scope }) {
  const args = [GATE,
    join(relative(repoRoot, scenarioDir), 'sources'),
    join(relative(repoRoot, scenarioDir), 'tests')];
  if (mutate) args.push('--mutate');
  if (scope) { args.push('--scope'); args.push(scope); }
  const r = spawnSync(process.execPath, args, {
    cwd: repoRoot, encoding: 'utf8', timeout: 30 * 60 * 1000,
  });
  const out = (r.stdout || '') + (r.stderr || '');

  const num = (re) => { const m = out.match(re); return m ? Number(m[1]) : null; };
  const parsed = {
    exit: r.status,
    asserts: num(/Asserts found:\s+(\d+)/),
    covered: (out.match(/Covered:\s+(\d+\/\d+)/) || [])[1] || null,
    mutations: num(/Mutations:\s+(\d+)/),
    killed: num(/Killed:\s+(\d+)/),
    survived: num(/Survived:\s+(\d+)/),
    score: num(/Mutation score[^:]*:\s+(\d+)%/),
    mutateSkipped: /could not run/.test(out),
    findings: [],
  };

  for (const m of out.matchAll(/^\s{2}(\S+):(\d+)\s+(assert|abort)\s+(\w+)\s*$/gm)) {
    parsed.findings.push(`unpaired:${m[4]}@${normPath(m[1])}:${m[2]}`);
  }
  for (const m of out.matchAll(/^\s{2}✗\s+(\S+):(\d+)\s+\[([\w-]+)\]/gm)) {
    parsed.findings.push(`survived:${m[3]}@${normPath(m[1])}:${m[2]}`);
  }

  // parse evidence lines: "    evidence: ... suspected-equivalent"
  const evidenceFindings = new Set();
  const lines = out.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (/evidence:.*suspected-equivalent/.test(lines[i])) {
      // walk back to find the survivor line this evidence belongs to
      for (let j = i - 1; j >= Math.max(0, i - 3); j--) {
        const sm = lines[j].match(/✗\s+(\S+):(\d+)\s+\[([\w-]+)\]/);
        if (sm) {
          evidenceFindings.add(`survived:${sm[3]}@${normPath(sm[1])}:${sm[2]}`);
          break;
        }
      }
    }
  }
  parsed.evidenceFindings = evidenceFindings;

  return { parsed, out };
}

// ── commands ─────────────────────────────────────────────────────────

function cmdDoctor() {
  let ok = true;
  if (existsSync(GATE)) console.log('✓ gate present: scripts/check-coverage.mjs');
  else { ok = false; console.log('✗ gate missing: scripts/check-coverage.mjs'); }

  const sui = suiVersion();
  if (sui) console.log(`✓ sui CLI: ${sui}`);
  else { ok = false; console.log('✗ sui CLI not on PATH (mutation rounds will skip — Layer 1 only)'); }

  const scenRoot = join(here, 'scenarios');
  for (const name of existsSync(scenRoot) ? readdirSync(scenRoot).sort() : []) {
    const dir = join(scenRoot, name);
    if (!existsSync(join(dir, 'sources'))) continue;
    const pin = tomlPin(dir);
    if (!pin) { console.log(`  ${name}: no Move.toml rev pin found`); continue; }
    const pinVer = (pin.match(/(\d+\.\d+\.\d+)/) || [])[1];
    if (sui && pinVer && sui !== pinVer) {
      ok = false;
      console.log(`✗ ${name}: pin ${pin} vs CLI ${sui} — MISMATCH (the baseline will fail; align them)`);
    } else {
      console.log(`✓ ${name}: pin ${pin}${sui ? ` matches CLI ${sui}` : ''}`);
    }
  }
  console.log(ok ? '\ndoctor: all clear' : '\ndoctor: fix the ✗ lines before a real round');
  process.exit(ok ? 0 : 1);
}

function cmdScore(argv) {
  const scenarioDir = resolve(argv.find((a) => !a.startsWith('--')) || die('score needs <scenario-dir>'));
  const template = argv.includes('--template')
    ? argv[argv.indexOf('--template') + 1]
    : 'main';
  if (!['main', 'varied'].includes(template)) die(`unknown template "${template}"`);
  const layer1Only = argv.includes('--layer1-only');

  const scenName = basename(scenarioDir);
  const testsDir = join(scenarioDir, 'tests');
  if (!existsSync(join(scenarioDir, 'sources'))) die(`no sources/ in ${scenName}`);

  const generated = listMoveFiles(testsDir);
  if (generated.length === 0) {
    die(`no generated tests in ${scenName}/tests/ — fire eval/prompt${template === 'varied' ? '-varied' : ''}.template at the skill first`);
  }

  // scenario source integrity: the gate must read the same site count every round
  const expectedPath = join(scenarioDir, 'expected.json');
  const expected = existsSync(expectedPath) ? JSON.parse(readFileSync(expectedPath, 'utf8')) : {};

  const rounds = loadRounds(scenName);
  if (verdict(rounds) === 'RETIRED') die(`${scenName} is RETIRED — no further rounds`);
  if (verdict(rounds) === 'VARIED-SWEEP-REQUIRED' && template !== 'varied') {
    die(`${scenName} has 2 consecutive dry rounds — this round must use --template varied (prompt-varied.template)`);
  }

  const scope = expected.target || null;
  const { parsed } = runGate(scenarioDir, { mutate: !layer1Only, scope });

  if (expected.asserts !== undefined && parsed.asserts !== expected.asserts) {
    die(`source integrity: gate found ${parsed.asserts} sites, expected.json says ${expected.asserts} — scenario sources drifted or got contaminated; restore before scoring`);
  }
  if (!layer1Only && parsed.mutateSkipped) {
    die('mutation could not run (see doctor) — a real round needs Layer 2; use --layer1-only only for smoke tests');
  }

  // load answer key if present (run.mjs reads this, gate never does — blind-brief)
  const keyPath = join(here, 'keys', `${scenName}.json`);
  const keyData = existsSync(keyPath) ? JSON.parse(readFileSync(keyPath, 'utf8')) : {};
  const planted = new Set(keyData.planted_equivalents || []);

  // adjudicate: planted + gate evidence → adjudicated_equivalent (not a finding)
  const adjudicated = [];
  const plantedSilent = [];
  const effectiveFindings = [];

  for (const f of parsed.findings) {
    if (planted.has(f) && parsed.evidenceFindings.has(f)) {
      adjudicated.push(f);
    } else if (planted.has(f) && !parsed.evidenceFindings.has(f)) {
      plantedSilent.push(f);
      effectiveFindings.push(f);
    } else {
      effectiveFindings.push(f);
    }
  }

  const known = new Set(rounds.flatMap((r) => r.findings));
  const newFindings = effectiveFindings.filter((f) => !known.has(f));
  const dry = newFindings.length === 0;

  // archive generated tests, then restore the scenario (rule: revert in the same round)
  const roundNo = rounds.length + 1;
  const archiveDir = join(RESULTS, scenName, `round-${String(roundNo).padStart(2, '0')}`);
  mkdirSync(archiveDir, { recursive: true });
  for (const f of generated) {
    copyFileSync(join(testsDir, f), join(archiveDir, f));
    unlinkSync(join(testsDir, f));
  }

  const record = {
    round: roundNo,
    date: new Date().toISOString().slice(0, 10),
    template,
    layer1Only,
    asserts: parsed.asserts,
    covered: parsed.covered,
    mutations: layer1Only ? null : {
      applied: parsed.mutations, killed: parsed.killed,
      survived: parsed.survived, score: parsed.score,
    },
    gateExit: parsed.exit,
    findings: effectiveFindings,
    newFindings,
    adjudicated_equivalent: adjudicated,
    planted_silent: plantedSilent,
    dry,
  };
  rounds.push(record);
  saveRounds(scenName, rounds);

  const v = verdict(rounds);
  console.log(`\n${scenName} · round ${roundNo} (${template}${layer1Only ? ', layer1-only' : ''})`);
  console.log(`  covered ${parsed.covered} · gate exit ${parsed.exit}` +
    (layer1Only ? '' : ` · mutants ${parsed.killed}/${parsed.mutations} killed`));
  console.log(`  findings ${effectiveFindings.length} (new: ${newFindings.length}) → ${dry ? 'DRY' : 'NOT-DRY'}`);
  for (const f of newFindings) console.log(`    + ${f}`);
  if (adjudicated.length > 0) {
    console.log(`  adjudicated equivalent: ${adjudicated.length} (planted + gate evidence → not findings)`);
    for (const a of adjudicated) console.log(`    ≡ ${a}`);
  }
  if (plantedSilent.length > 0) {
    console.log(`  ⚠ gate SILENT on planted equivalents (no evidence — gate honesty failure):`);
    for (const p of plantedSilent) console.log(`    ✗ ${p}`);
  }
  console.log(`  generated suite archived → ${relative(repoRoot, archiveDir)} · scenario restored`);
  console.log(`  verdict: ${v}${v === 'VARIED-SWEEP-REQUIRED' ? ' — next round: --template varied' : ''}`);
}

function cmdStatus() {
  if (!existsSync(RESULTS)) { console.log('no rounds recorded yet'); return; }
  console.log('scenario · rounds · dry-streak · verdict · last covered · last mutants · adjudicated');
  for (const name of readdirSync(RESULTS).sort()) {
    const rounds = loadRounds(name);
    if (!rounds.length) continue;
    const last = rounds[rounds.length - 1];
    const mut = last.mutations ? `${last.mutations.killed}/${last.mutations.applied}` : 'L1-only';
    const adj = (last.adjudicated_equivalent || []).length;
    console.log(`${name} · ${rounds.length} · ${trailingDry(rounds)} · ${verdict(rounds)} · ${last.covered} · ${mut} · ${adj}`);
  }
}

// ── main ─────────────────────────────────────────────────────────────

const [cmd, ...rest] = process.argv.slice(2);
if (cmd === 'doctor') cmdDoctor();
else if (cmd === 'score') cmdScore(rest);
else if (cmd === 'status') cmdStatus();
else {
  console.log('usage: node eval/run.mjs <doctor | score <scenario-dir> [--template main|varied] [--layer1-only] | status>');
  process.exit(2);
}
