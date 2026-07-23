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
 * Uses the Move parser for type tracking: if either operand is known
 * to be u128 or u256 (from let declaration, cast, or naming convention),
 * the multiplication is safe and not flagged.
 */

import { parseModule, getVarType } from '../scripts/move-parser.mjs';

const RULE_ID = 'MOV-002';
const SEVERITY = 'HIGH';
const TITLE = 'integer multiplication may overflow without u128 promotion';

const WIDE_TYPES = new Set(['u128', 'u256']);

/**
 * @param {string} source
 * @param {string} filename
 * @returns {Array<{rule, severity, file, line, message}>}
 */
export function check(source, filename) {
  const findings = [];
  const mod = parseModule(source);

  for (const fn of mod.functions) {
    // skip test functions
    if (fn.isTest || fn.isTestOnly) continue;
    if (!fn.body) continue;

    for (const mul of fn.body.multiplications) {
      const leftType = mul.leftType || getVarType(fn, mul.left);
      const rightType = mul.rightType || getVarType(fn, mul.right);

      // skip if either operand is u128/u256
      if (leftType && WIDE_TYPES.has(leftType)) continue;
      if (rightType && WIDE_TYPES.has(rightType)) continue;

      // skip if both are literals
      if (/^\d+$/.test(mul.left) && /^\d+$/.test(mul.right)) continue;

      // skip if naming convention indicates wide type
      if (/_u256$/.test(mul.left) || /_u256$/.test(mul.right)) continue;
      if (/_u128$/.test(mul.left) || /_u128$/.test(mul.right)) continue;

      // get the source line for additional context checks
      const lines = source.split('\n');
      const lineText = (lines[mul.line - 1] || '').trim();

      // skip if the line has an inline cast (as u128/u256)
      if (/as\s+u128/.test(lineText) || /as\s+u256/.test(lineText)) continue;

      // skip const declarations
      if (/const\s+\w+\s*:\s*u\d+\s*=/.test(lineText)) continue;
      if (/:\s*u128\s*=/.test(lineText) || /:\s*u256\s*=/.test(lineText)) continue;

      // skip shift operations
      if (/<<|>>/.test(lineText)) continue;

      findings.push({
        rule: RULE_ID,
        severity: SEVERITY,
        file: filename,
        line: mul.line,
        message: `${TITLE}: \`${mul.left} * ${mul.right}\`${leftType ? ` (${mul.left}: ${leftType})` : ''}${rightType ? ` (${mul.right}: ${rightType})` : ''} — cast to u128 before multiplying to prevent overflow`,
      });
    }
  }

  return findings;
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
