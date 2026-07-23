/**
 * MOV-004: Unsafe integer downcast without overflow check.
 *
 * Flags `(expr as u64)` casts from u128/u256 where no preceding
 * assert guards against truncation. Move's `as` operator silently
 * truncates on overflow — unlike arithmetic ops which abort.
 *
 * Why it matters: Bucket Protocol's interest_table.move correctly
 * checks `assert!(interest_payable <= max_u64())` before downcasting.
 * Code that skips this check risks silent value corruption — balances,
 * debt amounts, or reward calculations silently wrapping to small
 * numbers.
 *
 * What this catches:
 *   let result = (big_value as u64);  — no prior assert
 *
 * What this skips:
 *   - Downcasts inside mul_factor / mul_div (library return values,
 *     designed to fit u64 by construction)
 *   - Lines with assert on the same or preceding line
 *   - Test functions
 *   - Casts from u8/u16/u32 (always safe)
 */

const RULE_ID = 'MOV-004';
const SEVERITY = 'MEDIUM';
const TITLE = 'unsafe downcast to u64 without overflow check';

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

    // skip #[test] and #[test_only] function bodies
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

    // look for `as u64)` pattern — downcast from wider type
    if (!/as\s+u64\s*\)/.test(trimmed)) continue;

    // skip if this is inside a mul_factor / mul_div call (library return pattern)
    if (/mul_factor|mul_div|mul_factor_u128|mul_factor_u256/.test(trimmed)) continue;

    // skip if the enclosing function is a library math function (mul_div, mul_factor pattern)
    let inLibFn = false;
    for (let j = Math.max(0, i - 8); j < i; j++) {
      if (/fun\s+(mul_div|mul_factor|mul_div_u128|checked_mul|is_safe_mul)/.test(lines[j])) {
        inLibFn = true;
        break;
      }
    }
    if (inLibFn) continue;

    // skip if cast source is from a known-small context (u8/u16/u32 field names)
    if (/\(\s*\w*(duration|decimals?|precision_decimal|weight|ratio|percent|fee_rate|scale)\s+as\s+u64\)/.test(trimmed)) continue;
    if (/\(\s*\w+\.\w*(duration|decimals?|precision_decimal|weight|ratio|percent|fee_rate|scale)\s+as\s+u64\)/.test(trimmed)) continue;

    // check preceding lines for overflow assert
    let hasGuard = false;
    for (let j = Math.max(0, i - 3); j <= i; j++) {
      const prev = lines[j].trim();
      if (/assert!.*<=.*max_u64|assert!.*<=.*MAX_U64|assert!.*<=.*18446744073709551615/i.test(prev)) {
        hasGuard = true;
        break;
      }
    }
    if (hasGuard) continue;

    // skip if the cast is from a variable known to be small by context
    // (e.g., loop counter, decimal value, timestamp)
    if (/\b(i|j|k|idx|index|decimal|decimals|scale|epoch|timestamp)\b/.test(trimmed) &&
        /\(\s*(i|j|k|idx|index|decimal|decimals|scale|epoch|timestamp)\s+as\s+u64\)/.test(trimmed)) {
      continue;
    }

    // skip constant downcasts (constants::xxx() as u64) — values are small by design
    if (/constants::\w+\(\)\s+as\s+u64/.test(trimmed)) continue;

    // skip event emission context (downcast for logging, not computation)
    let inEmit = false;
    for (let j = Math.max(0, i - 4); j <= i; j++) {
      if (/emit|emit_param|emit_event/.test(lines[j])) { inEmit = true; break; }
    }
    if (inEmit) continue;

    // extract what's being cast for the message
    const castMatch = trimmed.match(/\(([^)]+)\s+as\s+u64\s*\)/);
    const expr = castMatch ? castMatch[1].trim() : '?';

    findings.push({
      rule: RULE_ID,
      severity: SEVERITY,
      file: filename,
      line: i + 1,
      message: `${TITLE}: \`(${expr} as u64)\` — add overflow check before downcasting from u128/u256`,
    });
  }

  return findings;
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
