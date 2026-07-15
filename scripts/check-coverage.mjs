#!/usr/bin/env node

/**
 * check-coverage.mjs
 *
 * Scans a Sui Move package and reports:
 *   1. Every assert!/abort in source modules
 *   2. Every #[expected_failure] test
 *   3. Unpaired asserts (no matching expected_failure test)
 *   4. (Optional) mutation results if --mutate flag is passed
 *
 * Usage:
 *   node check-coverage.mjs <sources-dir> <tests-dir>
 *   node check-coverage.mjs <sources-dir> <tests-dir> --mutate
 */

import { readFileSync, readdirSync, writeFileSync, mkdtempSync, cpSync, rmSync } from 'fs';
import { join, relative, resolve } from 'path';
import { execSync } from 'child_process';
import { tmpdir } from 'os';

// ── helpers ──────────────────────────────────────────────────────────

function walkDir(dir, ext) {
  const results = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) results.push(...walkDir(full, ext));
    else if (entry.name.endsWith(ext)) results.push(full);
  }
  return results;
}

function stripComment(line) {
  // Remove trailing // comment, but not inside string literals
  let inString = false;
  let quote = null;
  for (let i = 0; i < line.length - 1; i++) {
    const ch = line[i];
    if (inString) {
      if (ch === '\\') { i++; continue; } // skip escaped char
      if (ch === quote) inString = false;
    } else {
      if (ch === '"' || ch === '\'') { inString = true; quote = ch; }
      if (ch === '/' && line[i + 1] === '/' && !inString) return line.slice(0, i).trim();
    }
  }
  return line.trim();
}

function joinMultiline(lines, startIdx) {
  // Join lines until parentheses balance, respecting string literals
  let result = '';
  let depth = 0;
  let started = false;
  for (let i = startIdx; i < lines.length; i++) {
    const clean = stripComment(lines[i]);
    result += ' ' + clean;
    let inStr = false;
    let q = null;
    for (let j = 0; j < clean.length; j++) {
      const ch = clean[j];
      if (inStr) {
        if (ch === '\\') { j++; continue; }
        if (ch === q) inStr = false;
      } else {
        if (ch === '"' || ch === "\'") { inStr = true; q = ch; }
        if (ch === '(') { depth++; started = true; }
        if (ch === ')') depth--;
      }
    }
    if (started && depth <= 0) break;
  }
  return result.trim();
}

function extractAsserts(filePath) {
  const content = readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const asserts = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // skip full-line comments
    if (line.startsWith('//')) continue;

    const code = stripComment(line);

    // detect assert! start — may span multiple lines
    if (/assert!\s*\(/.test(code)) {
      const full = joinMultiline(lines, i);
      const assertMatch = full.match(/assert!\s*\(.*,\s*(\w+)\s*\)/);
      if (assertMatch) {
        asserts.push({
          file: filePath,
          line: i + 1,
          code: assertMatch[1],
          text: line,
          type: 'assert',
        });
      }
    }

    // abort ERROR_CODE — handle module-qualified (take last segment after ::)
    const abortMatch = code.match(/\babort\s+(?:[\w:]*::)?(\w+)\b/);
    if (abortMatch) {
      asserts.push({
        file: filePath,
        line: i + 1,
        code: abortMatch[1],
        text: line,
        type: 'abort',
      });
    }
  }

  return asserts;
}

function extractExpectedFailures(filePath) {
  const content = readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const failures = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // skip commented-out test annotations
    if (line.startsWith('//')) continue;
    const src = stripComment(line);

    // #[expected_failure(abort_code = module::ERROR_CODE)] or with location=
    // Match abort_code value, stop at comma or closing paren
    const efMatch = src.match(/expected_failure\s*\(\s*abort_code\s*=\s*[\w:]*?(\w+)\s*[,)]/);
    if (efMatch) {
      let fnName = '?';
      for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
        const fnMatch = lines[j].match(/fun\s+(\w+)/);
        if (fnMatch) { fnName = fnMatch[1]; break; }
      }

      failures.push({
        file: filePath,
        line: i + 1,
        code: efMatch[1],
        fnName,
        text: line,
        scoped: true,
      });
    }

    // expected_failure without abort_code (bare, arithmetic_error, out_of_gas, etc.)
    if (/^\#\[.*expected_failure/.test(src) && !efMatch) {
      let fnName = '?';
      for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
        const fnMatch = lines[j].match(/fun\s+(\w+)/);
        if (fnMatch) { fnName = fnMatch[1]; break; }
      }

      failures.push({
        file: filePath,
        line: i + 1,
        code: null,
        fnName,
        text: line,
        scoped: false,
      });
    }
  }

  return failures;
}

// ── mutation testing ─────────────────────────────────────────────────

