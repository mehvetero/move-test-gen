/**
 * classify.mjs — pure classification of mutation survivors.
 *
 * Extracted so gate-selftest can pin behavior with synthetic inputs (no sui needed).
 * The gate imports this; the gate NEVER reads expected.json, keys, or any answer file.
 */

/**
 * Classify surviving mutants.
 *
 * @param {Array<{file, line, mutation, desc, original, killed}>} allResults - full mutation results
 * @param {Array<{file, line, code, type}>} allAsserts - all assert/abort sites from source
 * @returns {{
 *   reframed: Array<{file, line, mutation, desc, original, evidence: string|null}>,
 *   probeResults: Array<{codeA, codeB, lineA, lineB, file, jointKilled: boolean}>
 * }}
 */
export function classifySurvivors(allResults, allAsserts) {
  const survived = allResults.filter(r => !r.killed);
  const reframed = [];
  const probeResults = [];

  if (survived.length === 0) return { reframed, probeResults };

  const dropSurvivors = survived.filter(s => s.mutation === 'drop-assert');

  const byFileAndCode = {};
  for (const s of dropSurvivors) {
    const assertAtLine = allAsserts.find(
      a => normFile(a.file) === normFile(s.file) && a.line === s.line
    );
    if (!assertAtLine) continue;
    const key = `${normFile(s.file)}::${assertAtLine.code}`;
    if (!byFileAndCode[key]) byFileAndCode[key] = [];
    byFileAndCode[key].push({ ...s, code: assertAtLine.code });
  }

  const redundantPairs = new Set();
  for (const [key, group] of Object.entries(byFileAndCode)) {
    if (group.length >= 2) {
      for (const s of group) redundantPairs.add(`${normFile(s.file)}:${s.line}`);
      probeResults.push({
        code: group[0].code,
        file: normFile(group[0].file),
        lines: group.map(g => g.line),
        jointKilled: null,
      });
    }
  }

  for (const s of survived) {
    const loc = `${normFile(s.file)}:${s.line}`;
    const isRedundantDrop = redundantPairs.has(loc);
    reframed.push({
      file: s.file,
      line: s.line,
      mutation: s.mutation,
      desc: s.desc,
      original: s.original,
      evidence: isRedundantDrop
        ? 'mutual redundancy — each guard individually removable, jointly load-bearing → suspected-equivalent'
        : null,
    });
  }

  return { reframed, probeResults };
}

function normFile(f) {
  const s = f.replace(/\\/g, '/');
  const i = s.search(/(sources|tests)\//);
  return i >= 0 ? s.slice(i) : s;
}
