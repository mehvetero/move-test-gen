/**
 * lint.mjs — security lint engine for Sui Move source code.
 *
 * Loads rules from rules/ directory, runs each against every .move file
 * in the given sources directory, reports findings grouped by severity.
 *
 * Rules are pure functions: (source, filename) → findings[].
 * Each rule is a standalone .mjs file with check() and meta exports.
 * No Move compiler needed — regex-based pattern detection.
 *
 * Usage (standalone):
 *   node scripts/lint.mjs <sources-dir>
 *
 * Usage (via check-coverage.mjs):
 *   node scripts/check-coverage.mjs <sources> <tests> --lint
 */

import { readdirSync, readFileSync } from 'fs';
import { join, resolve, relative, dirname } from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const here = dirname(fileURLToPath(import.meta.url));
const RULES_DIR = join(here, '..', 'rules');

function walkDir(dir, ext) {
  const results = [];
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return results; }
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) results.push(...walkDir(full, ext));
    else if (entry.name.endsWith(ext)) results.push(full);
  }
  return results;
}

/**
 * Run all lint rules against source files.
 * @param {string} sourcesDir
 * @returns {Promise<{findings: Array, ruleCount: number}>}
 */
export async function runLint(sourcesDir) {
  // load rules
  const ruleFiles = readdirSync(RULES_DIR)
    .filter(f => f.endsWith('.mjs') && f.startsWith('mov-'))
    .sort();

  const rules = [];
  for (const rf of ruleFiles) {
    const mod = await import(pathToFileURL(join(RULES_DIR, rf)).href);
    rules.push({ check: mod.check, meta: mod.meta, file: rf });
  }

  // load sources
  const sourceFiles = walkDir(resolve(sourcesDir), '.move');
  const allFindings = [];

  for (const srcPath of sourceFiles) {
    const source = readFileSync(srcPath, 'utf8');
    const filename = relative(process.cwd(), srcPath);

    for (const rule of rules) {
      const findings = rule.check(source, filename);
      allFindings.push(...findings);
    }
  }

  return { findings: allFindings, ruleCount: rules.length };
}

/**
 * Print lint results to console.
 */
export function printLintResults(findings, ruleCount) {
  console.log(`\n=== Security Lint (${ruleCount} rules) ===\n`);

  if (findings.length === 0) {
    console.log('No findings.\n');
    return;
  }

  const bySeverity = { CRITICAL: [], HIGH: [], MEDIUM: [], LOW: [], INFO: [] };
  for (const f of findings) {
    (bySeverity[f.severity] || bySeverity.INFO).push(f);
  }

  for (const [sev, items] of Object.entries(bySeverity)) {
    for (const f of items) {
      const icon = sev === 'CRITICAL' || sev === 'HIGH' ? '🔴' : sev === 'MEDIUM' ? '🟡' : '🔵';
      console.log(`  ${icon} ${sev}  ${f.file}:${f.line}  [${f.rule}] ${f.message}`);
    }
  }

  const counts = {};
  for (const f of findings) counts[f.severity] = (counts[f.severity] || 0) + 1;
  const summary = Object.entries(counts).map(([s, n]) => `${n} ${s.toLowerCase()}`).join(', ');
  console.log(`\n${findings.length} finding(s): ${summary}`);
}

// standalone mode
if (process.argv[1] && process.argv[1].endsWith('lint.mjs')) {
  const dir = process.argv[2];
  if (!dir) {
    console.log('Usage: node scripts/lint.mjs <sources-dir>');
    process.exit(1);
  }
  const { findings, ruleCount } = await runLint(dir);
  printLintResults(findings, ruleCount);
  if (findings.some(f => f.severity === 'CRITICAL' || f.severity === 'HIGH')) {
    process.exit(1);
  }
}