const MUTATIONS = [
  {
    name: 'flip-lt',
    desc: 'Flip < to >=',
    pattern: /(\w+)\s+<\s+(\w+)/,
    replace: (m, a, b) => `${a} >= ${b}`,
  },
  {
    name: 'flip-gt',
    desc: 'Flip > to <=',
    pattern: /(\w+)\s+>\s+(\w+)/,
    replace: (m, a, b) => `${a} <= ${b}`,
  },
  {
    name: 'flip-lte',
    desc: 'Flip <= to >',
    pattern: /(\w+)\s*<=\s*(\w+)/,
    replace: (m, a, b) => `${a} > ${b}`,
  },
  {
    name: 'flip-gte',
    desc: 'Flip >= to <',
    pattern: /(\w+)\s*>=\s*(\w+)/,
    replace: (m, a, b) => `${a} < ${b}`,
  },
  {
    name: 'flip-eq',
    desc: 'Flip == to !=',
    pattern: /(\w+)\s*==\s*(\w+)/,
    replace: (m, a, b) => `${a} != ${b}`,
  },
  {
    name: 'flip-neq',
    desc: 'Flip != to ==',
    pattern: /(\w+)\s*!=\s*(\w+)/,
    replace: (m, a, b) => `${a} == ${b}`,
  },
  {
    name: 'drop-assert',
    desc: 'Comment out an assert!',
    pattern: /^(\s*)(assert!\s*\()/,
    replace: (m, ws, a) => `${ws}// MUTANT: ${a}`,
  },
];

function runMutations(packageDir, sourceDir) {
  // baseline: run tests on unmodified code first
  console.log('Running baseline test (unmodified code)...');
  let baselineMs;
  try {
    const start = Date.now();
    execSync('sui move test 2>&1', {
      cwd: packageDir,
      timeout: 120000,
      stdio: 'pipe',
    });
    baselineMs = Date.now() - start;
    console.log(`Baseline: PASS ✓ (${Math.round(baselineMs / 1000)}s)\n`);
  } catch (e) {
    const output = e.stdout?.toString() || e.stderr?.toString() || '';
    if (output.includes('not found') || output.includes('No such file') || output.includes('not recognized')) {
      console.log('ERROR: sui CLI not found. Cannot run mutation testing without sui.');
      console.log('Install: https://docs.sui.io/build/install\n');
      return null;
    }
    console.log('ERROR: Baseline tests fail on unmodified code.');
    console.log('Fix your tests before running mutation testing.\n');
    return null;
  }
  const mutantTimeout = Math.max(30000, baselineMs * 3);

  // work on a temp copy to protect user's source
  const tempDir = mkdtempSync(join(tmpdir(), 'mtg-mutate-'));
  cpSync(packageDir, tempDir, { recursive: true });
  const tempSourceDir = join(tempDir, relative(packageDir, sourceDir));

  const sourceFiles = walkDir(tempSourceDir, '.move');
  const results = [];

  const cleanup = () => {
    try { rmSync(tempDir, { recursive: true, force: true }); } catch {}
  };

  // handle SIGINT gracefully
  process.on('SIGINT', () => {
    console.log('\nInterrupted — cleaning up temp directory...');
    cleanup();
    process.exit(130);
  });

  try {
    for (const srcFile of sourceFiles) {
      const original = readFileSync(srcFile, 'utf8');
      const lines = original.split('\n');

      for (const mut of MUTATIONS) {
        for (let i = 0; i < lines.length; i++) {
          if (!mut.pattern.test(lines[i])) continue;
          if (lines[i].trim().startsWith('//')) continue;

          // apply mutation in temp copy
          const mutated = [...lines];
          mutated[i] = mutated[i].replace(mut.pattern, mut.replace);
          writeFileSync(srcFile, mutated.join('\n'));

          // check if mutant compiles first
          let compiles = true;
          try {
            execSync('sui move build 2>&1', {
              cwd: tempDir,
              timeout: mutantTimeout,
              stdio: 'pipe',
            });
          } catch {
            compiles = false;
          }

          if (!compiles) {
            // stillborn mutant — doesn't compile, skip
            writeFileSync(srcFile, original);
            continue;
          }

          // run tests against compiled mutant
          let killed = false;
          try {
            execSync('sui move test 2>&1', {
              cwd: tempDir,
              timeout: mutantTimeout,
              stdio: 'pipe',
            });
            // tests passed = mutation survived = weak test
            killed = false;
          } catch {
            // tests failed = mutation killed = good
            killed = true;
          }

          results.push({
            file: relative(tempDir, srcFile),
            line: i + 1,
            mutation: mut.name,
            desc: mut.desc,
            original: lines[i].trim(),
            killed,
          });

          // restore for next mutation
          writeFileSync(srcFile, original);
        }
      }
    }
  } finally {
    cleanup();
  }

  return results;
}

// ── main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Usage: node check-coverage.mjs <sources-dir> <tests-dir> [--mutate]');
  process.exit(1);
}

