/**
 * MOV-003: Division without zero-denominator check.
 *
 * Flags division operations (/) where the denominator is a variable
 * and no assert!(denom != 0) or assert!(denom > 0) appears in the
 * preceding lines of the same function.
 *
 * Why it matters: Move VM aborts on division by zero, but the abort
 * gives no context — just a raw arithmetic error. An explicit assert
 * with a named error code makes the failure diagnosable and testable.
 * Every production-grade DeFi contract (fee calculations, share math,
 * oracle scaling) should check before dividing.
 *
 * What this catches:
 *   let result = amount / total_supply;  — no prior check on total_supply
 *
 * What this skips:
 *   let result = amount / 10000;  — literal denominator, always nonzero
 */

const RULE_ID = 'MOV-003';
const SEVERITY = 'MEDIUM';
const TITLE = 'division by variable without zero-check';

/**
 * @param {string} source
 * @param {string} filename
 * @returns {Array<{rule, severity, file, line, message}>}
 */
export function check(source, filename) {
  const findings = [];
  const lines = source.split('\n');

  // track function boundaries for scope
  let inFunction = false;
  let fnStartLine = 0;
  let braceDepth = 0;
  let fnLines = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (trimmed.startsWith('//')) continue;

    // detect function start
    if (/\bfun\s+\w+/.test(trimmed)) {
      inFunction = true;
      fnStartLine = i;
      fnLines = [];
      braceDepth = 0;
    }

    if (inFunction) {
      fnLines.push({ text: trimmed, lineNo: i + 1 });
      braceDepth += (line.match(/{/g) || []).length;
      braceDepth -= (line.match(/}/g) || []).length;

      if (braceDepth <= 0 && fnLines.length > 1) {
        // function ended — analyze it
        analyzeFn(fnLines, filename, findings);
        inFunction = false;
        fnLines = [];
      }
    }
  }

  return findings;
}

function analyzeFn(fnLines, filename, findings) {
  // collect all zero-checked variables in this function
  const checkedVars = new Set();

  for (const { text } of fnLines) {
    // assert!(x != 0, ...) or assert!(x > 0, ...)
    const checkMatch = text.match(/assert!\s*\(\s*(\w+)\s*(!= 0|> 0)/);
    if (checkMatch) checkedVars.add(checkMatch[1]);

    // x != 0 in if condition
    const ifCheck = text.match(/if\s*\(\s*(\w+)\s*(!= 0|> 0|== 0)/);
    if (ifCheck) checkedVars.add(ifCheck[1]);
  }

  // now find divisions
  for (const { text, lineNo } of fnLines) {
    if (text.startsWith('//')) continue;

    // match: expr / variable (not literal)
    const divMatches = [...text.matchAll(/(\w+)\s*\/\s*(\w+)/g)];
    for (const m of divMatches) {
      const denom = m[2];

      // skip literal denominators (numbers)
      if (/^\d+$/.test(denom)) continue;

      // skip if denominator was checked
      if (checkedVars.has(denom)) continue;

      // skip if denom is a field access result (likely checked elsewhere)
      // but still flag — better to warn than miss

      // skip comment-like patterns
      if (text.includes('//')) {
        const commentStart = text.indexOf('//');
        if (m.index > commentStart) continue;
      }

      findings.push({
        rule: RULE_ID,
        severity: SEVERITY,
        file: filename,
        line: lineNo,
        message: `${TITLE}: \`/ ${denom}\` — add \`assert!(${denom} != 0, E...)\` before dividing`,
      });
    }
  }
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
