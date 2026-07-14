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
 *   node check-coverage.mjs ./examples/sources ./examples/tests
 *   node check-coverage.mjs ./examples/sources ./examples/tests --mutate
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'fs';
import { join, basename, relative } from 'path';
import { execSync } from 'child_process';

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

function extractAsserts(filePath) {
  const content = readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const asserts = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // assert!(condition, ERROR_CODE)
    const assertMatch = line.match(/assert!\s*\(.*?,\s*(\w+)\s*\)/);
    if (assertMatch) {
      asserts.push({
        file: filePath,
        line: i + 1,
        code: assertMatch[1],
        text: line,
        type: 'assert',
      });
    }

    // abort ERROR_CODE
    const abortMatch = line.match(/abort\s+(\w+)/);
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

    // #[expected_failure(abort_code = module::ERROR_CODE)]
    const efMatch = line.match(/expected_failure\s*\(\s*abort_code\s*=\s*[\w:]*?(\w+)\s*\)/);
    if (efMatch) {
      // find the test function name (next line with 'fun')
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
      });
    }

    // #[expected_failure] without specific code
    if (/^\#\[expected_failure\]/.test(line)) {
      let fnName = '?';
      for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
        const fnMatch = lines[j].match(/fun\s+(\w+)/);
        if (fnMatch) { fnName = fnMatch[1]; break; }
      }

      failures.push({
        file: filePath,
        line: i + 1,
        code: '*',
        fnName,
        text: line,
      });
    }
  }

  return failures;
}

// ── mutation testing ─────────────────────────────────────────────────

const MUTATIONS = [
  {
    name: 'flip-comparison',
    desc: 'Flip < to >=',
    pattern: /(\w+)\s*<\s*(\w+)/,
    replace: (m, a, b) => `${a} >= ${b}`,
  },
  {
    name: 'flip-lte',
    desc: 'Flip <= to >',
    pattern: /(\w+)\s*<=\s*(\w+)/,
    replace: (m, a, b) => `${a} > ${b}`,
  },
  {
    name: 'flip-eq',
    desc: 'Flip == to !=',
    pattern: /(\w+)\s*==\s*(\w+)/,
    replace: (m, a, b) => `${a} != ${b}`,
  },
  {
    name: 'zero-amount',
    desc: 'Replace amount with 0',
    pattern: /assert!\s*\(\s*(\w+)\s*>\s*0/,
    replace: () => 'assert!(true',
  },
];

function runMutations(sourceDir, testDir) {
  const sourceFiles = walkDir(sourceDir, '.move');
  const results = [];

  for (const srcFile of sourceFiles) {
    const original = readFileSync(srcFile, 'utf8');
    const lines = original.split('\n');

    for (const mut of MUTATIONS) {
      for (let i = 0; i < lines.length; i++) {
        if (!mut.pattern.test(lines[i])) continue;
        if (lines[i].trim().startsWith('//')) continue;

        // apply mutation
        const mutated = [...lines];
        mutated[i] = mutated[i].replace(mut.pattern, mut.replace);
        writeFileSync(srcFile, mutated.join('\n'));

        // run tests
        let killed = false;
        try {
          execSync('sui move test 2>&1', {
            cwd: join(sourceDir, '..'),
            timeout: 30000,
            stdio: 'pipe',
          });
          // tests passed = mutation survived = bad
          killed = false;
        } catch {
          // tests failed = mutation killed = good
          killed = true;
        }

        results.push({
          file: relative(process.cwd(), srcFile),
          line: i + 1,
          mutation: mut.name,
          desc: mut.desc,
          original: lines[i].trim(),
          killed,
        });

        // restore original
        writeFileSync(srcFile, original);
        break; // one mutation per type per file
      }
    }
  }

  return results;
}

// ── main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Usage: node check-coverage.mjs <sources-dir> <tests-dir> [--mutate]');
  process.exit(1);
}

const [sourceDir, testDir] = args;
const doMutate = args.includes('--mutate');

console.log('=== move-test-gen coverage checker ===\n');

// Layer 1: collect asserts and expected_failures
const sourceFiles = walkDir(sourceDir, '.move');
const testFiles = walkDir(testDir, '.move');

const allAsserts = sourceFiles.flatMap(extractAsserts);
const allFailures = testFiles.flatMap(extractExpectedFailures);

console.log(`Source files: ${sourceFiles.length}`);
console.log(`Test files:   ${testFiles.length}`);
console.log(`Asserts found:           ${allAsserts.length}`);
console.log(`Expected failures found: ${allFailures.length}\n`);

// pair them
const assertCodes = new Set(allAsserts.map(a => a.code));
const failureCodes = new Set(allFailures.map(f => f.code));

const unpaired = allAsserts.filter(a => !failureCodes.has(a.code) && !failureCodes.has('*'));
const covered = allAsserts.filter(a => failureCodes.has(a.code) || failureCodes.has('*'));

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
    const match = allFailures.find(f => f.code === c.code || f.code === '*');
    console.log(`  ✓ ${c.code} (${rel}:${c.line}) → ${match?.fnName || '?'}`);
  }
}

// Layer 2: mutation testing (optional)
if (doMutate) {
  console.log('\n--- Mutation Testing ---\n');
  console.log('Injecting deterministic mutations into source...\n');

  const mutResults = runMutations(sourceDir, testDir);

  const killed = mutResults.filter(r => r.killed);
  const survived = mutResults.filter(r => !r.killed);

  console.log(`Mutations: ${mutResults.length} total`);
  console.log(`Killed:    ${killed.length} (tests caught the bug ✓)`);
  console.log(`Survived:  ${survived.length} (tests missed the bug ✗)`);

  if (survived.length > 0) {
    console.log('\nSurviving mutations (test suite did NOT catch these):');
    for (const s of survived) {
      console.log(`  ✗ ${s.file}:${s.line} [${s.mutation}] ${s.desc}`);
      console.log(`    ${s.original}`);
    }
  }

  const score = mutResults.length > 0
    ? Math.round((killed.length / mutResults.length) * 100)
    : 100;
  console.log(`\nMutation score: ${score}%`);
  if (score === 100) console.log('All mutations killed — test suite is effective.');
  else console.log(`${survived.length} mutation(s) survived — consider strengthening tests.`);
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
console.log('✓ All asserts have matching expected_failure tests');