const [sourceDir, testDir] = args.map(a => resolve(a));
const doMutate = args.includes('--mutate');

console.log('=== move-test-gen coverage checker ===\n');

// Layer 1: collect asserts and expected_failures
let sourceFiles, testFiles;
try {
  sourceFiles = walkDir(sourceDir, '.move');
  testFiles = walkDir(testDir, '.move');
} catch (e) {
  console.error(`Error: cannot read directory — ${e.message}`);
  process.exit(1);
}

const allAsserts = sourceFiles.flatMap(extractAsserts);
const allFailures = testFiles.flatMap(extractExpectedFailures);
const scopedFailures = allFailures.filter(f => f.scoped);
const unscopedFailures = allFailures.filter(f => !f.scoped);

console.log(`Source files: ${sourceFiles.length}`);
console.log(`Test files:   ${testFiles.length}`);
console.log(`Asserts found:           ${allAsserts.length}`);
console.log(`Expected failures found: ${allFailures.length} (${scopedFailures.length} scoped, ${unscopedFailures.length} unscoped)\n`);

if (unscopedFailures.length > 0) {
  console.log('Note: unscoped #[expected_failure] tests (no abort_code):');
  for (const u of unscopedFailures) {
    const rel = relative(process.cwd(), u.file);
    console.log(`  ${rel}:${u.line} → ${u.fnName}`);
  }
  console.log('  These catch any abort but are not counted toward specific assert coverage.\n');
}

// pair only with scoped failures
const failureCodes = new Set(scopedFailures.map(f => f.code));

const unpaired = allAsserts.filter(a => !failureCodes.has(a.code));
const covered = allAsserts.filter(a => failureCodes.has(a.code));

console.log('--- Coverage ---');
console.log(`Covered:  ${covered.length}/${allAsserts.length}`);
console.log(`Unpaired: ${unpaired.length}/${allAsserts.length}`);

if (unpaired.length > 0) {
  console.log('\nUnpaired asserts (no matching expected_failure test):');
  for (const u of unpaired) {
    const rel = relative(process.cwd(), u.file);
    console.log(`  ${rel}:${u.line}  ${u.type} ${u.code}`);
    console.log(`    ${u.text}`);
  }
}

if (covered.length > 0) {
  console.log('\nCovered asserts:');
  for (const c of covered) {
    const rel = relative(process.cwd(), c.file);
    const match = scopedFailures.find(f => f.code === c.code);
    console.log(`  ✓ ${c.code} (${rel}:${c.line}) → ${match?.fnName || '?'}`);
  }
}

// Layer 2: mutation testing (optional)
if (doMutate) {
  console.log('\n--- Mutation Testing ---\n');

  // resolve package root (parent of sources dir)
  const packageDir = resolve(sourceDir, '..');
  const mutResults = runMutations(packageDir, sourceDir);

  if (mutResults === null) {
    console.log('Mutation testing skipped (see errors above).\n');
    process.exitCode = 1;
  } else if (mutResults.length === 0) {
    console.log('No applicable mutations found in source files.\n');
  } else {
    const killed = mutResults.filter(r => r.killed);
    const survived = mutResults.filter(r => !r.killed);

    console.log(`Mutations: ${mutResults.length} applied (stillborn excluded)`);
    console.log(`Killed:    ${killed.length} (tests caught the bug ✓)`);
    console.log(`Survived:  ${survived.length} (tests missed the bug ✗)`);

    if (survived.length > 0) {
      console.log('\nSurviving mutations (test suite did NOT catch these):');
      for (const s of survived) {
        console.log(`  ✗ ${s.file}:${s.line} [${s.mutation}] ${s.desc}`);
        console.log(`    ${s.original}`);
      }
    }

    const score = Math.round((killed.length / mutResults.length) * 100);
    console.log(`\nMutation score: ${score}%`);

    if (survived.length > 0) {
      process.exitCode = 1;
    }
  }
}

// summary
console.log('\n--- Summary ---');
const coverageScore = allAsserts.length > 0
  ? Math.round((covered.length / allAsserts.length) * 100)
  : 100;
console.log(`Assert coverage: ${coverageScore}% (${covered.length}/${allAsserts.length})`);
if (unpaired.length > 0) {
  console.log(`⚠ ${unpaired.length} assert(s) have no expected_failure test`);
  process.exit(1);
}
if (process.exitCode === 1) {
  console.log('✓ All asserts paired, but mutation testing found weaknesses (see above)');
} else {
  console.log('✓ All asserts have matching expected_failure tests');
}
