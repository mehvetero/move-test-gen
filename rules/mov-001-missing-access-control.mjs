/**
 * MOV-001: Missing access control on state-modifying public functions.
 *
 * Flags public functions that take &mut parameters (state modification)
 * but have no capability parameter (AdminCap, OwnerCap, or any *Cap type).
 *
 * Why it matters: Kriya's update_pool was callable by anyone because it
 * lacked an access control check. Any public function that mutates shared
 * state without a capability gate is an open door.
 *
 * Exceptions: init(), test_only functions, view functions (no &mut on
 * domain objects), and functions whose only &mut is TxContext.
 */

const RULE_ID = 'MOV-001';
const SEVERITY = 'HIGH';
const TITLE = 'public function modifies state without capability check';

/**
 * @param {string} source — file content
 * @param {string} filename
 * @returns {Array<{rule, severity, file, line, message}>}
 */
export function check(source, filename) {
  const findings = [];
  const lines = source.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (trimmed.startsWith('//')) continue;

    const fnMatch = trimmed.match(/^public\s+(?:entry\s+)?fun\s+(\w+)(?:<[^>]*>)?\s*\(([^)]*)\)/);
    if (!fnMatch) {
      const startMatch = trimmed.match(/^public\s+(?:entry\s+)?fun\s+(\w+)(?:<[^>]*>)?\s*\(/);
      if (startMatch) {
        let params = '';
        for (let j = i; j < Math.min(i + 10, lines.length); j++) {
          params += lines[j];
          if (lines[j].includes(')')) break;
        }
        const fullMatch = params.match(/public\s+(?:entry\s+)?fun\s+(\w+)(?:<[^>]*>)?\s*\(([^)]*)\)/);
        if (fullMatch) {
          checkFunction(fullMatch[1], fullMatch[2], i + 1, filename, findings);
        }
      }
      continue;
    }

    checkFunction(fnMatch[1], fnMatch[2], i + 1, filename, findings);
  }

  return findings;
}

function checkFunction(name, params, lineNo, filename, findings) {
  // skip init, destroy, test functions
  if (name === 'init' || name.includes('testing') || name.includes('destroy')) return;
  if (name.startsWith('test_')) return;

  // does it take &mut on something other than TxContext?
  const hasMut = /&mut\s+(?!TxContext)(?!tx_context)/.test(params);
  if (!hasMut) return;

  // does it have a capability parameter?
  const hasCap = /[A-Z]\w*Cap\b|AdminCap|OwnerCap|ManagerCap|AuthCap/.test(params);
  if (hasCap) return;

  // does it have a signer/witness parameter that implies auth?
  const hasWitness = /_:\s+\w+|witness|Witness/.test(params) && /\bdrop\b/.test(params);
  if (hasWitness) return;

  findings.push({
    rule: RULE_ID,
    severity: SEVERITY,
    file: filename,
    line: lineNo,
    message: `${TITLE}: \`${name}\` takes &mut but no capability parameter`,
  });
}

export const meta = { id: RULE_ID, severity: SEVERITY, title: TITLE };
