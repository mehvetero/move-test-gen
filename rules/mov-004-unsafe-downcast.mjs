/**
 * MOV-004: Unsafe integer downcast without overflow check.
 *
 * Flags `(expr as u64)` casts from u128/u256 where no preceding
 * assert guards against truncation. Move's `as` operator silently
 * truncates on overflow — unlike arithmetic ops which abort.
 *
 * Uses the Move parser to:
 *   - track the source type of the expression being cast
 *   - skip casts from u8/u16/u32 (always safe, no truncation)
 *   - check for overflow asserts within the same function scope
 *   - skip test functions and library internals
 */

import { parseModule, getVarType, hasAssertBefore } from '../scripts/move-parser.mjs';

const RULE_ID = 'MOV-004';
const SEVERITY = 'MEDIUM';
const TITLE = 'unsafe downcast to u64 without overflow check';

const SAFE_SOURCE_TYPES = new Set(['u8', 'u16', 'u32', 'u64', 'literal']);
const LIB_FUNCTIONS = new Set([
  'mul_div', 'mul_factor', 'mul_div_u128', 'mul_factor_u128',
  'mul_factor_u256', 'checked_mul', 'is_safe_mul',
  'mul_div_floor', 'mul_div_round', 'mul_div_ceil',
  'mul_shr', 'mul_shl', 'full_mul',
  'pow', 'sqrt', 'log2',
]);
const LIB_PATTERNS = ['mul_div', 'mul_factor', 'safe_mul', 'checked_mul', 'full_mul'];

/**
 * @param {string} source
 * @param {string} filename
 * @returns {Array<{rule, severity, file, line, message}>}
 */
export function check(source, filename) {
  const findings = [];
  const mod = parseModule(source);
  const lines = source.split('\n');

  for (const fn of mod.functions) {
    if (fn.isTest || fn.isTestOnly) continue;
    if (LIB_FUNCTIONS.has(fn.name) || LIB_PATTERNS.some(p => fn.name.includes(p))) continue;
    if (!fn.body) continue;

    for (const cast of fn.body.casts) {
      if (cast.toType !== 'u64') continue;

      // if we know the source type and it fits in u64, skip
      const srcType = cast.fromType || inferTypeFromExpr(cast.expr, fn);
      if (srcType && SAFE_SOURCE_TYPES.has(srcType)) continue;

      // check for overflow assert before this cast in the function
      if (hasAssertBefore(fn, cast.line, /<=.*max_u64|<=.*MAX_U64|<=.*18446744073709551615/i)) continue;

      // skip if the line contains mul_factor / mul_div (library return)
      const lineText = (lines[cast.line - 1] || '').trim();
      if (/mul_factor|mul_div/.test(lineText)) continue;

      // skip constants:: calls (values small by design)
      if (/constants::\w+\(\)/.test(cast.expr)) continue;

      // skip known-small field names
      if (/\b(duration|decimals?|precision_decimal|weight|ratio|percent|fee_rate|scale)\b/.test(cast.expr)) continue;

      // skip event emission context
      let inEmit = false;
      for (let j = Math.max(0, cast.line - 5); j <= cast.line - 1; j++) {
        if (/emit/.test(lines[j] || '')) { inEmit = true; break; }
      }
      if (inEmit) continue;

      const typeInfo = srcType ? ` (from ${srcType})` : '';
      findings.push({
        rule: RULE_ID,
        severity: SEVERITY,
        file: filename,
        line: cast.line,
        message: `${TITLE}: \`(${cast.expr} as u64)\`${typeInfo} — add overflow check before downcasting`,
      });
    }
  }

  return findings;
}

function inferTypeFromExpr(expr, fn) {
  // direct variable lookup
  const varType = getVarType(fn, expr.trim());
  if (varType) return varType;

  // field access: obj.field — check if field name suggests small type
  const fieldMatch = expr.match(/\.(\w+)$/);
  if (fieldMatch) {
    const field = fieldMatch[1];
    if (/duration|decimals?|precision_decimal|weight|scale|epoch/.test(field)) return 'u32';
  }

  return null;
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
