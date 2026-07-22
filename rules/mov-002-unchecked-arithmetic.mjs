/**
 * MOV-002: Integer multiplication without overflow protection.
 *
 * Flags multiplication of u64 values without prior cast to u128/u256.
 * The Move VM aborts on arithmetic overflow, but in some contexts
 * (bitwise shifts, checked_shlw patterns) overflow is silent.
 *
 * Why it matters: The Cetus $223M exploit root cause was an incorrect
 * overflow check on a shift operation. Kriya had the identical bug.
 * Any u64 * u64 that could exceed 2^64 needs u128 promotion BEFORE
 * the multiplication, not after.
 *
 * What this catches:
 *   amount * price          — no cast, potential overflow
 *   (a as u128) * (b as u128)  — safe, not flagged
 *
 * Limitations: regex-based, may flag safe multiplications where
 * operands are known-small. Better to warn and let the developer
 * suppress than to miss a Cetus-class bug.
 */

const RULE_ID = 'MOV-002';
const SEVERITY = 'HIGH';
const TITLE = 'integer multiplication may overflow without u128 promotion';

/**
 * @param {string} source
 * @param {string} filename
 * @returns {Array<{rule, severity, file, line, message}>}
 */
export function check(source, filename) {
  const findings = [];
  const lines = source.split('\n');
  let inTestFn = false;
  let testBraceDepth = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (trimmed.startsWith('//')) continue;

    // track #[test] and #[test_only] function bodies — skip them
    if (/^#\[test[\],\s]/.test(trimmed) || /^#\[test_only\]/.test(trimmed)) {
      inTestFn = true;
      testBraceDepth = 0;
      continue;
    }
    if (inTestFn) {
      testBraceDepth += (line.match(/{/g) || []).length;
      testBraceDepth -= (line.match(/}/g) || []).length;
      if (testBraceDepth <= 0 && /}/.test(line)) { inTestFn = false; }
      continue;
    }

    // look for multiplication: word * word (not inside a cast expression)
    const mulMatches = [...trimmed.matchAll(/(\w+)\s*\*\s*(\w+)/g)];
    for (const m of mulMatches) {
      const fullLine = trimmed;

      // skip if this line has u128/u256 cast BEFORE the multiply
      // pattern: (expr as u128) * (expr as u128)
      const beforeMul = fullLine.slice(0, m.index);
      if (/as\s+u128\s*\)\s*$/.test(beforeMul)) continue;
      if (/as\s+u256\s*\)\s*$/.test(beforeMul)) continue;

      // skip if the whole expression is cast: (a * b as u128) — still risky
      // but (a as u128) * b is partially safe

      // skip if both operands are literals (constants)
      if (/^\d+$/.test(m[1]) && /^\d+$/.test(m[2])) continue;

      // skip if operands are already u128/u256 typed (naming convention)
      if (/_u256$/.test(m[1]) || /_u256$/.test(m[2])) continue;
      if (/_u128$/.test(m[1]) || /_u128$/.test(m[2])) continue;

      // skip if inside a type annotation or const declaration
      if (/const\s+\w+\s*:\s*u\d+\s*=/.test(fullLine)) continue;
      if (/:\s*u128\s*=/.test(fullLine) || /:\s*u256\s*=/.test(fullLine)) continue;

      // skip if the line already has (as u128) anywhere — likely cast chain
      if (/as\s+u128/.test(fullLine) || /as\s+u256/.test(fullLine)) continue;

      // skip shift operations (<<, >>)
      if (/<<|>>/.test(fullLine)) continue;

      findings.push({
        rule: RULE_ID,
        severity: SEVERITY,
        file: filename,
        line: i + 1,
        message: `${TITLE}: \`${m[1]} * ${m[2]}\` — cast to u128 before multiplying to prevent overflow`,
      });
    }
  }

  return findings;
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
